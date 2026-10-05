import { Router } from 'express';
import type { Response } from 'express';
import { pool } from '../db/pool.js';

const router = Router();

const ESTADOS = ['nuevo', 'contactado', 'convertido', 'descartado'];

function responderError(res: Response, err: unknown): void {
  const e = err as { code?: string; message: string };
  // P0001 = RAISE EXCEPTION de nuestros procedimientos: error de negocio, no de servidor
  res.status(e.code === 'P0001' ? 400 : 500).json({ error: e.message });
}

// GET /api/prospectos?estado=
router.get('/', async (req, res) => {
  try {
    const estado = typeof req.query.estado === 'string' && ESTADOS.includes(req.query.estado) ? req.query.estado : null;
    const result = await pool.query('SELECT * FROM fn_listar_prospectos($1::varchar)', [estado]);
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/prospectos/pendientes/count - para el badge del sidebar
router.get('/pendientes/count', async (_req, res) => {
  try {
    const result = await pool.query(`SELECT COUNT(*)::int AS count FROM prospecto WHERE estado = 'nuevo'`);
    res.json(result.rows[0]);
  } catch (err) {
    responderError(res, err);
  }
});

// PATCH /api/prospectos/:id
router.patch('/:id', async (req, res) => {
  try {
    const { estado, notas_internas, id_cliente, id_evento } = req.body;
    if (!estado) {
      res.status(400).json({ error: 'Falta estado' });
      return;
    }
    await pool.query('CALL sp_actualizar_prospecto($1::integer, $2::varchar, $3::text, $4::integer, $5::integer)', [
      req.params.id,
      estado,
      notas_internas ?? null,
      id_cliente ?? null,
      id_evento ?? null,
    ]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

export default router;
