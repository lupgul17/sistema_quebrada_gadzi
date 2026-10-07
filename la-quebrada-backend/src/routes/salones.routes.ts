import { Router } from 'express';
import { pool } from '../db/pool.js';
import { responderError } from '../utils/errores.js';

const router = Router();

// GET /api/salones - lista todos los salones con su locación
router.get('/', async (_req, res) => {
  try {
    const result = await pool.query(`SELECT * FROM fn_listar_salones()`);
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/salones/areas - locaciones con sus salones (para elegir dónde se ofrece un menú)
router.get('/areas', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_areas_menu()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

export default router;
