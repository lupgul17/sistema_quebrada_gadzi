import express from 'express';
import type { Request, Response, NextFunction } from 'express';
import multer from 'multer';
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
import recordatoriosRouter from './routes/recordatorios.routes.js';
import reportesRouter from './routes/reportes.routes.js';
import { iniciarJobRecordatorios } from './jobs/recordatorios.job.js';
import { requireAuth } from './middleware/auth.middleware.js';
import { aplicarPermisos } from './middleware/permisos.js';
import usuariosRouter from './routes/usuarios.routes.js';
import publicoRouter from './routes/publico.routes.js';
import prospectosRouter from './routes/prospectos.routes.js';
import { responderError } from './utils/errores.js';
import { cerrarNavegadorPdf } from './utils/pdf.js';
dotenv.config();

const app = express();
// Detrás de un proxy (Railway): sin esto, el límite de intentos vería la IP del proxy y no la del usuario
if (process.env.TRUST_PROXY) app.set('trust proxy', Number(process.env.TRUST_PROXY) || 1);
const PORT = process.env.PORT ?? 3000;

// Orígenes que pueden llamar a la API interna (el sistema). Separados por coma en CORS_ORIGENES.
const ORIGENES_PERMITIDOS = (process.env.CORS_ORIGENES ?? 'http://localhost:4200')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

app.use(express.json({ limit: '1mb' }));

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
// Rutas públicas de la landing: cualquier origen (son públicas) y van ANTES del middleware global de auth
app.use('/api/publico', cors(), publicoRouter);
app.use(cors({ origin: ORIGENES_PERMITIDOS }));
app.use('/api', requireAuth, aplicarPermisos);
app.use('/api/prospectos', prospectosRouter);
app.use('/api/usuarios', usuariosRouter);
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
app.use('/api/recordatorios', requireAuth, recordatoriosRouter);
app.use('/api/reportes', requireAuth, reportesRouter);
// Ruta inexistente dentro de /api: JSON en vez de la página HTML de Express
app.use('/api', (_req: Request, res: Response) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

// Errores que no pasan por el try/catch de las rutas: archivo inválido, JSON mal formado, etc.
app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  if (err instanceof multer.MulterError) {
    const mensaje = err.code === 'LIMIT_FILE_SIZE' ? 'El archivo supera el tamaño máximo de 5 MB' : 'No se pudo subir el archivo';
    res.status(400).json({ error: mensaje });
    return;
  }
  const e = err as { status?: number; type?: string; message?: string };
  if (e.type === 'entity.parse.failed') {
    res.status(400).json({ error: 'El cuerpo del pedido no es un JSON válido' });
    return;
  }
  if (e.type === 'entity.too.large') {
    res.status(413).json({ error: 'El pedido es demasiado grande' });
    return;
  }
  if (e.status && e.status >= 400 && e.status < 500) {
    res.status(e.status).json({ error: e.message });
    return;
  }
  responderError(res, err);
});

const servidor = app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
  console.log(`CORS permitido para: ${ORIGENES_PERMITIDOS.join(', ')}`);
  iniciarJobRecordatorios();
});

// Apagado ordenado: cerrar Chrome (PDFs) y las conexiones a la base
async function apagar(senal: string) {
  console.log(`
${senal} recibido, cerrando servidor...`);
  servidor.close();
  await cerrarNavegadorPdf();
  await pool.end().catch(() => undefined);
  process.exit(0);
}
process.on('SIGINT', () => void apagar('SIGINT'));
process.on('SIGTERM', () => void apagar('SIGTERM'));
