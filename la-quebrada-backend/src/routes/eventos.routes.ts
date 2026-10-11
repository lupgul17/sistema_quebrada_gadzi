import { Router } from 'express';
import { pool } from '../db/pool.js';
import fs from 'node:fs';
import type { AuthRequest } from '../middleware/auth.middleware.js';
import { responderError } from '../utils/errores.js';
import { fechaLocalHoy } from '../utils/validar.js';
import { uploadComprobante } from '../config/upload.js';
import { type RequestConAlcance, eventosEnAlcance, exigirAlcance, filtrarPorAlcance, salonesEnAlcance } from '../middleware/alcance.js';

const router = Router();

// Toda ruta con :id en este archivo es de un evento: si no es del área del usuario → 404
router.param('id', async (req, res, next, id) => {
  try {
    if (await exigirAlcance(req as RequestConAlcance, res, 'evento', id)) next();
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/eventos?estado=&fecha_desde=&fecha_hasta=&id_cliente=&calendario=1
// Solo los eventos del área del usuario. Con calendario=1 vienen también los demás, pero solo como
// "Ocupado" (fecha, horario y salón; sin cliente ni id): sirve para recomendar otro salón libre.
router.get('/', async (req: RequestConAlcance, res) => {
  try {
    const { estado, fecha_desde, fecha_hasta, id_cliente, calendario } = req.query;
    const result = await pool.query(
      'SELECT * FROM fn_listar_eventos($1::varchar, $2::date, $3::date, $4::integer)',
      [estado ?? null, fecha_desde ?? null, fecha_hasta ?? null, id_cliente ?? null]
    );
    const visibles = await eventosEnAlcance(req);
    if (visibles === null) {
      res.json(result.rows);
      return;
    }
    if (calendario === '1') {
      res.json(
        result.rows.map((ev) =>
          visibles.has(ev.id_evento)
            ? ev
            : {
                id_evento: null, fuera_de_alcance: true, cliente: 'Ocupado', fecha: ev.fecha,
                hora_inicio: ev.hora_inicio, hora_fin: ev.hora_fin, estado: ev.estado,
                reserva_temporal: ev.reserva_temporal, salones: ev.salones, locaciones: ev.locaciones,
              }
        )
      );
      return;
    }
    res.json(result.rows.filter((ev) => visibles.has(ev.id_evento)));
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/eventos/disponibilidad-salones?fecha=&hora_inicio=&hora_fin=&excluir_evento=
// OJO: tiene que ir ANTES que /:id, mismo motivo que "clientes/nuevo" en Angular
router.get('/disponibilidad-salones', async (req: RequestConAlcance, res) => {
  try {
    const { fecha, hora_inicio, hora_fin, excluir_evento } = req.query;
    if (!fecha || !hora_inicio || !hora_fin) {
      res.status(400).json({ error: 'Falta fecha, hora_inicio o hora_fin' });
      return;
    }
    const result = await pool.query(
      'SELECT * FROM fn_salones_disponibilidad($1::date, $2::time, $3::time, $4::integer)',
      [fecha, hora_inicio, hora_fin, excluir_evento ?? null]
    );
    // Para crear/editar un evento solo se ofrecen los salones del área del usuario
    const alcance = req.alcance;
    res.json(alcance ? result.rows.filter((s) => alcance.includes(s.id_salon)) : result.rows);
  } catch (err) {
    responderError(res, err);
  }
});
// GET /api/eventos/pendientes-pago
router.get('/pendientes-pago', async (req: RequestConAlcance, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_eventos_pendientes_pago()');
    res.json(await filtrarPorAlcance(req, result.rows));
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/eventos/:id/extras
router.get('/:id/extras', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_extras_evento($1::integer)', [req.params.id]);
    res.json(result.rows[0] ?? { id_extra: null, total: 0, servicios: [], menus: [] });
  } catch (err) {
    responderError(res, err);
  }
});
// GET /api/eventos/:id
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_evento_detalle($1::integer)', [req.params.id]);
    const evento = result.rows[0];
    if (!evento) {
      res.status(404).json({ error: 'Evento no encontrado' });
      return;
    }
    res.json(evento);
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/eventos
router.post('/', async (req: RequestConAlcance, res) => {
  try {
    const {
      id_cliente, id_tipo_evento, fecha, hora_inicio, hora_fin,
      total_adultos, total_menores, notas, reserva_temporal, salones,
    } = req.body;

    if (!id_cliente || !fecha || !hora_inicio || !hora_fin || !salones?.length) {
      res.status(400).json({ error: 'Falta id_cliente, fecha, hora_inicio, hora_fin o salones' });
      return;
    }
    if (!salonesEnAlcance(req, salones)) {
      res.status(403).json({ error: 'Solo podés crear eventos en los salones de tu área.' });
      return;
    }

    const result = await pool.query(
      `CALL sp_crear_evento(
        $1::integer, $2::integer, $3::date, $4::time, $5::time,
        $6::integer, $7::integer, $8::text, $9::boolean, $10::integer[], NULL
      )`,
      [
        id_cliente, id_tipo_evento ?? null, fecha, hora_inicio, hora_fin,
        total_adultos ?? 0, total_menores ?? 0, notas ?? null, reserva_temporal ?? false, salones,
      ]
    );

    res.status(201).json({ id_evento: result.rows[0].p_id_evento });
  } catch (err) {
    responderError(res, err);
  }
});

// PUT /api/eventos/:id
router.put('/:id', async (req: RequestConAlcance, res) => {
  try {
    const {
      id_tipo_evento, fecha, hora_inicio, hora_fin,
      total_adultos, total_menores, notas, reserva_temporal, salones,
    } = req.body;

    if (!fecha || !hora_inicio || !hora_fin || !salones?.length) {
      res.status(400).json({ error: 'Falta fecha, hora_inicio, hora_fin o salones' });
      return;
    }
    if (!salonesEnAlcance(req, salones)) {
      res.status(403).json({ error: 'Solo podés usar salones de tu área.' });
      return;
    }

    await pool.query(
      `CALL sp_editar_evento(
        $1::integer, $2::integer, $3::date, $4::time, $5::time,
        $6::integer, $7::integer, $8::text, $9::boolean, $10::integer[]
      )`,
      [
        req.params.id, id_tipo_evento ?? null, fecha, hora_inicio, hora_fin,
        total_adultos ?? 0, total_menores ?? 0, notas ?? null, reserva_temporal ?? false, salones,
      ]
    );

    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/eventos/:id/confirmacion - lo que necesita el modal "Confirmar evento"
router.get('/:id/confirmacion', async (req, res) => {
  try {
    const r = await pool.query(
      `SELECT fn_abono_minimo_confirmacion($1::integer) AS abono_minimo, fn_abonos_reserva($1::integer) AS abonado,
              (SELECT total FROM cotizacion WHERE id_evento = $1 AND activa) AS total_cotizacion`,
      [req.params.id]
    );
    const f = r.rows[0];
    res.json({
      abono_minimo: Number(f.abono_minimo),
      abonado: Number(f.abonado),
      total_cotizacion: f.total_cotizacion === null ? null : Number(f.total_cotizacion),
    });
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/eventos/:id/confirmar  (multipart: fecha_pago, monto, id_tipo_pago, notas?, comprobante?)
// Registra el abono de reserva y confirma el evento EN UNA SOLA TRANSACCIÓN: si el salón ya no está
// libre (u otra regla falla), no queda ni el pago ni el comprobante.
router.post('/:id/confirmar', uploadComprobante.single('comprobante'), async (req: AuthRequest, res) => {
  const rechazar = (status: number, error: string) => {
    if (req.file) fs.unlink(req.file.path, () => undefined);
    res.status(status).json({ error });
  };
  const { fecha_pago, monto, id_tipo_pago, notas } = req.body;
  const montoNum = Number(monto);
  if (!fecha_pago || !monto || !id_tipo_pago) return rechazar(400, 'Falta la fecha, el monto o la forma de pago del abono.');
  if (!Number.isFinite(montoNum) || montoNum <= 0 || montoNum > 1_000_000) return rechazar(400, 'El monto del abono no es válido.');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(fecha_pago)) || String(fecha_pago) > fechaLocalHoy()) {
    return rechazar(400, 'La fecha del pago no es válida o es futura.');
  }
  if (notas && String(notas).length > 500) return rechazar(400, 'Las notas pueden tener máximo 500 caracteres.');

  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    const empleado = await cliente.query('SELECT fn_id_empleado_por_persona($1::integer) AS id_empleado', [req.usuario!.id_persona]);
    const pago = await cliente.query(
      `CALL sp_registrar_pago($1::integer, $2::date, $3::decimal, $4::integer, 'reserva', 'staff', $5::integer, $6::varchar, $7::text, NULL)`,
      [req.params.id, fecha_pago, montoNum, id_tipo_pago, empleado.rows[0]?.id_empleado ?? null, req.file?.filename ?? null, String(notas ?? '').trim() || null]
    );
    // El SP valida el abono mínimo y que los salones sigan libres
    await cliente.query(`CALL sp_cambiar_estado_evento($1::integer, 'confirmado')`, [req.params.id]);
    await cliente.query('COMMIT');
    res.status(201).json({ ok: true, id_pago: pago.rows[0].p_id_pago });
  } catch (err) {
    await cliente.query('ROLLBACK').catch(() => undefined);
    if (req.file) fs.unlink(req.file.path, () => undefined);
    responderError(res, err);
  } finally {
    cliente.release();
  }
});

// PATCH /api/eventos/:id/estado
router.patch('/:id/estado', async (req, res) => {
  try {
    const { estado } = req.body;
    if (!estado) {
      res.status(400).json({ error: 'Falta estado' });
      return;
    }

    await pool.query('CALL sp_cambiar_estado_evento($1::integer, $2::varchar)', [req.params.id, estado]);

    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/eventos/:id/cotizaciones - historial de versiones
router.get('/:id/cotizaciones', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_cotizaciones_evento($1::integer)', [req.params.id]);
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/eventos/:id/pagos
router.get('/:id/pagos', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_pagos_evento($1::integer)', [req.params.id]);
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/eventos/:id/saldo
router.get('/:id/saldo', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_saldo_evento($1::integer)', [req.params.id]);
    const saldo = result.rows[0];
    if (!saldo) {
      res.status(404).json({ error: 'Evento no encontrado' });
      return;
    }
    res.json(saldo);
  } catch (err) {
    responderError(res, err);
  }
});
// GET /api/eventos/:id/degustaciones
router.get('/:id/degustaciones', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_degustaciones_evento($1::integer)', [req.params.id]);
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

export default router;