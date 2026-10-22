import "dotenv/config";
import { neon } from "@neondatabase/serverless";

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error("❌ DATABASE_URL is not set in .env");
  process.exit(1);
}

const sql = neon(databaseUrl);

async function runLockoutMigration() {
  console.log("🚀 Adding failed_attempts and lockout_until columns to 'users' table...");

  try {
    await sql`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS failed_attempts INT DEFAULT 0,
      ADD COLUMN IF NOT EXISTS lockout_until TIMESTAMPTZ DEFAULT NULL;
    `;

    console.log("   ✅ Columns added to 'users' table successfully.");

    const users = await sql`
      SELECT id, email, failed_attempts, lockout_until 
      FROM users 
      LIMIT 3;
    `;
    console.log("   👥 Current state of users:", users);
    console.log("\n🎉 NEON POSTGRES LOCKOUT MIGRATION COMPLETE!");
  } catch (error: any) {
    console.error("❌ Migration error:", error.message);
    process.exit(1);
  }
}

runLockoutMigration();
