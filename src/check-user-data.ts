import 'dotenv/config';
import { neon } from '@neondatabase/serverless';

const sql = neon(process.env.DATABASE_URL!);

async function checkUserData() {
  const userId = 'c348cec2-1204-4af9-9a79-172091a91f16';
  const creds = await sql`SELECT * FROM credentials WHERE user_id = ${userId};`;
  console.log("Credentials for user:", creds.length, creds);

  const notes = await sql`SELECT * FROM secure_notes WHERE user_id = ${userId};`;
  console.log("Notes for user:", notes.length, notes);

  const contacts = await sql`SELECT * FROM emergency_contacts WHERE user_id = ${userId};`;
  console.log("Contacts for user:", contacts.length, contacts);

  const family = await sql`SELECT * FROM family_members WHERE user_id = ${userId};`;
  console.log("Family for user:", family.length, family);

  const wifi = await sql`SELECT * FROM wifi_networks WHERE user_id = ${userId};`;
  console.log("WiFi for user:", wifi.length, wifi);
}

checkUserData();

