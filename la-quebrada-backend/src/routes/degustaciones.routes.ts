import { Router } from 'express';
import { pool } from '../db/pool.js';
import { exigirAlcance, filtrarDegustacionesPorAlcance, filtrarPorAlcance, guardiaAlcance } from '../middleware/alcance.js';
import { responderError } from '../utils/errores.js';
import { htmlAPdf } from '../utils/pdf.js';
import { logoDataUri, logoDeUsuario } from '../utils/logo.js';
import { armarHtmlDegustaciones, agruparSesionesDegustacion } from '../templates/reports/reporte-degustacion.template.js';

const router = Router();

// /:id es una degustación (de un evento); /fechas/:id es una fecha de degustación (compartida, sin área)
router.param('id', guardiaAlcance((req) => (req.path.startsWith('/fechas/') ? null : 'degustacion')));
router.param('idLinea', guardiaAlcance('degustacion_menu'));

// GET /api/degustaciones/fechas
router.get('/fechas', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_fechas_degustacion()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/degustaciones/fechas
router.post('/fechas', async (req, res) => {
  try {
    const { fecha, hora_inicio, hora_fin } = req.body;
    if (!fecha || !hora_inicio) {
      res.status(400).json({ error: 'Falta fecha u hora_inicio' });
      return;
    }
    const result = await pool.query(
      'CALL sp_crear_fecha_degustacion($1::date, $2::time, $3::time, NULL)',
      [fecha, hora_inicio, hora_fin ?? null]
    );
    res.status(201).json({ id_fecha_degustacion: result.rows[0].p_id_fecha_degustacion });
  } catch (err) {
    responderError(res, err);
  }
});

// PATCH /api/degustaciones/fechas/:id/estado
router.patch('/fechas/:id/estado', async (req, res) => {
  try {
    const { estado } = req.body;
    if (!estado) {
      res.status(400).json({ error: 'Falta estado' });
      return;
    }
    await pool.query('CALL sp_cambiar_estado_fecha_degustacion($1::integer, $2::varchar)', [req.params.id, estado]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

// PATCH /api/degustaciones/:id/resultado
router.patch('/:id/resultado', async (req, res) => {
  try {
    const { resultado, motivo_rechazo } = req.body;
    if (!resultado) {
      res.status(400).json({ error: 'Falta resultado' });
      return;
    }
    await pool.query('CALL sp_resolver_degustacion($1::integer, $2::varchar, $3::text)', [req.params.id, resultado, motivo_rechazo ?? null]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/degustaciones/:id
router.get('/:id', async (req, res) => {
  try {
    const [detalle, menus] = await Promise.all([
      pool.query('SELECT * FROM fn_degustacion_detalle($1::integer)', [req.params.id]),
      pool.query('SELECT * FROM fn_listar_menus_degustacion($1::integer)', [req.params.id]),
    ]);
    const degustacion = detalle.rows[0];
    if (!degustacion) {
      res.status(404).json({ error: 'Degustación no encontrada' });
      return;
    }
    res.json({ ...degustacion, menus: menus.rows });
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/degustaciones
router.post('/', async (req, res) => {
  try {
    const { id_evento, id_fecha_degustacion, hora_llegada, notas } = req.body;
    if (!id_evento || !id_fecha_degustacion) {
      res.status(400).json({ error: 'Falta id_evento o id_fecha_degustacion' });
      return;
    }
    if (!(await exigirAlcance(req, res, 'evento', id_evento))) return;
    const result = await pool.query(
      'CALL sp_agendar_degustacion($1::integer, $2::integer, $3::time, $4::text, NULL)',
      [id_evento, id_fecha_degustacion, hora_llegada ?? null, notas ?? null]
    );
    res.status(201).json({ id_degustacion: result.rows[0].p_id_degustacion });
  } catch (err) {
    responderError(res, err);
  }
});

// PATCH /api/degustaciones/:id/estado
router.patch('/:id/estado', async (req, res) => {
  try {
    const { estado } = req.body;
    if (!estado) {
      res.status(400).json({ error: 'Falta estado' });
      return;
    }
    await pool.query('CALL sp_cambiar_estado_degustacion($1::integer, $2::varchar)', [req.params.id, estado]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/degustaciones/:id/menu
router.post('/:id/menu', async (req, res) => {
  try {
    const { id_menu } = req.body;
    if (!id_menu) {
      res.status(400).json({ error: 'Falta id_menu' });
      return;
    }
    const result = await pool.query('CALL sp_agregar_menu_degustacion($1::integer, $2::integer, NULL)', [req.params.id, id_menu]);
    res.status(201).json({ id_degustacion_menu: result.rows[0].p_id_degustacion_menu });
  } catch (err) {
    responderError(res, err);
  }
});

// PATCH /api/degustaciones/menu/:idLinea
router.patch('/menu/:idLinea', async (req, res) => {
  try {
    const { resultado, notas } = req.body;
    if (!resultado) {
      res.status(400).json({ error: 'Falta resultado' });
      return;
    }
    await pool.query('CALL sp_resolver_menu_degustacion($1::integer, $2::varchar, $3::text)', [req.params.idLinea, resultado, notas ?? null]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});
// GET /api/degustaciones/fechas/:id/pdf
// Reporte de degustación (mismo template que Reportes) solo para esta sesión.
// Vive acá y no en /reportes porque quien maneja las fechas (Secretaria) no tiene acceso a Reportes.
router.get('/fechas/:id/pdf', async (req, res) => {
  try {
    const idFecha = Number(req.params.id);
    if (!Number.isInteger(idFecha) || idFecha <= 0) {
      res.status(400).json({ error: 'Fecha de degustación inválida' });
      return;
    }

    const sesion = await pool.query(
      `SELECT to_char(fecha, 'YYYY-MM-DD') AS fecha, hora_inicio FROM fechas_degustacion WHERE id_fecha_degustacion = $1`,
      [idFecha]
    );
    if (!sesion.rows[0]) {
      res.status(404).json({ error: 'Fecha de degustación no encontrada' });
      return;
    }
    const { fecha, hora_inicio } = sesion.rows[0];

    // El reporte trae todo el día: se deja solo la sesión de esta hora
    const result = await pool.query('SELECT * FROM fn_reporte_degustaciones_detallado($1::date, $1::date)', [fecha]);
    // Solo los agendados de eventos del área del usuario
    const filas = await filtrarDegustacionesPorAlcance(req, result.rows.filter((r) => r.hora_inicio === hora_inicio));

    const fechaLarga = new Date(`${fecha}T00:00:00`).toLocaleDateString('es-GT', { day: 'numeric', month: 'long', year: 'numeric' });
    const html = armarHtmlDegustaciones({
      logoUrl: logoDataUri(await logoDeUsuario((req as any).usuario.id_usuario)),
      subtitulo: `${fechaLarga}, ${String(hora_inicio).substring(0, 5)}`,
      sesiones: agruparSesionesDegustacion(filas),
    });

    const pdf = await htmlAPdf(html, { format: 'Letter', printBackground: true, margin: { top: '20px', bottom: '20px' } });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="degustacion-${fecha}.pdf"`);
    res.send(pdf);
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/degustaciones/fechas/:id/agendados
router.get('/fechas/:id/agendados', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_degustaciones_por_fecha($1::integer)', [req.params.id]);
    res.json(await filtrarPorAlcance(req, result.rows));
  } catch (err) {
    responderError(res, err);
  }
});
// PATCH /api/degustaciones/menu/:idLinea/quitar
router.patch('/menu/:idLinea/quitar', async (req, res) => {
  try {
    await pool.query('CALL sp_quitar_menu_degustacion($1::integer)', [req.params.idLinea]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

export default router;