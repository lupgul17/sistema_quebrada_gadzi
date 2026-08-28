import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { pool } from './db/pool.js';
import salonesRouter from './routes/salones.routes.js';
import authRouter from './routes/auth.routes.js';
import { requireAuth } from './middleware/auth.middleware.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT ?? 3000;

app.use(cors());
app.use(express.json());

app.get('/api/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', db: 'conectado' });
  } catch (err) {
    res.status(500).json({
      status: 'error',
      db: 'sin conexion',
      detail: (err as Error).message,
    });
  }
});

app.use('/api/auth', authRouter);
app.use('/api/salones', requireAuth, salonesRouter);

app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});