import { neon } from "@neondatabase/serverless";

const databaseUrl =
  process.env.DATABASE_URL ||
  "postgresql://neondb_owner:npg_PWeBTAC1Lo7y@ep-icy-lab-az0dwxto-pooler.c-3.ap-southeast-1.aws.neon.tech/neondb?sslmode=require";

const sql = neon(databaseUrl);

async function runWifiTableMigration() {
  console.log("🚀 Creating 'wifi_networks' table in Neon Postgres...");

  try {
    // Table: wifi_networks (SSID, Password, Security Type, Notes)
    await sql`
      CREATE TABLE IF NOT EXISTS wifi_networks (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        ssid VARCHAR(120) NOT NULL,
        password TEXT NOT NULL,
        security_type VARCHAR(30) DEFAULT 'WPA',
        notes TEXT,
        is_pinned BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `;
    console.log("   ✅ 'wifi_networks' table created successfully.");

    await sql`
      CREATE INDEX IF NOT EXISTS idx_wifi_networks_user_id ON wifi_networks(user_id);
    `;
    console.log("   ✅ Index 'idx_wifi_networks_user_id' created.");

    console.log("\n🎉 NEON POSTGRES WIFI_NETWORKS TABLE IS READY FOR PRODUCTION!");
  } catch (error: any) {
    console.error("❌ Migration error:", error.message);
    process.exit(1);
  }
}

runWifiTableMigration();
