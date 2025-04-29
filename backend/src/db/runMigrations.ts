//backend/src/db/runMigrations.ts
import pool from './index';
import fs from 'fs';
import path from 'path';

async function runMigrations() {
  const schemaPath = path.join(__dirname, 'migrations', 'schema.sql');
  const sql = fs.readFileSync(schemaPath, 'utf8');

  try {
    await pool.query(sql);
    console.log('✅ Database schema created successfully.');
  } catch (error) {
    console.error('❌ Error running migrations:', error);
  } finally {
    await pool.end();
  }
}

runMigrations();
