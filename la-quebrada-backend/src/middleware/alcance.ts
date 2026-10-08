import type { Response, NextFunction } from 'express';
import { pool } from '../db/pool.js';
import type { AuthRequest } from './auth.middleware.js';

/**
 * Alcance por área: qué salones puede ver el usuario de la petición.
 *   req.alcance = null      → ve todo (Superusuario, o usuario sin áreas asignadas)
 *   req.alcance = [2, 5]    → solo eventos que usen alguno de esos salones
 * Se calcula en cada petición (una consulta liviana): si cambian las áreas de alguien, aplica al instante.
 *
 * Este middleware solo RESUELVE el alcance. Aplicarlo es trabajo de cada ruta, con:
 *   - exigirAlcance(req, res, 'cotizacion', id)  → rutas con id (responde 404 si no es de su área)
 *   - filtrarPorAlcance(req, filas)             → listados
 */
export interface RequestConAlcance extends AuthRequest {
  alcance?: number[] | null;
}

export type TipoRecurso =
  | 'evento' | 'cotizacion' | 'cotizacion_menu' | 'cotizacion_servicios' | 'descuento'
  | 'pago' | 'degustacion' | 'degustacion_menu' | 'extras_servicios' | 'extras_menu';

export async function resolverAlcance(req: RequestConAlcance, res: Response, next: NextFunction): Promise<void> {
  if (req.method === 'OPTIONS' || !req.usuario) return next();
  try {
    const r = await pool.query('SELECT fn_salones_usuario($1::integer) AS salones', [req.usuario.id_usuario]);
    req.alcance = r.rows[0]?.salones ?? null;
    next();
  } catch (err) {
    console.error('No se pudo resolver el alcance del usuario:', err);
    res.status(500).json({ error: 'Ocurrió un error en el servidor. Intentá de nuevo en un momento.' });
  }
}

/**
 * Para rutas con id: si el recurso no es de un evento del área del usuario, responde 404 (no 403:
 * así ni siquiera confirma que existe) y devuelve false. Uso:
 *   if (!(await exigirAlcance(req, res, 'pago', req.params.id))) return;
 */
export async function exigirAlcance(req: RequestConAlcance, res: Response, tipo: TipoRecurso, id: unknown): Promise<boolean> {
  if (req.alcance === null || req.alcance === undefined) return true;
  const idNum = Number(id);
  if (!Number.isInteger(idNum) || idNum <= 0) {
    res.status(404).json({ error: 'No encontrado' });
    return false;
  }
  const r = await pool.query('SELECT fn_evento_en_alcance(fn_evento_de($1, $2::integer), $3::integer[]) AS ok', [tipo, idNum, req.alcance]);
  if (!r.rows[0]?.ok) {
    res.status(404).json({ error: 'No encontrado' });
    return false;
  }
  return true;
}

/** Ids de los eventos que el usuario puede ver (null = todos). */
export async function eventosEnAlcance(req: RequestConAlcance): Promise<Set<number> | null> {
  if (req.alcance === null || req.alcance === undefined) return null;
  const r = await pool.query('SELECT DISTINCT id_evento FROM evento_salon WHERE id_salon = ANY($1::integer[])', [req.alcance]);
  return new Set(r.rows.map((f) => f.id_evento as number));
}

/** Deja solo las filas de eventos del área del usuario (por defecto según la columna id_evento). */
export async function filtrarPorAlcance<T extends Record<string, any>>(req: RequestConAlcance, filas: T[], campo = 'id_evento'): Promise<T[]> {
  const ids = await eventosEnAlcance(req);
  return ids === null ? filas : filas.filter((f) => ids.has(Number(f[campo])));
}

/** ¿Todos estos salones están dentro del alcance? (para crear o editar un evento) */
export function salonesEnAlcance(req: RequestConAlcance, salones: number[]): boolean {
  if (req.alcance === null || req.alcance === undefined) return true;
  return salones.every((s) => req.alcance!.includes(Number(s)));
}

/**
 * Para router.param: valida el alcance del recurso que nombra ese parámetro de la URL.
 *   router.param('id', guardiaAlcance('pago'))
 * El tipo puede depender de la ruta (ej. /menu/:idLinea vs /servicios/:idLinea); null = no aplica.
 */
export function guardiaAlcance(tipo: TipoRecurso | ((req: RequestConAlcance) => TipoRecurso | null)) {
  return async (req: any, res: Response, next: NextFunction, id: unknown): Promise<void> => {
    try {
      const t = typeof tipo === 'function' ? tipo(req) : tipo;
      if (t === null) return next();
      if (await exigirAlcance(req, res, t, id)) next();
    } catch (err) {
      next(err);
    }
  };
}

/** Deja solo las degustaciones de eventos del área (para filas que traen id_degustacion y no id_evento). */
export async function filtrarDegustacionesPorAlcance<T extends Record<string, any>>(req: RequestConAlcance, filas: T[]): Promise<T[]> {
  if (req.alcance === null || req.alcance === undefined) return filas;
  const r = await pool.query(
    'SELECT d.id_degustacion FROM degustacion d WHERE fn_evento_en_alcance(d.id_evento, $1::integer[])',
    [req.alcance]
  );
  const ids = new Set(r.rows.map((f) => f.id_degustacion as number));
  return filas.filter((f) => ids.has(Number(f.id_degustacion)));
}
