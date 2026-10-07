import { Router } from 'express';
import type { Response } from 'express';
import { pool } from '../db/pool.js';
import { responderError } from '../utils/errores.js';

const router = Router();

const esEnteroPositivo = (v: unknown) => Number.isInteger(v) && (v as number) > 0;

/** Entero positivo opcional de la query string (o null). */
function enteroQuery(valor: unknown): number | null | 'invalido' {
  if (valor === undefined || valor === '') return null;
  const n = Number(valor);
  return esEnteroPositivo(n) ? n : 'invalido';
}

/**
 * Áreas de disponibilidad del body. Ambos vacíos = el menú se ofrece en todos lados.
 * Devuelve null (y responde 400) si vienen mal formadas.
 */
function leerAreas(body: any, res: Response): { locaciones: number[]; salones: number[] } | null {
  const locaciones = body.locaciones ?? [];
  const salones = body.salones ?? [];
  if (!Array.isArray(locaciones) || !Array.isArray(salones) || ![...locaciones, ...salones].every(esEnteroPositivo)) {
    res.status(400).json({ error: 'Las áreas de disponibilidad no son válidas' });
    return null;
  }
  return { locaciones: [...new Set(locaciones as number[])], salones: [...new Set(salones as number[])] };
}

// GET /api/menus?id_tipo_menu=&id_evento=&id_locacion=&id_salon=&sin_restriccion=true
// - id_evento: solo los menús activos que se pueden usar en ese evento (según sus salones)
// - id_locacion / id_salon: catálogo, disponibles en esa área (incluye los de "todos lados")
// - sin_restriccion: catálogo, solo los de "todos lados"
router.get('/', async (req, res) => {
  try {
    const filtros = ['id_tipo_menu', 'id_evento', 'id_locacion', 'id_salon'].map((k) => enteroQuery(req.query[k]));
    if (filtros.includes('invalido')) {
      res.status(400).json({ error: 'Filtro inválido' });
      return;
    }
    const sinRestriccion = req.query.sin_restriccion === 'true';
    const result = await pool.query(
      'SELECT * FROM fn_listar_menus($1::integer, $2::integer, $3::integer, $4::integer, $5::boolean)',
      [...filtros, sinRestriccion]
    );
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_menu_detalle($1::integer)', [req.params.id]);
    const menu = result.rows[0];
    if (!menu) {
      res.status(404).json({ error: 'Menú no encontrado' });
      return;
    }
    res.json(menu);
  } catch (err) {
    responderError(res, err);
  }
});

router.post('/', async (req, res) => {
  try {
    const { nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, componentes } = req.body;
    if (!nombre || !id_tipo_menu || precio_base == null || !unidad_medida) {
      res.status(400).json({ error: 'Falta nombre, id_tipo_menu, precio_base o unidad_medida' });
      return;
    }
    const areas = leerAreas(req.body, res);
    if (!areas) return;
    const result = await pool.query(
      `CALL sp_crear_menu($1::varchar, $2::integer, $3::decimal, $4::varchar, $5::text, $6::integer[], $7::integer[], $8::integer[], NULL)`,
      [nombre, id_tipo_menu, precio_base, unidad_medida, descripcion ?? null, componentes ?? [], areas.locaciones, areas.salones]
    );
    res.status(201).json({ id_menu: result.rows[0].p_id_menu });
  } catch (err) {
    responderError(res, err);
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, activo, componentes } = req.body;
    if (!nombre || !id_tipo_menu || precio_base == null || !unidad_medida) {
      res.status(400).json({ error: 'Falta nombre, id_tipo_menu, precio_base o unidad_medida' });
      return;
    }
    const areas = leerAreas(req.body, res);
    if (!areas) return;
    await pool.query(
      `CALL sp_editar_menu($1::integer, $2::varchar, $3::integer, $4::decimal, $5::varchar, $6::text, $7::boolean, $8::integer[], $9::integer[], $10::integer[])`,
      [req.params.id, nombre, id_tipo_menu, precio_base, unidad_medida, descripcion ?? null, activo ?? true, componentes ?? [], areas.locaciones, areas.salones]
    );
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/menus/:id/duplicar - misma receta con otro precio y/o área (nombre y precio opcionales)
router.post('/:id/duplicar', async (req, res) => {
  try {
    const { nombre, precio_base } = req.body;
    if (precio_base != null && !(Number(precio_base) > 0)) {
      res.status(400).json({ error: 'El precio debe ser mayor a 0' });
      return;
    }
    const areas = leerAreas(req.body, res);
    if (!areas) return;
    const result = await pool.query(
      `CALL sp_duplicar_menu($1::integer, $2::varchar, $3::numeric, $4::integer[], $5::integer[], NULL)`,
      [req.params.id, typeof nombre === 'string' ? nombre.trim() || null : null, precio_base ?? null, areas.locaciones, areas.salones]
    );
    res.status(201).json({ id_menu: result.rows[0].p_id_menu_nuevo });
  } catch (err) {
    responderError(res, err);
  }
});

export default router;
