import { Router } from 'express';
import type { Response } from 'express';
import { pool } from '../db/pool.js';
import { responderError } from '../utils/errores.js';

const router = Router();

const esEnteroPositivo = (v: unknown) => Number.isInteger(v) && (v as number) > 0;

const TIPOS_GRUPO = ['menu', 'componente', 'cortesia'];
const CALCULOS_EXTRA = ['fijo', 'por_persona', 'hora_extra'];

interface GrupoBody {
  tipo: 'menu' | 'componente' | 'cortesia';
  nombre: string;
  cantidad_a_elegir: number;
  opciones: number[];
}

/** Valida la forma del paquete (la base de datos valida además que las opciones existan). Responde 400 si algo falla. */
function leerPaquete(body: any, res: Response) {
  const nombre = typeof body.nombre === 'string' ? body.nombre.trim() : '';
  const precio = Number(body.precio_por_persona);
  const minimo = Number(body.minimo_personas);
  const idTipoMenu = Number(body.id_tipo_menu);
  const horas = body.horas_incluidas == null || body.horas_incluidas === '' ? null : Number(body.horas_incluidas);
  const grupos: GrupoBody[] = Array.isArray(body.grupos) ? body.grupos : [];
  const incluidos: any[] = Array.isArray(body.incluidos) ? body.incluidos : [];
  const extras: any[] = Array.isArray(body.extras) ? body.extras : [];
  const locaciones = Array.isArray(body.locaciones) ? body.locaciones : [];
  const salones = Array.isArray(body.salones) ? body.salones : [];

  const error = (msg: string) => {
    res.status(400).json({ error: msg });
    return null;
  };
  if (!nombre || nombre.length > 150) return error('El nombre es obligatorio (máximo 150 caracteres)');
  if (!Number.isFinite(precio) || precio <= 0) return error('El precio por persona debe ser mayor a 0');
  if (!esEnteroPositivo(minimo)) return error('El mínimo de personas debe ser un número entero mayor a 0');
  if (horas !== null && !esEnteroPositivo(horas)) return error('Las horas incluidas deben ser un número entero mayor a 0');
  if (!esEnteroPositivo(idTipoMenu)) return error('Elegí el tipo de menú');
  for (const g of grupos) {
    if (!TIPOS_GRUPO.includes(g?.tipo) || typeof g.nombre !== 'string' || !g.nombre.trim()) {
      return error('Cada grupo necesita tipo y nombre');
    }
    if (!Array.isArray(g.opciones) || !g.opciones.length || !g.opciones.every(esEnteroPositivo)) {
      return error(`El grupo "${g.nombre}" necesita al menos una opción válida`);
    }
    if (!esEnteroPositivo(Number(g.cantidad_a_elegir ?? 1))) return error(`Cantidad a elegir inválida en "${g.nombre}"`);
  }
  // Cada "incluye" es un servicio (con cantidad fija o "por cada N personas") o un texto
  for (const i of incluidos) {
    const texto = typeof i?.texto === 'string' ? i.texto.trim() : '';
    const conServicio = i?.id_servicio != null;
    if (conServicio === !!texto) return error('Cada "incluye" debe ser un servicio o un texto');
    if (texto.length > 250) return error('Un texto de "incluye" es muy largo (máximo 250 caracteres)');
    if (conServicio && (!esEnteroPositivo(i.id_servicio) || !esEnteroPositivo(Number(i.cantidad ?? 1)))) {
      return error('Los servicios incluidos no son válidos');
    }
    if (i.por_cada_personas != null && !esEnteroPositivo(Number(i.por_cada_personas))) {
      return error('"Por cada N personas" debe ser un número entero mayor a 0');
    }
  }
  for (const e of extras) {
    if (!esEnteroPositivo(e?.id_servicio) || !(Number(e.precio) >= 0) || !CALCULOS_EXTRA.includes(e.calculo ?? 'fijo')) {
      return error('Los extras no son válidos (servicio, precio y cálculo)');
    }
  }
  if (![...locaciones, ...salones].every(esEnteroPositivo)) return error('Las áreas de disponibilidad no son válidas');

  return {
    nombre,
    descripcion: typeof body.descripcion === 'string' ? body.descripcion : null,
    precio,
    minimo,
    horas,
    idTipoMenu,
    activo: body.activo ?? true,
    grupos: grupos.map((g) => ({ tipo: g.tipo, nombre: g.nombre.trim(), cantidad_a_elegir: Number(g.cantidad_a_elegir ?? 1), opciones: g.opciones })),
    incluidos: incluidos.map((i) =>
      i.id_servicio != null
        ? { id_servicio: i.id_servicio, cantidad: Number(i.cantidad ?? 1), por_cada_personas: i.por_cada_personas != null ? Number(i.por_cada_personas) : null }
        : { texto: String(i.texto).trim() }
    ),
    extras: extras.map((e) => ({ id_servicio: e.id_servicio, precio: Number(e.precio), calculo: e.calculo ?? 'fijo' })),
    locaciones,
    salones,
  };
}

// GET /api/paquetes?id_evento=  (con id_evento: solo los activos que se pueden usar en ese evento)
router.get('/', async (req, res) => {
  try {
    const idEvento = req.query.id_evento ? Number(req.query.id_evento) : null;
    if (idEvento !== null && !esEnteroPositivo(idEvento)) {
      res.status(400).json({ error: 'Evento inválido' });
      return;
    }
    const result = await pool.query('SELECT * FROM fn_listar_paquetes($1::integer, NULL)', [idEvento]);
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_paquetes(NULL, $1::integer)', [req.params.id]);
    if (!result.rows[0]) {
      res.status(404).json({ error: 'Paquete no encontrado' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    responderError(res, err);
  }
});

async function guardar(idPaquete: number | null, body: any, res: Response): Promise<number | null> {
  const p = leerPaquete(body, res);
  if (!p) return null;
  const result = await pool.query(
    `CALL sp_guardar_paquete($1::integer, $2::varchar, $3::text, $4::numeric, $5::integer, $6::integer, $7::integer, $8::boolean,
                             $9::jsonb, $10::jsonb, $11::jsonb, $12::integer[], $13::integer[], NULL)`,
    [idPaquete, p.nombre, p.descripcion, p.precio, p.minimo, p.horas, p.idTipoMenu, p.activo,
     JSON.stringify(p.grupos), JSON.stringify(p.incluidos), JSON.stringify(p.extras), p.locaciones, p.salones]
  );
  return result.rows[0].p_id_paquete_out;
}

router.post('/', async (req, res) => {
  try {
    const id = await guardar(null, req.body, res);
    if (id !== null) res.status(201).json({ id_paquete: id });
  } catch (err) {
    responderError(res, err);
  }
});

router.put('/:id', async (req, res) => {
  try {
    const id = await guardar(Number(req.params.id), req.body, res);
    if (id !== null) res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/paquetes/:id/duplicar - misma estructura con otro precio y/o área
router.post('/:id/duplicar', async (req, res) => {
  try {
    const { nombre, precio_por_persona } = req.body;
    const locaciones = Array.isArray(req.body.locaciones) ? req.body.locaciones : [];
    const salones = Array.isArray(req.body.salones) ? req.body.salones : [];
    if (precio_por_persona != null && !(Number(precio_por_persona) > 0)) {
      res.status(400).json({ error: 'El precio por persona debe ser mayor a 0' });
      return;
    }
    if (![...locaciones, ...salones].every(esEnteroPositivo)) {
      res.status(400).json({ error: 'Las áreas de disponibilidad no son válidas' });
      return;
    }
    const result = await pool.query(
      `CALL sp_duplicar_paquete($1::integer, $2::varchar, $3::numeric, $4::integer[], $5::integer[], NULL)`,
      [req.params.id, typeof nombre === 'string' ? nombre.trim() || null : null, precio_por_persona ?? null, locaciones, salones]
    );
    res.status(201).json({ id_paquete: result.rows[0].p_id_paquete_nuevo });
  } catch (err) {
    responderError(res, err);
  }
});

export default router;
