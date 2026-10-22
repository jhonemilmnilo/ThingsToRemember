import { neon } from '@neondatabase/serverless';

const databaseUrl = 'postgresql://neondb_owner:npg_PWeBTAC1Lo7y@ep-icy-lab-az0dwxto-pooler.c-3.ap-southeast-1.aws.neon.tech/neondb?sslmode=require';
const sql = neon(databaseUrl);

async function inspectSample() {
  const credentials = await sql`SELECT id, title, encrypted_password FROM credentials LIMIT 2;`;
  console.log("Credentials sample:", credentials);

  const wifis = await sql`SELECT id, ssid, password FROM wifi_networks LIMIT 2;`;
  console.log("Wifi sample:", wifis);
}

inspectSample();
