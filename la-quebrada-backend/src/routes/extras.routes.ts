import { Router } from 'express';
import { pool } from '../db/pool.js';
import type { AuthRequest } from '../middleware/auth.middleware.js';

const router = Router();

// POST /api/extras/servicio
router.post('/servicio', async (req: AuthRequest, res) => {
  try {
    const { id_evento, id_tipo_cargo_extra, id_servicio, descripcion, cantidad, precio_unitario } = req.body;
    if (!id_evento || !id_tipo_cargo_extra || !cantidad || precio_unitario == null) {
      res.status(400).json({ error: 'Falta id_evento, id_tipo_cargo_extra, cantidad o precio_unitario' });
      return;
    }

    const empleadoResult = await pool.query('SELECT fn_id_empleado_por_persona($1::integer) AS id_empleado', [req.usuario!.id_persona]);
    const idEmpleado = empleadoResult.rows[0]?.id_empleado ?? null;

    const result = await pool.query(
      `SELECT sp_agregar_extra_servicio($1::integer, $2::integer, $3::integer, $4::text, $5::integer, $6::numeric, $7::integer) AS p_id_extras_servicios`,
      [id_evento, id_tipo_cargo_extra, id_servicio ?? null, descripcion ?? null, cantidad, precio_unitario, idEmpleado]
    );
    res.status(201).json({ id_extras_servicios: result.rows[0].p_id_extras_servicios });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// POST /api/extras/menu
router.post('/menu', async (req: AuthRequest, res) => {
  try {
    const { id_evento, id_menu, descripcion, cantidad, precio_base } = req.body;
    if (!id_evento || !cantidad || precio_base == null) {
      res.status(400).json({ error: 'Falta id_evento, cantidad o precio_base' });
      return;
    }

    const empleadoResult = await pool.query('SELECT fn_id_empleado_por_persona($1::integer) AS id_empleado', [req.usuario!.id_persona]);
    const idEmpleado = empleadoResult.rows[0]?.id_empleado ?? null;

    const result = await pool.query(
      `SELECT sp_agregar_extra_menu($1::integer, $2::integer, $3::text, $4::integer, $5::numeric, $6::integer) AS p_id_extras_menu`,
      [id_evento, id_menu ?? null, descripcion ?? null, cantidad, precio_base, idEmpleado]
    );
    res.status(201).json({ id_extras_menu: result.rows[0].p_id_extras_menu });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// PATCH /api/extras/:tipo/:idLinea/cancelar
router.patch('/:tipo/:idLinea/cancelar', async (req, res) => {
  try {
    const { tipo, idLinea } = req.params;
    if (tipo !== 'servicio' && tipo !== 'menu') {
      res.status(400).json({ error: 'tipo debe ser "servicio" o "menu"' });
      return;
    }
    const result = await pool.query('SELECT sp_cancelar_extra($1::varchar, $2::integer) AS p_ok', [tipo, idLinea]);
    if (!result.rows[0].p_ok) {
      res.status(404).json({ error: 'No se encontró esa línea, o ya estaba cancelada' });
      return;
    }
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

export default router;