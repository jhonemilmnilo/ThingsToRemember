import "dotenv/config";
import { neon } from '@neondatabase/serverless';
import { encryptVaultField } from '../worker/crypto.js';

const databaseUrl = process.env.DATABASE_URL;
const masterKey = process.env.AES_VAULT_MASTER_KEY;

if (!databaseUrl || !masterKey) {
  console.error("❌ DATABASE_URL or AES_VAULT_MASTER_KEY is not set in .env");
  process.exit(1);
}
const validMasterKey: string = masterKey;
const sql = neon(databaseUrl);

async function encryptExistingData() {
  console.log("🔒 Encrypting existing plain-text passwords in Neon Postgres...");

  // 1. Credentials
  const credentials = await sql`SELECT id, encrypted_password FROM credentials WHERE encrypted_password NOT LIKE 'enc:v1:%';`;
  console.log(`Found ${credentials.length} unencrypted credentials.`);
  for (const row of credentials) {
    const cipher = await encryptVaultField(row.encrypted_password, validMasterKey);
    await sql`UPDATE credentials SET encrypted_password = ${cipher} WHERE id = ${row.id};`;
  }

  // 2. Secure notes (Secrets / Things to remember)
  const secrets = await sql`SELECT id, content FROM secure_notes WHERE content NOT LIKE 'enc:v1:%';`;
  console.log(`Found ${secrets.length} unencrypted secrets.`);
  for (const row of secrets) {
    const cipher = await encryptVaultField(row.content, validMasterKey);
    await sql`UPDATE secure_notes SET content = ${cipher} WHERE id = ${row.id};`;
  }

  // 3. Wi-Fi networks
  const wifis = await sql`SELECT id, password FROM wifi_networks WHERE password NOT LIKE 'enc:v1:%';`;
  console.log(`Found ${wifis.length} unencrypted wifi passwords.`);
  for (const row of wifis) {
    const cipher = await encryptVaultField(row.password, validMasterKey);
    await sql`UPDATE wifi_networks SET password = ${cipher} WHERE id = ${row.id};`;
  }

  console.log("🎉 ALL EXISTING PASSWORDS & SECRETS ARE NOW 100% ENCRYPTED IN NEON POSTGRES!");
}

encryptExistingData();
