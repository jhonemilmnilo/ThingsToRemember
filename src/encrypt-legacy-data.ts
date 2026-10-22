import { neon } from '@neondatabase/serverless';
import { encryptVaultField } from '../worker/crypto.js';

const databaseUrl = 'postgresql://neondb_owner:npg_PWeBTAC1Lo7y@ep-icy-lab-az0dwxto-pooler.c-3.ap-southeast-1.aws.neon.tech/neondb?sslmode=require';
const masterKey = 'e7b89f3c1a2d4e6f8b0c2e4a6d8f0b2c4e6a8d0f2b4c6e8a0d2f4b6c8e0a2d4f';
const sql = neon(databaseUrl);

async function encryptExistingData() {
  console.log("🔒 Encrypting existing plain-text passwords in Neon Postgres...");

  // 1. Credentials
  const credentials = await sql`SELECT id, encrypted_password FROM credentials WHERE encrypted_password NOT LIKE 'enc:v1:%';`;
  console.log(`Found ${credentials.length} unencrypted credentials.`);
  for (const row of credentials) {
    const cipher = await encryptVaultField(row.encrypted_password, masterKey);
    await sql`UPDATE credentials SET encrypted_password = ${cipher} WHERE id = ${row.id};`;
  }

  // 2. Secure notes (Secrets / Things to remember)
  const secrets = await sql`SELECT id, content FROM secure_notes WHERE content NOT LIKE 'enc:v1:%';`;
  console.log(`Found ${secrets.length} unencrypted secrets.`);
  for (const row of secrets) {
    const cipher = await encryptVaultField(row.content, masterKey);
    await sql`UPDATE secure_notes SET content = ${cipher} WHERE id = ${row.id};`;
  }

  // 3. Wi-Fi networks
  const wifis = await sql`SELECT id, password FROM wifi_networks WHERE password NOT LIKE 'enc:v1:%';`;
  console.log(`Found ${wifis.length} unencrypted wifi passwords.`);
  for (const row of wifis) {
    const cipher = await encryptVaultField(row.password, masterKey);
    await sql`UPDATE wifi_networks SET password = ${cipher} WHERE id = ${row.id};`;
  }

  console.log("🎉 ALL EXISTING PASSWORDS & SECRETS ARE NOW 100% ENCRYPTED IN NEON POSTGRES!");
}

encryptExistingData();
