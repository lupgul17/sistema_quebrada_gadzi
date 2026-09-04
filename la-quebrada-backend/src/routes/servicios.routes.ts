import { Router } from 'express';
import { pool } from '../db/pool.js';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const { id_categoria_servicio } = req.query;
    const result = await pool.query('SELECT * FROM fn_listar_servicios($1::integer)', [id_categoria_servicio ?? null]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { id_categoria_servicio, nombre, precio_base, unidad_medida } = req.body;
    if (!id_categoria_servicio || !nombre || precio_base == null || !unidad_medida) {
      res.status(400).json({ error: 'Falta id_categoria_servicio, nombre, precio_base o unidad_medida' });
      return;
    }
    const result = await pool.query(
      'CALL sp_crear_servicio($1::integer, $2::varchar, $3::decimal, $4::varchar, NULL)',
      [id_categoria_servicio, nombre, precio_base, unidad_medida]
    );
    res.status(201).json({ id_servicio: result.rows[0].p_id_servicio });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { id_categoria_servicio, nombre, precio_base, unidad_medida, activo } = req.body;
    if (!id_categoria_servicio || !nombre || precio_base == null || !unidad_medida) {
      res.status(400).json({ error: 'Falta id_categoria_servicio, nombre, precio_base o unidad_medida' });
      return;
    }
    await pool.query(
      'CALL sp_editar_servicio($1::integer, $2::integer, $3::varchar, $4::decimal, $5::varchar, $6::boolean)',
      [req.params.id, id_categoria_servicio, nombre, precio_base, unidad_medida, activo ?? true]
    );
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

export default router;