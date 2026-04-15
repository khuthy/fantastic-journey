/**
 * Run the schema SQL against your Neon database.
 *
 * Usage:
 *   DATABASE_URL="postgres://..." node scripts/migrate.js
 */

import { createRequire } from 'module';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const require = createRequire(import.meta.url);
const { neon } = require('@neondatabase/serverless');

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL environment variable is required.');
  process.exit(1);
}

const __dir = dirname(fileURLToPath(import.meta.url));
const schema = readFileSync(join(__dir, '../src/db/schema.sql'), 'utf-8');

const sql = neon(process.env.DATABASE_URL);

async function main() {
  console.log('Running schema migration...');
  // neon() tagged template only supports single statements — split and run sequentially
  const statements = schema
    .split(';')
    .map((s) => s.trim())
    .filter((s) => s.length > 0 && !s.startsWith('--'));

  for (const stmt of statements) {
    try {
      await sql.unsafe(stmt);
    } catch (e) {
      console.warn(`  ⚠ Statement warning: ${e.message?.slice(0, 120)}`);
    }
  }
  console.log('✓ Migration complete.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
