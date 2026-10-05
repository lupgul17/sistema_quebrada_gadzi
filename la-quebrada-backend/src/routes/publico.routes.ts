import { Router } from 'express';
import { pool } from '../db/pool.js';
import { crearLimitador } from '../middleware/limitador.js';

/**
 * Endpoints SIN autenticación que consume la landing page.
 * Se montan antes del middleware global de auth. Solo exponen:
 * salones, tipos de evento, fechas ocupadas (sin datos de clientes)
 * y la creación de solicitudes (prospectos).
 */
const router = Router();

const MAX_DIAS_RANGO = 100;
const FECHA_ISO = /^\d{4}-\d{2}-\d{2}$/;

// 5 solicitudes por hora por IP para el formulario de la landing
const limiteSolicitudes = crearLimitador({
  ventanaMs: 60 * 60 * 1000,
  max: 5,
  mensaje: 'Recibimos varias solicitudes desde tu conexión. Intentá de nuevo más tarde o escribinos por WhatsApp.',
});

function texto(valor: unknown, max: number): string | null {
  if (typeof valor !== 'string') return null;
  const limpio = valor.trim();
  return limpio === '' ? null : limpio.slice(0, max);
}

function entero(valor: unknown): number | null {
  const n = Number(valor);
  return Number.isInteger(n) && n > 0 ? n : null;
}

// GET /api/publico/salones
router.get('/salones', async (_req, res) => {
  try {
    const result = await pool.query('SELECT id_salon, nombre, capacidad, locacion FROM fn_listar_salones()');
    res.json(result.rows);
  } catch {
    res.status(500).json({ error: 'No se pudieron cargar los salones' });
  }
});

// GET /api/publico/tipos-evento
router.get('/tipos-evento', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_tipos_evento()');
    res.json(result.rows);
  } catch {
    res.status(500).json({ error: 'No se pudieron cargar los tipos de evento' });
  }
});

// GET /api/publico/fechas-ocupadas?desde=YYYY-MM-DD&hasta=YYYY-MM-DD
router.get('/fechas-ocupadas', async (req, res) => {
  const { desde, hasta } = req.query;
  if (typeof desde !== 'string' || typeof hasta !== 'string' || !FECHA_ISO.test(desde) || !FECHA_ISO.test(hasta)) {
    res.status(400).json({ error: 'Parámetros desde/hasta inválidos (formato YYYY-MM-DD)' });
    return;
  }
  const dias = (Date.parse(hasta) - Date.parse(desde)) / 86_400_000;
  if (Number.isNaN(dias) || dias < 0 || dias > MAX_DIAS_RANGO) {
    res.status(400).json({ error: `El rango debe ser de 0 a ${MAX_DIAS_RANGO} días` });
    return;
  }
  try {
    const result = await pool.query(
      `SELECT to_char(fecha, 'YYYY-MM-DD') AS fecha, id_salon FROM fn_fechas_ocupadas_publico($1::date, $2::date)`,
      [desde, hasta]
    );
    res.json(result.rows);
  } catch {
    res.status(500).json({ error: 'No se pudo consultar la disponibilidad' });
  }
});

// POST /api/publico/solicitudes
router.post('/solicitudes', limiteSolicitudes.middleware, async (req, res) => {
  const body = req.body ?? {};

  // Honeypot: campo invisible en el formulario. Un humano lo deja vacío; un bot suele llenarlo.
  // Se responde 201 igual para que el bot no sepa que fue descartado.
  if (texto(body.sitio_web, 200)) {
    res.status(201).json({ ok: true });
    return;
  }

  const nombre = texto(body.nombre, 150);
  const telefono = texto(body.telefono, 30);
  const correo = texto(body.correo, 150);
  const mensaje = texto(body.mensaje, 2000);
  const fecha = texto(body.fecha_tentativa, 10);

  if (!nombre || !telefono) {
    res.status(400).json({ error: 'Nombre y teléfono son obligatorios' });
    return;
  }
  if (!/^[\d\s+()-]{7,30}$/.test(telefono)) {
    res.status(400).json({ error: 'El teléfono no parece válido' });
    return;
  }
  if (correo && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo)) {
    res.status(400).json({ error: 'El correo no parece válido' });
    return;
  }
  if (fecha && !FECHA_ISO.test(fecha)) {
    res.status(400).json({ error: 'Fecha tentativa inválida' });
    return;
  }

  try {
    await pool.query(
      `CALL sp_crear_prospecto($1::varchar, $2::varchar, $3::varchar, $4::integer, $5::integer, $6::date, $7::integer, $8::text, $9::varchar, NULL)`,
      [nombre, telefono, correo, entero(body.id_tipo_evento), entero(body.id_salon), fecha, entero(body.invitados), mensaje, req.ip ?? null]
    );
    res.status(201).json({ ok: true });
  } catch (err) {
    const e = err as { code?: string; message: string };
    // P0001 = validación de negocio del procedimiento; 23503 = salón/tipo inexistente
    if (e.code === 'P0001') {
      res.status(400).json({ error: e.message });
    } else if (e.code === '23503') {
      res.status(400).json({ error: 'El salón o el tipo de evento elegido no existe' });
    } else {
      console.error('Error creando prospecto:', err);
      res.status(500).json({ error: 'No pudimos registrar tu solicitud. Escribinos por WhatsApp.' });
    }
  }
});

export default router;
