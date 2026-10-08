import { Router } from 'express';
import { pool } from '../db/pool.js';
import { htmlAPdf } from '../utils/pdf.js';
import { armarHtmlCotizacion } from '../templates/reports/cotizacion.template.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import type { AuthRequest } from '../middleware/auth.middleware.js';
import { exigirAlcance, filtrarPorAlcance, guardiaAlcance } from '../middleware/alcance.js';
import { logoDeEvento } from '../utils/logo.js';
import { responderError } from '../utils/errores.js';
import bcrypt from 'bcryptjs';
import { crearLimitador } from '../middleware/limitador.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const router = Router();

// Alcance por área (404 si la cotización / línea / descuento no es de un evento de su área)
router.param('id', guardiaAlcance('cotizacion'));
router.param('idLinea', guardiaAlcance((req) => (req.path.startsWith('/menu/') ? 'cotizacion_menu' : 'cotizacion_servicios')));
router.param('idDescuento', guardiaAlcance('descuento'));

// GET /api/cotizaciones/por-vencer?dias=3
router.get('/por-vencer', async (req, res) => {
  try {
    const dias = req.query.dias ? Number(req.query.dias) : 3;
    const result = await pool.query('SELECT * FROM fn_cotizaciones_proximas_vencer($1::integer)', [dias]);
    res.json(await filtrarPorAlcance(req, result.rows));
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/cotizaciones/:id - detalle completo (header + líneas)
router.get('/:id', async (req, res) => {
  try {
    const [detalle, menus, servicios, paquetes] = await Promise.all([
      pool.query('SELECT * FROM fn_cotizacion_detalle($1::integer)', [req.params.id]),
      pool.query('SELECT * FROM fn_cotizacion_menu_detalle($1::integer)', [req.params.id]),
      pool.query('SELECT * FROM fn_cotizacion_servicios_detalle($1::integer)', [req.params.id]),
      pool.query('SELECT * FROM fn_cotizacion_paquete($1::integer)', [req.params.id]),
    ]);

    const cotizacion = detalle.rows[0];
    if (!cotizacion) {
      res.status(404).json({ error: 'Cotización no encontrada' });
      return;
    }

    res.json({ ...cotizacion, menus: menus.rows, servicios: servicios.rows, paquetes: paquetes.rows });
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/cotizaciones - crear nueva versión
// POST /api/cotizaciones
// Intentos de autorización de administrador (usuario + contraseña) al aplicar paquetes bajo el mínimo
const limiteAutorizacion = crearLimitador({
  ventanaMs: 15 * 60 * 1000,
  max: 10,
  mensaje: 'Demasiados intentos de autorización. Esperá unos minutos e intentá de nuevo.',
  clave: (req) => `${req.ip}|${String(req.body?.autorizacion?.username ?? '').trim().toLowerCase()}`,
});

const ROLES_AUTORIZAN = ['Administrador', 'Superusuario'];
const esEnteroPositivo = (v: unknown) => Number.isInteger(v) && (v as number) > 0;

// POST /api/cotizaciones/paquete - aplica un paquete: crea una nueva versión con las líneas ya llenas
// body: { id_evento, id_paquete, menus: [ids], componentes: [ids], cortesias: [ids],
//         extras: [{ id_servicio, cantidad }], cantidad?, deposito_garantia?,
//         autorizacion?: { username, password } }   ← solo si la cantidad es menor al mínimo
router.post('/paquete', limiteAutorizacion.middleware, async (req: AuthRequest, res) => {
  try {
    const { id_evento, id_paquete, menus, componentes, cortesias, extras, cantidad, deposito_garantia, autorizacion } = req.body;
    if (!esEnteroPositivo(Number(id_evento)) || !esEnteroPositivo(Number(id_paquete))) {
      res.status(400).json({ error: 'Falta el evento o el paquete' });
      return;
    }
    if (!(await exigirAlcance(req, res, 'evento', id_evento))) return;
    const listaValida = (v: unknown) => Array.isArray(v) && v.every(esEnteroPositivo);
    if (!listaValida(menus ?? []) || !listaValida(componentes ?? []) || !listaValida(cortesias ?? [])) {
      res.status(400).json({ error: 'Las opciones elegidas no son válidas' });
      return;
    }
    const extrasLista: any[] = extras ?? [];
    if (!Array.isArray(extrasLista) || !extrasLista.every((e) => esEnteroPositivo(e?.id_servicio) && esEnteroPositivo(Number(e?.cantidad)))) {
      res.status(400).json({ error: 'Los extras elegidos no son válidos' });
      return;
    }
    if (cantidad != null && !esEnteroPositivo(Number(cantidad))) {
      res.status(400).json({ error: 'La cantidad debe ser un número entero mayor a 0' });
      return;
    }

    // Quién autoriza (solo se usa si la cantidad queda bajo el mínimo; el SP lo vuelve a validar):
    // un Administrador/Superusuario con sesión se autoriza a sí mismo; si no, usuario y contraseña de uno.
    let idAutoriza: number | null = null;
    if (ROLES_AUTORIZAN.includes(req.usuario!.rol_acceso ?? '')) {
      idAutoriza = req.usuario!.id_usuario;
    } else if (autorizacion?.username && autorizacion?.password) {
      const busqueda = await pool.query('SELECT * FROM fn_buscar_usuario_login($1)', [String(autorizacion.username).trim().toLowerCase()]);
      const admin = busqueda.rows[0];
      const valido =
        admin && admin.activo && admin.confirmacion && ROLES_AUTORIZAN.includes(admin.rol_acceso) &&
        (await bcrypt.compare(String(autorizacion.password), admin.password_hash));
      if (!valido) {
        res.status(403).json({ error: 'El usuario o la contraseña del administrador no son correctos' });
        return;
      }
      // Un administrador solo autoriza eventos de su área (un admin de GADZI no autoriza en La Quebrada)
      const enSuArea = await pool.query(
        'SELECT fn_evento_en_alcance($1::integer, fn_salones_usuario($2::integer)) AS ok',
        [Number(id_evento), admin.id_usuario]
      );
      if (!enSuArea.rows[0]?.ok) {
        res.status(403).json({ error: 'Ese administrador no tiene este evento en su área; tiene que autorizarlo uno de esta locación.' });
        return;
      }
      idAutoriza = admin.id_usuario;
    }

    const empleado = await pool.query('SELECT fn_id_empleado_por_persona($1::integer) AS id_empleado', [req.usuario!.id_persona]);
    const result = await pool.query(
      `CALL sp_aplicar_paquete($1::integer, $2::integer, $3::integer[], $4::integer[], $5::integer[], $6::jsonb,
                               $7::integer, $8::numeric, $9::integer, $10::integer, NULL)`,
      [
        Number(id_evento), Number(id_paquete), [...new Set(menus ?? [])], [...new Set(componentes ?? [])], [...new Set(cortesias ?? [])],
        JSON.stringify(extrasLista.map((e) => ({ id_servicio: e.id_servicio, cantidad: Number(e.cantidad) }))),
        cantidad ?? null, Number(deposito_garantia ?? 0), empleado.rows[0]?.id_empleado ?? null, idAutoriza,
      ]
    );
    limiteAutorizacion.reiniciar(req);
    res.status(201).json({ id_cotizacion: result.rows[0].p_id_cotizacion });
  } catch (err) {
    responderError(res, err);
  }
});

router.post('/', async (req: AuthRequest, res) => {
  try {
    const { id_evento, vigencia_dias, deposito_garantia } = req.body;
    if (!id_evento) {
      res.status(400).json({ error: 'Falta id_evento' });
      return;
    }
    if (!(await exigirAlcance(req, res, 'evento', id_evento))) return;

    // Quién crea la cotización sale de la sesión, nunca del body (si no, se podría falsificar)
    const empleadoResult = await pool.query('SELECT fn_id_empleado_por_persona($1::integer) AS id_empleado', [req.usuario!.id_persona]);
    const idEmpleado = empleadoResult.rows[0]?.id_empleado ?? null;

    const result = await pool.query(
      'CALL sp_crear_cotizacion($1::integer, $2::integer, $3::decimal, $4::integer, NULL)',
      [id_evento, vigencia_dias ?? 8, deposito_garantia ?? 0, idEmpleado]
    );
    res.status(201).json({ id_cotizacion: result.rows[0].p_id_cotizacion });
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/cotizaciones/:id/menu
router.post('/:id/menu', async (req, res) => {
  try {
    const { id_menu, cantidad } = req.body;
    if (!id_menu) {
      res.status(400).json({ error: 'Falta id_menu' });
      return;
    }
    const result = await pool.query(
      'CALL sp_agregar_menu_cotizacion($1::integer, $2::integer, $3::integer, NULL)',
      [req.params.id, id_menu, cantidad ?? null]
    );
    res.status(201).json({ id_cotizacion_menu: result.rows[0].p_id_cotizacion_menu });
  } catch (err) {
    responderError(res, err);
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
    responderError(res, err);
  }
});

// DELETE /api/cotizaciones/menu/:idLinea
router.delete('/menu/:idLinea', async (req, res) => {
  try {
    await pool.query('CALL sp_quitar_menu_cotizacion($1::integer)', [req.params.idLinea]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

// DELETE /api/cotizaciones/servicios/:idLinea
router.delete('/servicios/:idLinea', async (req, res) => {
  try {
    await pool.query('CALL sp_quitar_servicio_cotizacion($1::integer)', [req.params.idLinea]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
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
    responderError(res, err);
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
    responderError(res, err);
  }
});
// GET /api/cotizaciones/servicios/:idLinea/descuentos
router.get('/servicios/:idLinea/descuentos', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_descuentos_servicio($1::integer)', [req.params.idLinea]);
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
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
    responderError(res, err);
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
    responderError(res, err);
  }
});


// GET /api/cotizaciones/:id/pdf
// GET /api/cotizaciones/:id/pdf
router.get('/:id/pdf', async (req, res) => {
  try {
    const [detalleRes, menusRes, serviciosRes, paquetesRes] = await Promise.all([
      pool.query('SELECT * FROM fn_cotizacion_detalle($1::integer)', [req.params.id]),
      pool.query('SELECT * FROM fn_cotizacion_menu_detalle($1::integer)', [req.params.id]),
      pool.query('SELECT * FROM fn_cotizacion_servicios_detalle($1::integer)', [req.params.id]),
      pool.query('SELECT * FROM fn_cotizacion_paquete($1::integer)', [req.params.id]),
    ]);

    const cot = detalleRes.rows[0];
    if (!cot) {
      res.status(404).json({ error: 'Cotización no encontrada' });
      return;
    }

    const [eventoRes, pagosRes, saldoRes, extrasRes] = await Promise.all([
      pool.query('SELECT * FROM fn_evento_detalle($1::integer)', [cot.id_evento]),
      pool.query('SELECT * FROM fn_listar_pagos_evento($1::integer)', [cot.id_evento]),
      pool.query('SELECT * FROM fn_saldo_evento($1::integer)', [cot.id_evento]),
      pool.query('SELECT * FROM fn_listar_extras_evento($1::integer)', [cot.id_evento]),
    ]);
    const evento = eventoRes.rows[0];
    const pagosVerificados = pagosRes.rows.filter((p) => p.estado === 'verificado');
    const saldo = saldoRes.rows[0];

    // Extras: solo los que cuentan para el saldo (aprobado / pagado), y solo en la versión activa
    const extrasFila = extrasRes.rows[0];
    const estadosQueCuentan = ['aprobado', 'pagado'];
    const extras = cot.activa && extrasFila
      ? [
          ...(extrasFila.servicios ?? [])
            .filter((s: any) => estadosQueCuentan.includes(s.estado))
            .map((s: any) => ({
              nombre: s.servicio ?? s.descripcion ?? 'Cargo extra',
              etiqueta: s.tipo_cargo_extra as string,
              cantidad: Number(s.cantidad),
              precio: Number(s.precio_unitario),
              subtotal: Number(s.subtotal),
            })),
          ...(extrasFila.menus ?? [])
            .filter((m: any) => estadosQueCuentan.includes(m.estado))
            .map((m: any) => ({
              nombre: m.menu ?? m.descripcion ?? 'Menú extra',
              etiqueta: 'Menú',
              cantidad: Number(m.cantidad),
              precio: Number(m.precio_base),
              subtotal: Number(m.subtotal),
            })),
        ]
      : [];
    const totalExtras = extras.reduce((acc, e) => acc + e.subtotal, 0);

    // Logo de la locación del evento (GADZI o La Quebrada)
    const logo = await logoDeEvento(cot.id_evento);

    const html = armarHtmlCotizacion({
      logoUrl: logo.dataUri,
      // Con el logo propio de la locación ya se sabe dónde es: el nombre solo hace falta con el genérico
      mostrarLocacion: !logo.archivo,
      clienteNombre: evento?.cliente ?? '—',
      clienteTelefono: evento?.telefono_cliente ?? null,
      fechaCotizacion: new Date(cot.fecha_cotizacion).toLocaleDateString('es-GT'),
      eventoTipo: evento?.tipo_evento ?? null,
      eventoFecha: evento ? new Date(evento.fecha).toLocaleDateString('es-GT') : '—',
      eventoSalones: evento?.salones ?? '—',
      eventoLocacion: evento?.locaciones ?? 'La Quebrada',
      eventoHorario: evento ? `${evento.hora_inicio.substring(0, 5)} - ${evento.hora_fin.substring(0, 5)}` : '—',
      version: cot.version,
      vigenciaDias: cot.vigencia_dias,
      vendedor: cot.vendedor,
      menus: menusRes.rows.map((m) => ({
        nombre: m.menu,
        // Línea de un paquete: lo elegido (plato, bebida...) debajo del nombre
        detalle: paquetesRes.rows.find((p) => p.id_cotizacion_menu === m.id_cotizacion_menu)?.elecciones ?? null,
        cantidad: m.cantidad,
        precio: Number(m.precio_unitario_congelado),
        subtotal: Number(m.subtotal),
        esExtraDegustacion: m.es_extra_degustacion,
      })),
      servicios: serviciosRes.rows.map((s) => ({
        nombre: s.servicio,
        cantidad: s.cantidad,
        precio: Number(s.precio_unitario_congelado),
        subtotal: Number(s.subtotal),
      })),
      extras,
      paquetes: paquetesRes.rows.map((p) => ({
        nombre: p.paquete as string,
        incluye: (p.incluye ?? []) as string[],
        horasIncluidas: p.horas_incluidas as number | null,
      })),
      subtotalMenus: Number(cot.subtotal_menus),
      subtotalServicios: Number(cot.subtotal_servicios),
      depositoGarantia: Number(cot.deposito_garantia),
      totalDescuento: Number(cot.total_descuento),
      total: Number(cot.total),
      totalExtras,
      brindis: cot.brindis,
      cantidadMesaPrincipal: cot.cantidad_mesa_principal,
      cantidadMesasReservadas: cot.cantidad_mesas_reservadas,
      colorMantel: cot.color_mantel,
      colorCubremanteles: cot.color_cubremanteles,
      boquitas: cot.boquitas,
      observaciones: cot.observaciones,
      pagos: pagosVerificados.map((p) => ({ fecha: p.fecha_pago, concepto: p.concepto, monto: Number(p.monto) })),
      saldoPendiente: saldo ? Number(saldo.saldo_pendiente) : Number(cot.total),
    });

        const pdfBuffer = await htmlAPdf(html, { format: 'Letter', printBackground: true, margin: { top: '20px', bottom: '20px' } });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="cotizacion-v${cot.version}.pdf"`);
    res.send(Buffer.from(pdfBuffer));
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/cotizaciones/:id/menu-personalizado
router.post('/:id/menu-personalizado', async (req, res) => {
  try {
    const { nombre, id_tipo_menu, precio, descripcion, componentes, cantidad, id_menu_base } = req.body;
    const nombreLimpio = typeof nombre === 'string' ? nombre.trim() : '';
    const precioNum = Number(precio);
    const esEnteroPositivo = (v: unknown) => Number.isInteger(v) && (v as number) > 0;

    if (!nombreLimpio || !esEnteroPositivo(Number(id_tipo_menu))) {
      res.status(400).json({ error: 'Falta el nombre o el tipo de menú' });
      return;
    }
    if (nombreLimpio.length > 150) {
      res.status(400).json({ error: 'El nombre no puede pasar de 150 caracteres' });
      return;
    }
    if (!Number.isFinite(precioNum) || precioNum <= 0) {
      res.status(400).json({ error: 'El precio base debe ser mayor a 0' });
      return;
    }
    if (!Array.isArray(componentes) || componentes.length === 0 || !componentes.every(esEnteroPositivo)) {
      res.status(400).json({ error: 'Elegí al menos un componente válido' });
      return;
    }
    if (id_menu_base != null && !esEnteroPositivo(Number(id_menu_base))) {
      res.status(400).json({ error: 'Menú base inválido' });
      return;
    }
    const componentesUnicos = [...new Set(componentes as number[])];

    // precio = precio base por plato SIN recargos: el SP suma el recargo de cada componente
    // elegido que no venía en el menú base (sin menú base, todos)

    const result = await pool.query(
      'CALL sp_crear_menu_personalizado($1::integer, $2::varchar, $3::integer, $4::numeric, $5::text, $6::integer[], $7::integer, $8::integer, NULL, NULL)',
      [req.params.id, nombreLimpio, Number(id_tipo_menu), precioNum, descripcion ?? null, componentesUnicos, cantidad ?? null, id_menu_base ?? null]
    );
    res.status(201).json({ id_menu: result.rows[0].p_id_menu, id_cotizacion_menu: result.rows[0].p_id_cotizacion_menu });
  } catch (err) {
    responderError(res, err);
  }
});
// PATCH /api/cotizaciones/menu/:idLinea/cantidad
router.patch('/menu/:idLinea/cantidad', async (req, res) => {
  try {
    const { cantidad } = req.body;
    if (!cantidad) {
      res.status(400).json({ error: 'Falta cantidad' });
      return;
    }
    await pool.query('CALL sp_editar_cantidad_menu_cotizacion($1::integer, $2::integer)', [req.params.idLinea, cantidad]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});
export default router;