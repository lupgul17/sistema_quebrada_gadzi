import { Router } from 'express';
import { ejecutarRecordatorios } from '../jobs/recordatorios.job.js';

const router = Router();

// POST /api/recordatorios/ejecutar-ahora
router.post('/ejecutar-ahora', async (_req, res) => {
  try {
    const resultado = await ejecutarRecordatorios();
    res.json(resultado);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

export default router;