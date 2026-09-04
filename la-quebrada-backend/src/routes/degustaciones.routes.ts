import { Router } from 'express';
import { pool } from '../db/pool.js';

const router = Router();

// GET /api/degustaciones/fechas
router.get('/fechas', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_fechas_degustacion()');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// POST /api/degustaciones/fechas
router.post('/fechas', async (req, res) => {
  try {
    const { fecha, hora_inicio, hora_fin } = req.body;
    if (!fecha || !hora_inicio) {
      res.status(400).json({ error: 'Falta fecha u hora_inicio' });
      return;
    }
    const result = await pool.query(
      'CALL sp_crear_fecha_degustacion($1::date, $2::time, $3::time, NULL)',
      [fecha, hora_inicio, hora_fin ?? null]
    );
    res.status(201).json({ id_fecha_degustacion: result.rows[0].p_id_fecha_degustacion });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// PATCH /api/degustaciones/fechas/:id/estado
router.patch('/fechas/:id/estado', async (req, res) => {
  try {
    const { estado } = req.body;
    if (!estado) {
      res.status(400).json({ error: 'Falta estado' });
      return;
    }
    await pool.query('CALL sp_cambiar_estado_fecha_degustacion($1::integer, $2::varchar)', [req.params.id, estado]);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// GET /api/degustaciones/:id
router.get('/:id', async (req, res) => {
  try {
    const [detalle, menus] = await Promise.all([
      pool.query('SELECT * FROM fn_degustacion_detalle($1::integer)', [req.params.id]),
      pool.query('SELECT * FROM fn_listar_menus_degustacion($1::integer)', [req.params.id]),
    ]);
    const degustacion = detalle.rows[0];
    if (!degustacion) {
      res.status(404).json({ error: 'Degustación no encontrada' });
      return;
    }
    res.json({ ...degustacion, menus: menus.rows });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// POST /api/degustaciones
router.post('/', async (req, res) => {
  try {
    const { id_evento, id_fecha_degustacion, hora_llegada, notas } = req.body;
    if (!id_evento || !id_fecha_degustacion) {
      res.status(400).json({ error: 'Falta id_evento o id_fecha_degustacion' });
      return;
    }
    const result = await pool.query(
      'CALL sp_agendar_degustacion($1::integer, $2::integer, $3::time, $4::text, NULL)',
      [id_evento, id_fecha_degustacion, hora_llegada ?? null, notas ?? null]
    );
    res.status(201).json({ id_degustacion: result.rows[0].p_id_degustacion });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// PATCH /api/degustaciones/:id/estado
router.patch('/:id/estado', async (req, res) => {
  try {
    const { estado } = req.body;
    if (!estado) {
      res.status(400).json({ error: 'Falta estado' });
      return;
    }
    await pool.query('CALL sp_cambiar_estado_degustacion($1::integer, $2::varchar)', [req.params.id, estado]);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// POST /api/degustaciones/:id/menu
router.post('/:id/menu', async (req, res) => {
  try {
    const { id_menu } = req.body;
    if (!id_menu) {
      res.status(400).json({ error: 'Falta id_menu' });
      return;
    }
    const result = await pool.query('CALL sp_agregar_menu_degustacion($1::integer, $2::integer, NULL)', [req.params.id, id_menu]);
    res.status(201).json({ id_degustacion_menu: result.rows[0].p_id_degustacion_menu });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// PATCH /api/degustaciones/menu/:idLinea
router.patch('/menu/:idLinea', async (req, res) => {
  try {
    const { resultado, notas } = req.body;
    if (!resultado) {
      res.status(400).json({ error: 'Falta resultado' });
      return;
    }
    await pool.query('CALL sp_resolver_menu_degustacion($1::integer, $2::varchar, $3::text)', [req.params.idLinea, resultado, notas ?? null]);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});
// GET /api/degustaciones/fechas/:id/agendados
router.get('/fechas/:id/agendados', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_degustaciones_por_fecha($1::integer)', [req.params.id]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

export default router;