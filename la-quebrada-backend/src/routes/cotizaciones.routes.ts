import { Router } from 'express';
import { pool } from '../db/pool.js';

const router = Router();

// GET /api/cotizaciones/:id - detalle completo (header + líneas)
router.get('/:id', async (req, res) => {
  try {
    const [detalle, menus, servicios] = await Promise.all([
      pool.query('SELECT * FROM fn_cotizacion_detalle($1::integer)', [req.params.id]),
      pool.query('SELECT * FROM fn_cotizacion_menu_detalle($1::integer)', [req.params.id]),
      pool.query('SELECT * FROM fn_cotizacion_servicios_detalle($1::integer)', [req.params.id]),
    ]);

    const cotizacion = detalle.rows[0];
    if (!cotizacion) {
      res.status(404).json({ error: 'Cotización no encontrada' });
      return;
    }

    res.json({ ...cotizacion, menus: menus.rows, servicios: servicios.rows });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// POST /api/cotizaciones - crear nueva versión
router.post('/', async (req, res) => {
  try {
    const { id_evento, vigencia_dias, deposito_garantia, id_empleado } = req.body;
    if (!id_evento) {
      res.status(400).json({ error: 'Falta id_evento' });
      return;
    }
    const result = await pool.query(
      'CALL sp_crear_cotizacion($1::integer, $2::integer, $3::decimal, $4::integer, NULL)',
      [id_evento, vigencia_dias ?? 8, deposito_garantia ?? 0, id_empleado ?? null]
    );
    res.status(201).json({ id_cotizacion: result.rows[0].p_id_cotizacion });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// POST /api/cotizaciones/:id/menu - agregar línea de menú
router.post('/:id/menu', async (req, res) => {
  try {
    const { id_menu } = req.body;
    if (!id_menu) {
      res.status(400).json({ error: 'Falta id_menu' });
      return;
    }
    const result = await pool.query('CALL sp_agregar_menu_cotizacion($1::integer, $2::integer, NULL)', [req.params.id, id_menu]);
    res.status(201).json({ id_cotizacion_menu: result.rows[0].p_id_cotizacion_menu });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// POST /api/cotizaciones/:id/servicios - agregar línea de servicio
router.post('/:id/servicios', async (req, res) => {
  try {
    const { id_servicio, cantidad } = req.body;
    if (!id_servicio) {
      res.status(400).json({ error: 'Falta id_servicio' });
      return;
    }
    const result = await pool.query(
      'CALL sp_agregar_servicio_cotizacion($1::integer, $2::integer, $3::integer, NULL)',
      [req.params.id, id_servicio, cantidad ?? 1]
    );
    res.status(201).json({ id_cotizacion_servicios: result.rows[0].p_id_cotizacion_servicios });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// DELETE /api/cotizaciones/menu/:idLinea
router.delete('/menu/:idLinea', async (req, res) => {
  try {
    await pool.query('CALL sp_quitar_menu_cotizacion($1::integer)', [req.params.idLinea]);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// DELETE /api/cotizaciones/servicios/:idLinea
router.delete('/servicios/:idLinea', async (req, res) => {
  try {
    await pool.query('CALL sp_quitar_servicio_cotizacion($1::integer)', [req.params.idLinea]);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// PATCH /api/cotizaciones/:id/estado
router.patch('/:id/estado', async (req, res) => {
  try {
    const { estado } = req.body;
    if (!estado) {
      res.status(400).json({ error: 'Falta estado' });
      return;
    }
    await pool.query('CALL sp_cambiar_estado_cotizacion($1::integer, $2::varchar)', [req.params.id, estado]);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});
// PUT /api/cotizaciones/:id - editar detalles (no toca totales)
router.put('/:id', async (req, res) => {
  try {
    const {
      brindis, cantidad_mesa_principal, cantidad_mesas_reservadas,
      id_color_mantel, id_color_cubremanteles, observaciones, boquitas,
    } = req.body;
    await pool.query(
      `CALL sp_editar_cotizacion($1::integer, $2::boolean, $3::integer, $4::integer, $5::integer, $6::integer, $7::text, $8::text)`,
      [
        req.params.id, brindis ?? false, cantidad_mesa_principal ?? null, cantidad_mesas_reservadas ?? null,
        id_color_mantel ?? null, id_color_cubremanteles ?? null, observaciones ?? null, boquitas ?? null,
      ]
    );
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});
// GET /api/cotizaciones/servicios/:idLinea/descuentos
router.get('/servicios/:idLinea/descuentos', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_descuentos_servicio($1::integer)', [req.params.idLinea]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// POST /api/cotizaciones/servicios/:idLinea/descuentos
router.post('/servicios/:idLinea/descuentos', async (req, res) => {
  try {
    const { id_tipo_descuento, porcentaje, monto_descontado, motivo, id_empleado } = req.body;
    if (!id_tipo_descuento) {
      res.status(400).json({ error: 'Falta id_tipo_descuento' });
      return;
    }
    const result = await pool.query(
      `CALL sp_crear_descuento_servicio($1::integer, $2::integer, $3::decimal, $4::decimal, $5::text, $6::integer, NULL)`,
      [req.params.idLinea, id_tipo_descuento, porcentaje ?? null, monto_descontado ?? null, motivo ?? null, id_empleado ?? null]
    );
    res.status(201).json({ id_descuento: result.rows[0].p_id_descuento });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// PATCH /api/cotizaciones/descuentos/:idDescuento
router.patch('/descuentos/:idDescuento', async (req, res) => {
  try {
    const { estado, id_empleado } = req.body;
    if (!estado) {
      res.status(400).json({ error: 'Falta estado' });
      return;
    }
    await pool.query('CALL sp_resolver_descuento_servicio($1::integer, $2::varchar, $3::integer)', [req.params.idDescuento, estado, id_empleado ?? null]);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});
export default router;