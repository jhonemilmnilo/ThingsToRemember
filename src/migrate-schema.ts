import "dotenv/config";
import { neon } from "@neondatabase/serverless";

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error("❌ DATABASE_URL is not set");
  process.exit(1);
}

const sql = neon(databaseUrl);

async function runMigration() {
  console.log("🚀 Starting database schema migration on Neon Postgres...");

  try {
    // 1. Create users table (no avatar_url as requested)
    console.log("1️⃣ Ensuring 'users' table exists...");
    await sql`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT UNIQUE NOT NULL,
        name TEXT,
        provider VARCHAR(30) DEFAULT 'email',
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `;
    console.log("   ✅ 'users' table ready.");

    // 2. Add user_id to credentials if credentials exists, or create credentials with FK
    console.log("2️⃣ Ensuring 'credentials' table has 'user_id' FK...");
    await sql`
      CREATE TABLE IF NOT EXISTS credentials (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(100) NOT NULL,
        category VARCHAR(50) DEFAULT 'General',
        username_or_email TEXT NOT NULL,
        encrypted_password TEXT NOT NULL,
        iv TEXT NOT NULL,
        website_url TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `;

    // Ensure user_id column exists if table was created previously without it
    await sql`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name = 'credentials' AND column_name = 'user_id'
        ) THEN
          ALTER TABLE credentials ADD COLUMN user_id UUID REFERENCES users(id) ON DELETE CASCADE;
        END IF;
      END $$;
    `;

    // 3. Create index on credentials(user_id) for optimal performance
    await sql`
      CREATE INDEX IF NOT EXISTS idx_credentials_user_id ON credentials(user_id);
    `;
    console.log("   ✅ 'credentials' table updated with foreign key & index.");

    // Verify tables
    const userCols = await sql`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'users' ORDER BY ordinal_position;
    `;
    console.log("\n📋 Users table schema columns:", userCols.map(c => `${c.column_name} (${c.data_type})`).join(", "));

    const credCols = await sql`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'credentials' ORDER BY ordinal_position;
    `;
    console.log("📋 Credentials table schema columns:", credCols.map(c => `${c.column_name} (${c.data_type})`).join(", "));

    console.log("\n🎉 Database migration finished successfully!");
  } catch (err: any) {
    console.error("❌ Migration failed:", err.message);
    process.exit(1);
  }
}

runMigration();
