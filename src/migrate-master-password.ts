import { neon } from "@neondatabase/serverless";

const databaseUrl =
  process.env.DATABASE_URL ||
  "postgresql://neondb_owner:npg_PWeBTAC1Lo7y@ep-icy-lab-az0dwxto-pooler.c-3.ap-southeast-1.aws.neon.tech/neondb?sslmode=require";

const sql = neon(databaseUrl);

async function runMasterPasswordMigration() {
  console.log("🚀 Migrating 'users' table to support Master Vault Password...");

  try {
    await sql`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS master_password_hash TEXT,
      ADD COLUMN IF NOT EXISTS password_salt TEXT,
      ADD COLUMN IF NOT EXISTS has_master_password BOOLEAN DEFAULT FALSE;
    `;

    console.log("   ✅ Columns added to 'users' table.");

    const users = await sql`SELECT id, email, has_master_password FROM users LIMIT 5;`;
    console.log("   👥 Sample users table state:", users);

    console.log("\n🎉 NEON POSTGRES USERS TABLE MIGRATION COMPLETE!");
  } catch (error: any) {
    console.error("❌ Migration error:", error.message);
    process.exit(1);
  }
}

runMasterPasswordMigration();
