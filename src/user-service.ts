import 'dotenv/config';
import { neon } from '@neondatabase/serverless';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error("❌ DATABASE_URL is not set");
  process.exit(1);
}

const sql = neon(databaseUrl);

export async function syncUserToNeon(email: string, name?: string | null, provider: string = 'google') {
  const rows = await sql`
    INSERT INTO users (email, name, provider, updated_at)
    VALUES (${email}, ${name || 'User'}, ${provider}, NOW())
    ON CONFLICT (email) 
    DO UPDATE SET 
      name = COALESCE(EXCLUDED.name, users.name),
      updated_at = NOW()
    RETURNING *;
  `;
  return rows[0];
}
