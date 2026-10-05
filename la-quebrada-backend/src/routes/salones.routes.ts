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

export default router;
