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

    // 1. Sync User (Google OAuth / Identity)
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

    // 2. Fetch User Vault Status
    if (url.pathname === '/api/vault/status' && request.method === 'GET') {
      try {
        const email = url.searchParams.get('email');
        if (!email) {
          return Response.json({ success: false, error: 'Email parameter required' }, { status: 400, headers: corsHeaders });
        }

        const userRows = await sql`SELECT id FROM users WHERE email = ${email};`;
        if (userRows.length === 0) {
          return Response.json({ success: false, error: 'User not found' }, { status: 404, headers: corsHeaders });
        }

        const userId = userRows[0].id;
        const [creds, notes, contacts, family] = await Promise.all([
          sql`SELECT count(*) as count FROM credentials WHERE user_id = ${userId}`,
          sql`SELECT count(*) as count FROM secure_notes WHERE user_id = ${userId}`,
          sql`SELECT count(*) as count FROM emergency_contacts WHERE user_id = ${userId}`,
          sql`SELECT count(*) as count FROM family_members WHERE user_id = ${userId}`,
        ]);

        return Response.json({
          success: true,
          userId,
          counts: {
            credentials: parseInt(creds[0].count),
            notes: parseInt(notes[0].count),
            contacts: parseInt(contacts[0].count),
            family: parseInt(family[0].count),
          }
        }, { headers: corsHeaders });
      } catch (err: any) {
        return Response.json({ success: false, error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    return Response.json({ error: 'Endpoint Not Found' }, { status: 404, headers: corsHeaders });
  },
};
