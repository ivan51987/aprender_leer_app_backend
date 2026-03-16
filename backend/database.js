const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: {
    rejectUnauthorized: false
  }
});

// the pool will emit an error on behalf of any idle client
// it contains if a backend error or network partition happens
pool.on('error', (err, client) => {
  console.error('Unexpected error on idle client', err);
  // We don't necessarily want to exit here, but we should log it
});

async function initDB() {
  const initQueries = `
    CREATE TABLE IF NOT EXISTS ninos (
      id SERIAL PRIMARY KEY,
      nombre VARCHAR(255) NOT NULL,
      fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS puntuaciones (
      id SERIAL PRIMARY KEY,
      nino_id INTEGER REFERENCES ninos(id),
      categoria VARCHAR(255) NOT NULL,
      juego_tipo VARCHAR(100),
      puntuacion INTEGER NOT NULL,
      estrellas INTEGER NOT NULL DEFAULT 0,
      fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(nino_id, categoria, juego_tipo)
    );

    CREATE TABLE IF NOT EXISTS aprendidos (
      id SERIAL PRIMARY KEY,
      nino_id INTEGER REFERENCES ninos(id),
      item_texto TEXT NOT NULL,
      categoria VARCHAR(255) NOT NULL,
      fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(nino_id, item_texto)
    );

    CREATE TABLE IF NOT EXISTS recompensas (
      id SERIAL PRIMARY KEY,
      nino_id INTEGER REFERENCES ninos(id),
      tipo VARCHAR(100) NOT NULL,
      cantidad INTEGER NOT NULL,
      fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `;
  try {
    console.log('Intentando conectar a la base de datos en:', process.env.DB_HOST);
    await pool.query(initQueries);
    console.log('Conexión exitosa. Tablas inicializadas correctamente en PostgreSQL');
  } catch (err) {
    console.error('Error inicializando tablas en PostgreSQL:', err);
    console.error('Detalles del error:', {
      message: err.message,
      stack: err.stack,
      code: err.code
    });
  }
}

module.exports = {
  pool,
  initDB,
};
