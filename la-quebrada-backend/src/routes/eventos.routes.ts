import { Router } from 'express';
import { pool } from '../db/pool.js';

const router = Router();

// GET /api/eventos?estado=&fecha_desde=&fecha_hasta=&id_cliente=
router.get('/', async (req, res) => {
  try {
    const { estado, fecha_desde, fecha_hasta, id_cliente } = req.query;
    const result = await pool.query(
      'SELECT * FROM fn_listar_eventos($1::varchar, $2::date, $3::date, $4::integer)',
      [estado ?? null, fecha_desde ?? null, fecha_hasta ?? null, id_cliente ?? null]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// GET /api/eventos/disponibilidad-salones?fecha=&hora_inicio=&hora_fin=&excluir_evento=
// OJO: tiene que ir ANTES que /:id, mismo motivo que "clientes/nuevo" en Angular
router.get('/disponibilidad-salones', async (req, res) => {
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
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});
// GET /api/eventos/pendientes-pago
router.get('/pendientes-pago', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_eventos_pendientes_pago()');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// GET /api/eventos/:id/extras
router.get('/:id/extras', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_extras_evento($1::integer)', [req.params.id]);
    res.json(result.rows[0] ?? { id_extra: null, total: 0, servicios: [], menus: [] });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
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
    res.status(500).json({ error: (err as Error).message });
  }
});

// POST /api/eventos
router.post('/', async (req, res) => {
  try {
    const {
      id_cliente, id_tipo_evento, fecha, hora_inicio, hora_fin,
      total_adultos, total_menores, notas, reserva_temporal, salones,
    } = req.body;

    if (!id_cliente || !fecha || !hora_inicio || !hora_fin || !salones?.length) {
      res.status(400).json({ error: 'Falta id_cliente, fecha, hora_inicio, hora_fin o salones' });
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
    res.status(500).json({ error: (err as Error).message });
  }
});

// PUT /api/eventos/:id
router.put('/:id', async (req, res) => {
  try {
    const {
      id_tipo_evento, fecha, hora_inicio, hora_fin,
      total_adultos, total_menores, notas, reserva_temporal, salones,
    } = req.body;

    if (!fecha || !hora_inicio || !hora_fin || !salones?.length) {
      res.status(400).json({ error: 'Falta fecha, hora_inicio, hora_fin o salones' });
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
    res.status(500).json({ error: (err as Error).message });
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
    res.status(500).json({ error: (err as Error).message });
  }
});

// GET /api/eventos/:id/cotizaciones - historial de versiones
router.get('/:id/cotizaciones', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_cotizaciones_evento($1::integer)', [req.params.id]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// GET /api/eventos/:id/pagos
router.get('/:id/pagos', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_pagos_evento($1::integer)', [req.params.id]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
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
    res.status(500).json({ error: (err as Error).message });
  }
});
// GET /api/eventos/:id/degustaciones
router.get('/:id/degustaciones', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_degustaciones_evento($1::integer)', [req.params.id]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

export default router;