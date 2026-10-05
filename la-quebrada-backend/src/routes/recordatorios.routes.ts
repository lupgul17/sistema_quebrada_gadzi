import { Router } from 'express';
import { ejecutarRecordatorios } from '../jobs/recordatorios.job.js';
import { responderError } from '../utils/errores.js';

const router = Router();

// POST /api/recordatorios/ejecutar-ahora
router.post('/ejecutar-ahora', async (_req, res) => {
  try {
    const resultado = await ejecutarRecordatorios();
    res.json(resultado);
  } catch (err) {
    responderError(res, err);
  }
});

export default router;