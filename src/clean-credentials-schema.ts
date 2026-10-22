import 'dotenv/config';
import { neon } from '@neondatabase/serverless';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error("❌ DATABASE_URL is not set");
  process.exit(1);
}

const sql = neon(databaseUrl);

async function cleanCredentialsSchema() {
  console.log("🚀 Cleaning and updating 'credentials' table in Neon Postgres...");

  try {
    // 1. Drop unused columns
    console.log("1️⃣ Dropping unused columns (iv, category, website_url)...");
    await sql`ALTER TABLE credentials DROP COLUMN IF EXISTS iv;`;
    await sql`ALTER TABLE credentials DROP COLUMN IF EXISTS category;`;
    await sql`ALTER TABLE credentials DROP COLUMN IF EXISTS website_url;`;
    console.log("   ✅ Columns dropped successfully.");

    // 2. Add 'notes' column
    console.log("2️⃣ Adding 'notes' column...");
    await sql`ALTER TABLE credentials ADD COLUMN IF NOT EXISTS notes TEXT;`;
    console.log("   ✅ 'notes' column added.");

    // 3. Inspect final columns
    const cols = await sql`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'credentials' 
      ORDER BY ordinal_position;
    `;
    console.log("\n📋 Final 'credentials' columns in Neon DB:");
    cols.forEach(c => console.log(`   - ${c.column_name} (${c.data_type})`));

    console.log("\n🎉 Database migration finished successfully!");
  } catch (err: any) {
    console.error("❌ Migration error:", err.message);
    process.exit(1);
  }
}

cleanCredentialsSchema();
