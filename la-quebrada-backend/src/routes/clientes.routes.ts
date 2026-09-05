import { Router } from 'express';
import { pool } from '../db/pool.js';

const router = Router();

// GET /api/clientes?q=texto - lista o busca clientes
router.get('/', async (req, res) => {
  try {
    const { q } = req.query;
    const result = q
      ? await pool.query('SELECT * FROM fn_buscar_cliente($1)', [q])
      : await pool.query('SELECT * FROM fn_listar_clientes()');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// GET /api/clientes/:id - un cliente puntual
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_cliente_detalle($1::integer)', [req.params.id]);
    const cliente = result.rows[0];
    if (!cliente) {
      res.status(404).json({ error: 'Cliente no encontrado' });
      return;
    }
    res.json(cliente);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// POST /api/clientes - crear cliente
router.post('/', async (req, res) => {
  try {
    const {
      primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
      cui, nit, telefono, correo,
    } = req.body;

    if (!primer_nombre || !primer_apellido) {
      res.status(400).json({ error: 'Falta primer_nombre o primer_apellido' });
      return;
    }

    const result = await pool.query(
      `CALL sp_crear_cliente(
        $1::varchar, $2::varchar, $3::varchar, $4::varchar,
        $5::varchar, $6::varchar, $7::varchar, $8::varchar, NULL
      )`,
      [
        primer_nombre, segundo_nombre ?? null, primer_apellido, segundo_apellido ?? null,
        cui ?? null, nit ?? null, telefono ?? null, correo ?? null,
      ]
    );

    res.status(201).json({ id_cliente: result.rows[0].p_id_cliente });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// PUT /api/clientes/:id - editar cliente
router.put('/:id', async (req, res) => {
  try {
    const {
      primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
      cui, nit, telefono, correo,
    } = req.body;

    if (!primer_nombre || !primer_apellido) {
      res.status(400).json({ error: 'Falta primer_nombre o primer_apellido' });
      return;
    }

    await pool.query(
      `CALL sp_editar_cliente(
        $1::integer, $2::varchar, $3::varchar, $4::varchar, $5::varchar,
        $6::varchar, $7::varchar, $8::varchar, $9::varchar
      )`,
      [
        req.params.id, primer_nombre, segundo_nombre ?? null, primer_apellido, segundo_apellido ?? null,
        cui ?? null, nit ?? null, telefono ?? null, correo ?? null,
      ]
    );

    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});
// GET /api/clientes/:id/pagos
router.get('/:id/pagos', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_pagos_cliente($1::integer)', [req.params.id]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});
export default router;