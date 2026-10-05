import { Router } from 'express';
import { pool } from '../db/pool.js';
import { responderError } from '../utils/errores.js';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const { id_categoria } = req.query;
    const result = await pool.query('SELECT * FROM fn_listar_componentes_menu($1::integer)', [id_categoria ?? null]);
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

router.post('/', async (req, res) => {
  try {
    const { id_categoria_componente_menu, nombre, recargo } = req.body;
    if (!id_categoria_componente_menu || !nombre) {
      res.status(400).json({ error: 'Falta id_categoria_componente_menu o nombre' });
      return;
    }
    const result = await pool.query(
      'CALL sp_crear_componente_menu($1::integer, $2::varchar, $3::decimal, NULL)',
      [id_categoria_componente_menu, nombre, recargo ?? 0]
    );
    res.status(201).json({ id_componente: result.rows[0].p_id_componente });
  } catch (err) {
    responderError(res, err);
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { id_categoria_componente_menu, nombre, recargo, activo } = req.body;
    if (!id_categoria_componente_menu || !nombre) {
      res.status(400).json({ error: 'Falta id_categoria_componente_menu o nombre' });
      return;
    }
    await pool.query(
      'CALL sp_editar_componente_menu($1::integer, $2::integer, $3::varchar, $4::decimal, $5::boolean)',
      [req.params.id, id_categoria_componente_menu, nombre, recargo ?? 0, activo ?? true]
    );
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

export default router;