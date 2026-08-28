import { Router } from 'express';
import { pool } from '../db/pool.js';

const router = Router();

// GET /api/salones - lista todos los salones con su locación
router.get('/', async (_req, res) => {
  try {
    const result = await pool.query(`SELECT * FROM fn_listar_salones()`);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

export default router;
