import "dotenv/config";
import { neon } from "@neondatabase/serverless";

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error("❌ DATABASE_URL is not set");
  process.exit(1);
}

const sql = neon(databaseUrl);

async function runLifeVaultMigration() {
  console.log("🚀 Expanding Neon Database Schema for PassKeep Life Vault...");

  try {
    // 1. Ensure 'users' exists
    await sql`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT UNIQUE NOT NULL,
        name TEXT,
        provider VARCHAR(30) DEFAULT 'google',
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `;
    console.log("   ✅ 'users' table confirmed.");

    // 2. Table: secure_notes (Secrets & Private Memos)
    console.log("1️⃣ Ensuring 'secure_notes' table...");
    await sql`
      CREATE TABLE IF NOT EXISTS secure_notes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(150) NOT NULL,
        content TEXT NOT NULL,
        is_pinned BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `;
    await sql`CREATE INDEX IF NOT EXISTS idx_secure_notes_user_id ON secure_notes(user_id);`;
    console.log("   ✅ 'secure_notes' table ready.");

    // 3. Table: emergency_contacts (Important Contacts & Phone Numbers)
    console.log("2️⃣ Ensuring 'emergency_contacts' table...");
    await sql`
      CREATE TABLE IF NOT EXISTS emergency_contacts (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        name VARCHAR(100) NOT NULL,
        phone_number VARCHAR(30) NOT NULL,
        relationship VARCHAR(50) DEFAULT 'General',
        notes TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `;
    await sql`CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON emergency_contacts(user_id);`;
    console.log("   ✅ 'emergency_contacts' table ready.");

    // 4. Table: family_members (Birthdays & Milestones)
    console.log("3️⃣ Ensuring 'family_members' table...");
    await sql`
      CREATE TABLE IF NOT EXISTS family_members (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        name VARCHAR(100) NOT NULL,
        relationship VARCHAR(50) DEFAULT 'Family',
        birthdate DATE NOT NULL,
        notes TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `;
    await sql`CREATE INDEX IF NOT EXISTS idx_family_members_user_id ON family_members(user_id);`;
    console.log("   ✅ 'family_members' table ready.");

    console.log("\n🎉 ALL PASSKEEP LIFE VAULT TABLES DEPLOYED SUCCESSFULLY TO NEON!");
  } catch (error: any) {
    console.error("❌ Migration error:", error.message);
    process.exit(1);
  }
}

runLifeVaultMigration();
