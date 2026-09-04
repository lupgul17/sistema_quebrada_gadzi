import { Router } from 'express';
import { pool } from '../db/pool.js';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const { id_tipo_menu } = req.query;
    const result = await pool.query('SELECT * FROM fn_listar_menus($1::integer)', [id_tipo_menu ?? null]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_menu_detalle($1::integer)', [req.params.id]);
    const menu = result.rows[0];
    if (!menu) {
      res.status(404).json({ error: 'Menú no encontrado' });
      return;
    }
    res.json(menu);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, componentes } = req.body;
    if (!nombre || !id_tipo_menu || precio_base == null || !unidad_medida) {
      res.status(400).json({ error: 'Falta nombre, id_tipo_menu, precio_base o unidad_medida' });
      return;
    }
    const result = await pool.query(
      `CALL sp_crear_menu($1::varchar, $2::integer, $3::decimal, $4::varchar, $5::text, $6::integer[], NULL)`,
      [nombre, id_tipo_menu, precio_base, unidad_medida, descripcion ?? null, componentes ?? []]
    );
    res.status(201).json({ id_menu: result.rows[0].p_id_menu });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, activo, componentes } = req.body;
    if (!nombre || !id_tipo_menu || precio_base == null || !unidad_medida) {
      res.status(400).json({ error: 'Falta nombre, id_tipo_menu, precio_base o unidad_medida' });
      return;
    }
    await pool.query(
      `CALL sp_editar_menu($1::integer, $2::varchar, $3::integer, $4::decimal, $5::varchar, $6::text, $7::boolean, $8::integer[])`,
      [req.params.id, nombre, id_tipo_menu, precio_base, unidad_medida, descripcion ?? null, activo ?? true, componentes ?? []]
    );
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

export default router;