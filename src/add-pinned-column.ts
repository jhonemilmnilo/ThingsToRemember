import { neon } from '@neondatabase/serverless';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error('DATABASE_URL is missing!');
  process.exit(1);
}

const sql = neon(databaseUrl);

async function addPinnedColumns() {
  console.log('Adding is_pinned column to tables in Neon DB...');
  try {
    await sql`ALTER TABLE credentials ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;`;
    console.log('✓ Added is_pinned to credentials');

    await sql`ALTER TABLE secure_notes ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;`;
    console.log('✓ Added is_pinned to secure_notes');

    await sql`ALTER TABLE emergency_contacts ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;`;
    console.log('✓ Added is_pinned to emergency_contacts');

    await sql`ALTER TABLE family_members ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;`;
    console.log('✓ Added is_pinned to family_members');

    console.log('All tables updated with is_pinned successfully!');
  } catch (err) {
    console.error('Error adding is_pinned:', err);
    process.exit(1);
  }
}

addPinnedColumns();
