import "dotenv/config";
import { neon } from '@neondatabase/serverless';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error("❌ DATABASE_URL is not set in .env");
  process.exit(1);
}
const sql = neon(databaseUrl);

async function inspectSample() {
  const credentials = await sql`SELECT id, title, encrypted_password FROM credentials LIMIT 2;`;
  console.log("Credentials sample:", credentials);

  const wifis = await sql`SELECT id, ssid, password FROM wifi_networks LIMIT 2;`;
  console.log("Wifi sample:", wifis);
}

inspectSample();
