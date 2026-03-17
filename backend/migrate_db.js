const { pool } = require('./database');

async function migrate() {
  try {
    console.log('Migrando base de datos...');
    await pool.query('ALTER TABLE aprendidos ADD COLUMN IF NOT EXISTS stars INTEGER NOT NULL DEFAULT 1;');
    console.log('Columna "stars" añadida a "aprendidos".');
    process.exit(0);
  } catch (err) {
    console.error('Error migrando:', err);
    process.exit(1);
  }
}

migrate();
