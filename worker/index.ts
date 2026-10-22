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
          sql`SELECT * FROM credentials WHERE user_id = ${targetUserId} ORDER BY created_at DESC;`,
          sql`SELECT * FROM secure_notes WHERE user_id = ${targetUserId} ORDER BY created_at DESC;`,
          sql`SELECT * FROM emergency_contacts WHERE user_id = ${targetUserId} ORDER BY created_at DESC;`,
          sql`SELECT * FROM family_members WHERE user_id = ${targetUserId} ORDER BY birthdate ASC;`,
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
            INSERT INTO credentials (user_id, title, username_or_email, encrypted_password, notes)
            VALUES (${userId}, ${data.title}, ${data.username_or_email}, ${data.password}, ${data.notes || null})
            RETURNING *;
          `;
        } else if (type === 'secret') {
          inserted = await sql`
            INSERT INTO secure_notes (user_id, title, content)
            VALUES (${userId}, ${data.title}, ${data.content})
            RETURNING *;
          `;
        } else if (type === 'contact') {
          inserted = await sql`
            INSERT INTO emergency_contacts (user_id, name, phone_number, relationship, notes)
            VALUES (${userId}, ${data.name}, ${data.phone_number}, ${data.relationship || 'General'}, ${data.notes || null})
            RETURNING *;
          `;
        } else if (type === 'birthday') {
          inserted = await sql`
            INSERT INTO family_members (user_id, name, relationship, birthdate, notes)
            VALUES (${userId}, ${data.name}, ${data.relationship || 'Family'}, ${data.birthdate}, ${data.notes || null})
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

    return Response.json({ error: 'Endpoint Not Found' }, { status: 404, headers: corsHeaders });
  },
};
