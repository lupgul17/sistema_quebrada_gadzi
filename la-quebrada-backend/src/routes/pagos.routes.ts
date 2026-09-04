import { Router } from 'express';
import { pool } from '../db/pool.js';
import {AuthRequest} from '../middleware/auth.middleware.js';
import path from 'path';
import { UPLOADS_DIR } from '../config/upload.js';
import {uploadComprobante} from '../config/upload.js';

const router = Router();

// GET /api/pagos/pendientes - bandeja global de verificación
router.get('/pendientes', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_pagos_pendientes_verificacion()');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

/// POST /api/pagos
router.post('/', uploadComprobante.single('comprobante'), async (req: AuthRequest, res) => {
  try {
    const { id_evento, fecha_pago, monto, id_tipo_pago, concepto, origen, notas } = req.body;
    if (!id_evento || !fecha_pago || !monto || !id_tipo_pago || !concepto || !origen) {
      res.status(400).json({ error: 'Falta id_evento, fecha_pago, monto, id_tipo_pago, concepto u origen' });
      return;
    }

    const empleadoResult = await pool.query('SELECT fn_id_empleado_por_persona($1::integer) AS id_empleado', [req.usuario!.id_persona]);
    const idEmpleado = empleadoResult.rows[0]?.id_empleado ?? null;

    const pathComprobante = req.file ? req.file.filename : null;

    const result = await pool.query(
      `CALL sp_registrar_pago($1::integer, $2::date, $3::decimal, $4::integer, $5::varchar, $6::varchar, $7::integer, $8::varchar, $9::text, NULL)`,
      [id_evento, fecha_pago, monto, id_tipo_pago, concepto, origen, idEmpleado, pathComprobante, notas || null]
    );
    res.status(201).json({ id_pago: result.rows[0].p_id_pago });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// PATCH /api/pagos/:id/verificar
router.patch('/:id/verificar', async (req: AuthRequest, res) => {
  try {
    const { estado, motivo_rechazo } = req.body;
    if (!estado) {
      res.status(400).json({ error: 'Falta estado' });
      return;
    }

    const empleadoResult = await pool.query('SELECT fn_id_empleado_por_persona($1::integer) AS id_empleado', [req.usuario!.id_persona]);
    const idEmpleado = empleadoResult.rows[0]?.id_empleado;

    if (!idEmpleado) {
      res.status(403).json({ error: 'Tu usuario no está vinculado a un empleado, no podés verificar pagos' });
      return;
    }

    await pool.query('CALL sp_verificar_pago($1::integer, $2::varchar, $3::integer, $4::text)', [req.params.id, estado, idEmpleado, motivo_rechazo ?? null]);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// GET /api/pagos/verificados - historial global de pagos ya aprobados
router.get('/verificados', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_pagos_verificados()');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});
// GET /api/pagos/comprobante/:filename
router.get('/comprobante/:filename', (req, res) => {
  const filename = req.params.filename;
  if (filename.includes('..') || filename.includes('/') || filename.includes('\\')) {
    res.status(400).json({ error: 'Nombre de archivo inválido' });
    return;
  }
  res.sendFile(path.join(UPLOADS_DIR, filename), (err) => {
    if (err) res.status(404).json({ error: 'Comprobante no encontrado' });
  });
});

export default router;