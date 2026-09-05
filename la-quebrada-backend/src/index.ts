import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { pool } from './db/pool.js';
import salonesRouter from './routes/salones.routes.js';
import authRouter from './routes/auth.routes.js';
import clientesRouter from './routes/clientes.routes.js'
import eventosRouter from './routes/eventos.routes.js';
import tiposEventoRouter from './routes/tipos-evento.routes.js';
import catalogosRouter from './routes/catalogo.routes.js';
import serviciosRouter from './routes/servicios.routes.js';
import componentesMenuRouter from './routes/comoponentes-menu.routes.js';
import menusRouter from './routes/menus.routes.js';
import cotizacionesRouter from './routes/cotizaciones.routes.js';
import pagosRouter from './routes/pagos.routes.js';
import degustacionesRouter from './routes/degustaciones.routes.js';
import extrasRouter from './routes/extras.routes.js';
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
app.use('/api/clientes',requireAuth, clientesRouter);
app.use('/api/eventos',requireAuth, eventosRouter);
app.use('/api/tipos-evento', requireAuth, tiposEventoRouter);
app.use('/api/catalogos', requireAuth, catalogosRouter);
app.use('/api/servicios', requireAuth, serviciosRouter);
app.use('/api/componentes-menu', requireAuth, componentesMenuRouter);
app.use('/api/menus', requireAuth, menusRouter);
app.use('/api/cotizaciones', requireAuth, cotizacionesRouter);
app.use('/api/pagos', requireAuth, pagosRouter);
app.use('/api/degustaciones', requireAuth, degustacionesRouter);
app.use('/api/extras', requireAuth, extrasRouter);

app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});