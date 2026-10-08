import fs from 'node:fs';
import { Router } from 'express';
import { pool } from '../db/pool.js';
import {AuthRequest} from '../middleware/auth.middleware.js';
import path from 'path';
import { UPLOADS_DIR } from '../config/upload.js';
import {uploadComprobante} from '../config/upload.js';
import { type RequestConAlcance, exigirAlcance, filtrarPorAlcance, guardiaAlcance } from '../middleware/alcance.js';
import { responderError } from '../utils/errores.js';

const CONCEPTOS_PAGO = ['reserva', 'abono', 'saldo', 'recargo'];

/** Hoy en formato YYYY-MM-DD según la hora local del servidor (TZ America/Guatemala en Railway). */
function fechaLocalHoy(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

const router = Router();

router.param('id', guardiaAlcance('pago'));

// GET /api/pagos/pendientes - bandeja global de verificación
router.get('/pendientes', async (req: RequestConAlcance, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_pagos_pendientes_verificacion()');
    res.json(await filtrarPorAlcance(req, result.rows));
  } catch (err) {
    responderError(res, err);
  }
});

/// POST /api/pagos
router.post('/', uploadComprobante.single('comprobante'), async (req: AuthRequest, res) => {
  try {
    const { id_evento, fecha_pago, monto, id_tipo_pago, concepto, origen, notas } = req.body;
    const rechazar = (error: string) => {
      // El comprobante ya se subió: si el pago no se registra, no debe quedar el archivo suelto
      if (req.file) fs.unlink(req.file.path, () => undefined);
      res.status(400).json({ error });
    };
    if (!id_evento || !fecha_pago || !monto || !id_tipo_pago || !concepto || !origen) {
      rechazar('Falta id_evento, fecha_pago, monto, id_tipo_pago, concepto u origen');
      return;
    }
    const montoNum = Number(monto);
    if (!Number.isFinite(montoNum) || montoNum <= 0 || montoNum > 1_000_000) {
      rechazar('El monto debe ser mayor a Q0.');
      return;
    }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(String(fecha_pago)) || String(fecha_pago) > fechaLocalHoy()) {
      rechazar('La fecha del pago no es válida o es futura.');
      return;
    }
    if (!CONCEPTOS_PAGO.includes(String(concepto))) {
      rechazar('El concepto del pago no es válido.');
      return;
    }
    if (notas && String(notas).length > 500) {
      rechazar('Las notas pueden tener máximo 500 caracteres.');
      return;
    }
    const alcance = (req as RequestConAlcance).alcance;
    if (alcance) {
      const enArea = await pool.query('SELECT fn_evento_en_alcance($1::integer, $2::integer[]) AS ok', [id_evento, alcance]);
      if (!enArea.rows[0]?.ok) {
        if (req.file) fs.unlink(req.file.path, () => undefined);
        res.status(404).json({ error: 'No encontrado' });
        return;
      }
    }

    const empleadoResult = await pool.query('SELECT fn_id_empleado_por_persona($1::integer) AS id_empleado', [req.usuario!.id_persona]);
    const idEmpleado = empleadoResult.rows[0]?.id_empleado ?? null;

    const pathComprobante = req.file ? req.file.filename : null;

    const result = await pool.query(
      `CALL sp_registrar_pago($1::integer, $2::date, $3::decimal, $4::integer, $5::varchar, $6::varchar, $7::integer, $8::varchar, $9::text, NULL)`,
      [id_evento, fecha_pago, montoNum, id_tipo_pago, concepto, origen, idEmpleado, pathComprobante, String(notas ?? '').trim() || null]
    );
    res.status(201).json({ id_pago: result.rows[0].p_id_pago });
  } catch (err) {
    responderError(res, err);
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
    responderError(res, err);
  }
});

// GET /api/pagos/verificados - historial global de pagos ya aprobados
router.get('/verificados', async (req: RequestConAlcance, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_pagos_verificados()');
    res.json(await filtrarPorAlcance(req, result.rows));
  } catch (err) {
    responderError(res, err);
  }
});
// GET /api/pagos/comprobante/:filename
router.get('/comprobante/:filename', async (req: RequestConAlcance, res) => {
  const filename = req.params.filename;
  if (filename.includes('..') || filename.includes('/') || filename.includes('\\')) {
    res.status(400).json({ error: 'Nombre de archivo inválido' });
    return;
  }
  // El comprobante es de un pago: solo lo ve quien tiene ese evento en su área
  if (req.alcance) {
    const pago = await pool.query('SELECT id_pago FROM pago WHERE path_comprobante = $1', [filename]);
    if (!pago.rows[0] || !(await exigirAlcance(req, res, 'pago', pago.rows[0].id_pago))) {
      if (!res.headersSent) res.status(404).json({ error: 'Comprobante no encontrado' });
      return;
    }
  }
  res.sendFile(path.join(UPLOADS_DIR, filename), (err) => {
    if (err) res.status(404).json({ error: 'Comprobante no encontrado' });
  });
});

export default router;