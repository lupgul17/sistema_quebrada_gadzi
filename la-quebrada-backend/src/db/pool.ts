import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

if (!process.env.DATABASE_URL) {
  throw new Error('Falta DATABASE_URL en el archivo .env');
}

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Neon requiere SSL. rejectUnauthorized:false evita problemas de
  // verificación de certificado con el endpoint pooler de Neon.
  // Es una configuración normal para este caso, no un riesgo real
  // en una base de desarrollo.
  ssl: { rejectUnauthorized: false },
});

pool.on('error', (err) => {
  console.error('Error inesperado en el pool de Postgres:', err);
});
