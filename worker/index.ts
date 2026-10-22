import { neon } from '@neondatabase/serverless';

export interface Env {
  DATABASE_URL: string;
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
          RETURNING id, email, name, provider, created_at;
        `;

        return Response.json({ success: true, user: rows[0] }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    // 2. Fetch all vault items for a user
    if (url.pathname === '/api/vault/items' && request.method === 'GET') {
      try {
        const userId = url.searchParams.get('userId');
        const email = url.searchParams.get('email');

        let targetUserId = userId;
        if (!targetUserId && email) {
          const userRows = await sql`SELECT id FROM users WHERE email = ${email};`;
          if (userRows.length > 0) {
            targetUserId = userRows[0].id;
          }
        }

        if (!targetUserId) {
          return Response.json({ success: false, error: 'userId or email is required' }, { status: 400, headers: corsHeaders });
        }

        const [passwords, secrets, contacts, birthdays] = await Promise.all([
          sql`SELECT * FROM credentials WHERE user_id = ${targetUserId} ORDER BY COALESCE(is_pinned, FALSE) DESC, created_at DESC;`,
          sql`SELECT * FROM secure_notes WHERE user_id = ${targetUserId} ORDER BY COALESCE(is_pinned, FALSE) DESC, created_at DESC;`,
          sql`SELECT * FROM emergency_contacts WHERE user_id = ${targetUserId} ORDER BY COALESCE(is_pinned, FALSE) DESC, created_at DESC;`,
          sql`SELECT * FROM family_members WHERE user_id = ${targetUserId} ORDER BY COALESCE(is_pinned, FALSE) DESC, birthdate ASC;`,
        ]);

        return Response.json({
          success: true,
          userId: targetUserId,
          passwords,
          secrets,
          contacts,
          birthdays,
        }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    // 3. Create a vault item
    if (url.pathname === '/api/vault/items' && request.method === 'POST') {
      try {
        const body: any = await request.json();
        const { type, userId, data } = body;

        if (!userId || !type || !data) {
          return Response.json({ success: false, error: 'Missing type, userId, or data' }, { status: 400, headers: corsHeaders });
        }

        let inserted;
        if (type === 'password') {
          inserted = await sql`
            INSERT INTO credentials (user_id, title, username_or_email, encrypted_password, notes, is_pinned)
            VALUES (${userId}, ${data.title}, ${data.username_or_email}, ${data.password}, ${data.notes || null}, ${data.is_pinned ?? false})
            RETURNING *;
          `;
        } else if (type === 'secret') {
          inserted = await sql`
            INSERT INTO secure_notes (user_id, title, content, is_pinned)
            VALUES (${userId}, ${data.title}, ${data.content}, ${data.is_pinned ?? false})
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
        } else {
          return Response.json({ success: false, error: 'Invalid type' }, { status: 400, headers: corsHeaders });
        }

        return Response.json({ success: true, item: inserted[0] }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    // 4. Update a vault item
    if (url.pathname === '/api/vault/items' && request.method === 'PUT') {
      try {
        const body: any = await request.json();
        const { type, userId, itemId, data } = body;

        if (!userId || !type || !itemId || !data) {
          return Response.json({ success: false, error: 'Missing type, userId, itemId, or data' }, { status: 400, headers: corsHeaders });
        }

        let updated;
        if (type === 'password') {
          updated = await sql`
            UPDATE credentials
            SET title = COALESCE(${data.title}, title),
                username_or_email = COALESCE(${data.username_or_email}, username_or_email),
                encrypted_password = COALESCE(${data.password}, encrypted_password),
                notes = ${data.notes !== undefined ? (data.notes || null) : sql`notes`},
                is_pinned = COALESCE(${data.is_pinned}, is_pinned),
                updated_at = NOW()
            WHERE id = ${itemId} AND user_id = ${userId}
            RETURNING *;
          `;
        } else if (type === 'secret') {
          updated = await sql`
            UPDATE secure_notes
            SET title = COALESCE(${data.title}, title),
                content = COALESCE(${data.content}, content),
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
        } else {
          return Response.json({ success: false, error: 'Invalid type' }, { status: 400, headers: corsHeaders });
        }

        return Response.json({ success: true, item: updated[0] }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    return Response.json({ error: 'Endpoint Not Found' }, { status: 404, headers: corsHeaders });
  },
};
