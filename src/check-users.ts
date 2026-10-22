import 'dotenv/config';
import { neon } from '@neondatabase/serverless';

const sql = neon(process.env.DATABASE_URL!);

async function check() {
  const users = await sql`SELECT * FROM users;`;
  console.log("Current users in Neon DB:", users);
}

check();
