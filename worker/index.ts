import { neon } from '@neondatabase/serverless';
import {
  encryptVaultField,
  decryptVaultField,
  hashPassword,
  verifyPassword,
  issueSessionToken,
  verifySessionToken,
  SessionPayload,
} from './crypto';

export interface Env {
  DATABASE_URL: string;
  AES_VAULT_MASTER_KEY: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // CORS Headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    const sql = neon(env.DATABASE_URL);

    // Reusable Bearer Token Verification Helper
    async function getAuthenticatedSession(): Promise<SessionPayload | null> {
      const authHeader = request.headers.get('Authorization') || request.headers.get('authorization');
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return null;
      }
      const token = authHeader.substring(7).trim();
      return await verifySessionToken(token, env.AES_VAULT_MASTER_KEY);
    }

    // Health check
    if (url.pathname === '/health' || url.pathname === '/') {
      return Response.json(
        { status: 'ok', service: 'PassKeep Cloudflare Edge API', time: new Date().toISOString() },
        { headers: corsHeaders }
      );
    }

    // 1. Sync / Fetch User by Email
    if (url.pathname === '/api/users/sync' && request.method === 'POST') {
      try {
        const body: any = await request.json();
        const { email, name, provider } = body;

        if (!email) {
          return Response.json({ success: false, error: 'Email is required' }, { status: 400, headers: corsHeaders });
        }

        const rows = await sql`
          INSERT INTO users (email, name, provider, updated_at)
          VALUES (${email}, ${name || 'User'}, ${provider || 'google'}, NOW())
          ON CONFLICT (email) 
          DO UPDATE SET 
            name = COALESCE(EXCLUDED.name, users.name),
            updated_at = NOW()
          RETURNING id, email, name, provider, COALESCE(has_master_password, FALSE) as has_master_password, failed_attempts, lockout_until, created_at;
        `;

        const user = rows[0];
        const now = new Date();

        // If lockout has expired, automatically reset to 0 in sync as well
        if (user.lockout_until && now >= new Date(user.lockout_until)) {
          await sql`
            UPDATE users 
            SET failed_attempts = 0, lockout_until = NULL, updated_at = NOW() 
            WHERE id = ${user.id};
          `;
          user.failed_attempts = 0;
          user.lockout_until = null;
        }

        const isCurrentlyLocked = user.lockout_until && now < new Date(user.lockout_until);

        return Response.json({
          success: true,
          user: {
            ...user,
            is_locked: isCurrentlyLocked,
          },
        }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    // 1.1 Set / Register Master Password -> Issues signed session token upon setup
    if (url.pathname === '/api/users/set-password' && request.method === 'POST') {
      try {
        const body: any = await request.json();
        const { email, password } = body;

        if (!email || !password || typeof password !== 'string' || password.length < 4) {
          return Response.json(
            { success: false, error: 'Valid email and password (min 4 characters) are required' },
            { status: 400, headers: corsHeaders }
          );
        }

        const { hashHex, saltHex } = await hashPassword(password);

        const updated = await sql`
          UPDATE users
          SET 
            master_password_hash = ${hashHex},
            password_salt = ${saltHex},
            has_master_password = TRUE,
            updated_at = NOW()
          WHERE email = ${email}
          RETURNING id, email, name, has_master_password;
        `;

        if (updated.length === 0) {
          return Response.json({ success: false, error: 'User not found' }, { status: 404, headers: corsHeaders });
        }

        const user = updated[0];
        const sessionToken = await issueSessionToken(user.id, user.email, env.AES_VAULT_MASTER_KEY);

        return Response.json({ success: true, user, sessionToken }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    // 1.2 Verify Master Password -> Issues signed session token upon correct verification
    if (url.pathname === '/api/users/verify-password' && request.method === 'POST') {
      try {
        const body: any = await request.json();
        const { email, password } = body;

        if (!email || !password) {
          return Response.json({ success: false, error: 'Email and password are required' }, { status: 400, headers: corsHeaders });
        }

        const rows = await sql`
          SELECT id, email, master_password_hash, password_salt, has_master_password, failed_attempts, lockout_until
          FROM users
          WHERE email = ${email};
        `;

        if (rows.length === 0) {
          return Response.json({ success: false, error: 'User not found' }, { status: 404, headers: corsHeaders });
        }

        const user = rows[0];
        if (!user.has_master_password || !user.master_password_hash || !user.password_salt) {
          return Response.json({ success: false, error: 'No master password configured for this user' }, { status: 400, headers: corsHeaders });
        }

        const now = new Date();

        // 1. CHECK LOCKOUT EXPIRY & ACTIVE LOCK
        if (user.lockout_until) {
          const lockoutDate = new Date(user.lockout_until);
          if (now < lockoutDate) {
            // Still within the 1-hour lockout window -> block immediately
            return Response.json({
              success: false,
              locked: true,
              error: 'Account locked due to 5 failed attempts. Please try again after 1 hour.',
            }, { status: 423, headers: corsHeaders });
          } else {
            // 1 Hour has passed! Auto-reset the counter for a fresh set of 5 tries
            user.failed_attempts = 0;
            user.lockout_until = null;
            await sql`
              UPDATE users 
              SET failed_attempts = 0, lockout_until = NULL, updated_at = NOW() 
              WHERE id = ${user.id};
            `;
          }
        }

        // 2. VERIFY PASSWORD HASH
        const isValid = await verifyPassword(password, user.master_password_hash, user.password_salt);

        if (!isValid) {
          const currentFailed = Number(user.failed_attempts || 0);
          const newAttempts = currentFailed + 1;

          if (newAttempts >= 5) {
            // 💥 Strike 5 reached! Lock account for exactly 1 hour
            const lockoutUntil = new Date(now.getTime() + 60 * 60 * 1000);
            await sql`
              UPDATE users 
              SET failed_attempts = 5, lockout_until = ${lockoutUntil.toISOString()}, updated_at = NOW() 
              WHERE id = ${user.id};
            `;

            return Response.json({
              success: false,
              locked: true,
              error: 'Account locked due to 5 failed attempts. Please try again after 1 hour.',
            }, { status: 423, headers: corsHeaders });
          } else {
            // Strikes 1 to 4: Increment failed_attempts
            await sql`
              UPDATE users 
              SET failed_attempts = ${newAttempts}, updated_at = NOW() 
              WHERE id = ${user.id};
            `;

            return Response.json({
              success: false,
              verified: false,
              locked: false,
              error: 'Incorrect password.',
            }, { status: 401, headers: corsHeaders });
          }
        }

        // ✅ 3. SUCCESSFUL LOGIN: Reset counter and lockout back to 0
        await sql`
          UPDATE users 
          SET failed_attempts = 0, lockout_until = NULL, updated_at = NOW() 
          WHERE id = ${user.id};
        `;

        // Issue cryptographically signed token valid for 7 days
        const sessionToken = await issueSessionToken(user.id, user.email, env.AES_VAULT_MASTER_KEY);

        return Response.json({ success: true, verified: true, sessionToken }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    // =========================================================================
    // 🔒 PROTECTED VAULT ROUTES - STRICT BEARER SESSION AUTHENTICATION REQUIRED
    // =========================================================================

    // 2. Fetch all vault items for an authenticated user
    if (url.pathname === '/api/vault/items' && request.method === 'GET') {
      try {
        const session = await getAuthenticatedSession();
        if (!session) {
          return Response.json(
            { success: false, error: 'Unauthorized: Valid Session Token required to access vault' },
            { status: 401, headers: corsHeaders }
          );
        }

        const targetUserId = session.userId;

        const [passwordsRaw, secretsRaw, contacts, birthdays, wifiRaw] = await Promise.all([
          sql`SELECT * FROM credentials WHERE user_id = ${targetUserId} ORDER BY COALESCE(is_pinned, FALSE) DESC, created_at DESC;`,
          sql`SELECT * FROM secure_notes WHERE user_id = ${targetUserId} ORDER BY COALESCE(is_pinned, FALSE) DESC, created_at DESC;`,
          sql`SELECT * FROM emergency_contacts WHERE user_id = ${targetUserId} ORDER BY COALESCE(is_pinned, FALSE) DESC, created_at DESC;`,
          sql`SELECT * FROM family_members WHERE user_id = ${targetUserId} ORDER BY COALESCE(is_pinned, FALSE) DESC, birthdate ASC;`,
          sql`SELECT * FROM wifi_networks WHERE user_id = ${targetUserId} ORDER BY COALESCE(is_pinned, FALSE) DESC, created_at DESC;`,
        ]);

        const masterKey = env.AES_VAULT_MASTER_KEY;

        // Decrypt sensitive fields on the fly
        const passwords = await Promise.all(
          passwordsRaw.map(async (row: any) => ({
            ...row,
            encrypted_password: await decryptVaultField(row.encrypted_password, masterKey),
          }))
        );

        const secrets = await Promise.all(
          secretsRaw.map(async (row: any) => ({
            ...row,
            content: await decryptVaultField(row.content, masterKey),
          }))
        );

        const wifi = await Promise.all(
          wifiRaw.map(async (row: any) => ({
            ...row,
            password: await decryptVaultField(row.password, masterKey),
          }))
        );

        return Response.json({
          success: true,
          userId: targetUserId,
          passwords,
          secrets,
          contacts,
          birthdays,
          wifi,
        }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    // 3. Create a vault item (Protected)
    if (url.pathname === '/api/vault/items' && request.method === 'POST') {
      try {
        const session = await getAuthenticatedSession();
        if (!session) {
          return Response.json(
            { success: false, error: 'Unauthorized: Valid Session Token required to add vault items' },
            { status: 401, headers: corsHeaders }
          );
        }

        const body: any = await request.json();
        const { type, data } = body;
        const userId = session.userId; // Securely take userId from authenticated token

        if (!type || !data) {
          return Response.json({ success: false, error: 'Missing type or data' }, { status: 400, headers: corsHeaders });
        }

        const masterKey = env.AES_VAULT_MASTER_KEY;

        let inserted;
        if (type === 'password') {
          const cipherPass = await encryptVaultField(data.password, masterKey);
          inserted = await sql`
            INSERT INTO credentials (user_id, title, username_or_email, encrypted_password, notes, is_pinned)
            VALUES (${userId}, ${data.title}, ${data.username_or_email}, ${cipherPass}, ${data.notes || null}, ${data.is_pinned ?? false})
            RETURNING *;
          `;
        } else if (type === 'secret') {
          const cipherContent = await encryptVaultField(data.content, masterKey);
          inserted = await sql`
            INSERT INTO secure_notes (user_id, title, content, is_pinned)
            VALUES (${userId}, ${data.title}, ${cipherContent}, ${data.is_pinned ?? false})
            RETURNING *;
          `;
        } else if (type === 'contact') {
          inserted = await sql`
            INSERT INTO emergency_contacts (user_id, name, phone_number, relationship, notes, is_pinned)
            VALUES (${userId}, ${data.name}, ${data.phone_number}, ${data.relationship || 'General'}, ${data.notes || null}, ${data.is_pinned ?? false})
            RETURNING *;
          `;
        } else if (type === 'birthday') {
          inserted = await sql`
            INSERT INTO family_members (user_id, name, relationship, birthdate, notes, is_pinned)
            VALUES (${userId}, ${data.name}, ${data.relationship || 'Family'}, ${data.birthdate}, ${data.notes || null}, ${data.is_pinned ?? false})
            RETURNING *;
          `;
        } else if (type === 'wifi') {
          const cipherWifiPass = await encryptVaultField(data.password, masterKey);
          inserted = await sql`
            INSERT INTO wifi_networks (user_id, ssid, password, security_type, notes, is_pinned)
            VALUES (${userId}, ${data.ssid}, ${cipherWifiPass}, ${data.security_type || 'WPA'}, ${data.notes || null}, ${data.is_pinned ?? false})
            RETURNING *;
          `;
        } else {
          return Response.json({ success: false, error: 'Invalid type' }, { status: 400, headers: corsHeaders });
        }

        return Response.json({ success: true, item: inserted[0] }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    // 4. Update a vault item (Protected)
    if (url.pathname === '/api/vault/items' && request.method === 'PUT') {
      try {
        const session = await getAuthenticatedSession();
        if (!session) {
          return Response.json(
            { success: false, error: 'Unauthorized: Valid Session Token required to update vault items' },
            { status: 401, headers: corsHeaders }
          );
        }

        const body: any = await request.json();
        const { type, itemId, data } = body;
        const userId = session.userId; // Securely take userId from authenticated token

        if (!type || !itemId || !data) {
          return Response.json({ success: false, error: 'Missing type, itemId, or data' }, { status: 400, headers: corsHeaders });
        }

        const masterKey = env.AES_VAULT_MASTER_KEY;

        let updated;
        if (type === 'password') {
          const cipherPass = data.password !== undefined
              ? await encryptVaultField(data.password, masterKey)
              : null;

          updated = await sql`
            UPDATE credentials
            SET title = COALESCE(${data.title}, title),
                username_or_email = COALESCE(${data.username_or_email}, username_or_email),
                encrypted_password = ${cipherPass !== null ? cipherPass : sql`encrypted_password`},
                notes = ${data.notes !== undefined ? (data.notes || null) : sql`notes`},
                is_pinned = COALESCE(${data.is_pinned}, is_pinned),
                updated_at = NOW()
            WHERE id = ${itemId} AND user_id = ${userId}
            RETURNING *;
          `;
        } else if (type === 'secret') {
          const cipherContent = data.content !== undefined
              ? await encryptVaultField(data.content, masterKey)
              : null;

          updated = await sql`
            UPDATE secure_notes
            SET title = COALESCE(${data.title}, title),
                content = ${cipherContent !== null ? cipherContent : sql`content`},
                is_pinned = COALESCE(${data.is_pinned}, is_pinned),
                updated_at = NOW()
            WHERE id = ${itemId} AND user_id = ${userId}
            RETURNING *;
          `;
        } else if (type === 'contact') {
          updated = await sql`
            UPDATE emergency_contacts
            SET name = COALESCE(${data.name}, name),
                phone_number = COALESCE(${data.phone_number}, phone_number),
                relationship = COALESCE(${data.relationship}, relationship),
                notes = ${data.notes !== undefined ? (data.notes || null) : sql`notes`},
                is_pinned = COALESCE(${data.is_pinned}, is_pinned),
                updated_at = NOW()
            WHERE id = ${itemId} AND user_id = ${userId}
            RETURNING *;
          `;
        } else if (type === 'birthday') {
          updated = await sql`
            UPDATE family_members
            SET name = COALESCE(${data.name}, name),
                relationship = COALESCE(${data.relationship}, relationship),
                birthdate = COALESCE(${data.birthdate}, birthdate),
                notes = ${data.notes !== undefined ? (data.notes || null) : sql`notes`},
                is_pinned = COALESCE(${data.is_pinned}, is_pinned),
                updated_at = NOW()
            WHERE id = ${itemId} AND user_id = ${userId}
            RETURNING *;
          `;
        } else if (type === 'wifi') {
          const cipherWifiPass = data.password !== undefined
              ? await encryptVaultField(data.password, masterKey)
              : null;

          updated = await sql`
            UPDATE wifi_networks
            SET ssid = COALESCE(${data.ssid}, ssid),
                password = ${cipherWifiPass !== null ? cipherWifiPass : sql`password`},
                security_type = COALESCE(${data.security_type}, security_type),
                notes = ${data.notes !== undefined ? (data.notes || null) : sql`notes`},
                is_pinned = COALESCE(${data.is_pinned}, is_pinned),
                updated_at = NOW()
            WHERE id = ${itemId} AND user_id = ${userId}
            RETURNING *;
          `;
        } else {
          return Response.json({ success: false, error: 'Invalid type' }, { status: 400, headers: corsHeaders });
        }

        return Response.json({ success: true, item: updated[0] }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    // 5. Delete a vault item (Protected)
    if (request.method === 'DELETE' && url.pathname === '/api/vault/items') {
      try {
        const session = await getAuthenticatedSession();
        if (!session) {
          return Response.json(
            { success: false, error: 'Unauthorized: Valid Session Token required to delete vault items' },
            { status: 401, headers: corsHeaders }
          );
        }

        const body = await request.json() as any;
        const { type, itemId } = body;
        const userId = session.userId; // Securely take userId from authenticated token

        if (!type || !itemId) {
          return Response.json({ success: false, error: 'Missing required parameters' }, { status: 400, headers: corsHeaders });
        }

        if (type === 'password') {
          await sql`DELETE FROM credentials WHERE id = ${itemId} AND user_id = ${userId};`;
        } else if (type === 'secret') {
          await sql`DELETE FROM secure_notes WHERE id = ${itemId} AND user_id = ${userId};`;
        } else if (type === 'contact') {
          await sql`DELETE FROM emergency_contacts WHERE id = ${itemId} AND user_id = ${userId};`;
        } else if (type === 'birthday') {
          await sql`DELETE FROM family_members WHERE id = ${itemId} AND user_id = ${userId};`;
        } else if (type === 'wifi') {
          await sql`DELETE FROM wifi_networks WHERE id = ${itemId} AND user_id = ${userId};`;
        } else {
          return Response.json({ success: false, error: 'Invalid type' }, { status: 400, headers: corsHeaders });
        }

        return Response.json({ success: true, message: 'Item deleted successfully' }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    return Response.json({ error: 'Endpoint Not Found' }, { status: 404, headers: corsHeaders });
  },
};
