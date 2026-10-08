import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from '../db/pool.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CARPETA_ASSETS = path.join(__dirname, '..', '..', 'assets');
const LOGO_POR_DEFECTO = 'logo-quebrada.png';

const enCache = new Map<string, string>();

/**
 * Logo como data URI, para incrustarlo en los PDF (se lee del disco una sola vez por archivo).
 * Sin archivo, o si no existe, el de La Quebrada.
 */
export function logoDataUri(archivo: string | null = LOGO_POR_DEFECTO): string {
  const nombre = archivo && /^[\w.-]+\.(png|jpe?g)$/i.test(archivo) && fs.existsSync(path.join(CARPETA_ASSETS, archivo)) ? archivo : LOGO_POR_DEFECTO;
  if (!enCache.has(nombre)) {
    const tipo = /\.png$/i.test(nombre) ? 'png' : 'jpeg';
    enCache.set(nombre, `data:image/${tipo};base64,${fs.readFileSync(path.join(CARPETA_ASSETS, nombre)).toString('base64')}`);
  }
  return enCache.get(nombre)!;
}

/** Logo de la locación de un evento (si sus salones son todos de la misma locación); si no, el de La Quebrada. */
export async function logoDeEvento(idEvento: number): Promise<{ archivo: string | null; dataUri: string }> {
  const r = await pool.query(
    `SELECT CASE WHEN COUNT(DISTINCT s.id_locacion) = 1 THEN MAX(l.logo) END AS logo
     FROM evento_salon es JOIN salon s ON s.id_salon = es.id_salon JOIN locacion l ON l.id_locacion = s.id_locacion
     WHERE es.id_evento = $1`,
    [idEvento]
  );
  const archivo = r.rows[0]?.logo ?? null;
  return { archivo, dataUri: logoDataUri(archivo) };
}

/** Logo que corresponde a un usuario: el de su locación si todas sus áreas son de una sola; si no, el de La Quebrada. */
export async function logoDeUsuario(idUsuario: number): Promise<string | null> {
  const r = await pool.query(
    `WITH alcance AS (SELECT fn_salones_usuario($1::integer) AS salones)
     SELECT CASE WHEN a.salones IS NOT NULL AND COUNT(DISTINCT s.id_locacion) = 1 THEN MAX(l.logo) END AS logo
     FROM alcance a
     LEFT JOIN salon s ON s.id_salon = ANY (a.salones)
     LEFT JOIN locacion l ON l.id_locacion = s.id_locacion
     GROUP BY a.salones`,
    [idUsuario]
  );
  return r.rows[0]?.logo ?? null;
}
