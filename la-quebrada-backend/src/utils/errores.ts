import type { Response } from 'express';

/**
 * Respuesta de error uniforme para todas las rutas.
 * - P0001: RAISE EXCEPTION de nuestros SPs (regla de negocio) → 400 con el mensaje del SP.
 * - Datos con formato o rango inválido / falta un dato obligatorio → 400.
 * - Referencia a algo que no existe o que está en uso → 400.
 * - Duplicado → 409.
 * - Cualquier otra cosa es un error real del servidor → 500 genérico; el detalle va al log,
 *   no al navegador (puede traer nombres de tablas o columnas).
 */
export function responderError(res: Response, err: unknown): void {
  const e = err as { code?: string; message?: string };

  switch (e.code) {
    case 'P0001':
      res.status(400).json({ error: e.message });
      return;
    case '22P02': // texto que no se puede convertir (ej. "abc" o "2.7" a integer)
    case '22003': // número fuera de rango
    case '22007': // fecha/hora inválida
    case '22008':
      res.status(400).json({ error: 'Alguno de los datos enviados tiene un formato inválido' });
      return;
    case '23502':
      res.status(400).json({ error: 'Falta un dato obligatorio' });
      return;
    case '23503':
      res.status(400).json({ error: 'El registro relacionado no existe o está siendo usado por otro registro' });
      return;
    case '23505':
      res.status(409).json({ error: 'Ya existe un registro con esos datos' });
      return;
    case '23514':
      res.status(400).json({ error: 'Alguno de los datos no cumple las reglas permitidas' });
      return;
  }

  console.error('Error no controlado:', err);
  res.status(500).json({ error: 'Ocurrió un error en el servidor. Intentá de nuevo en un momento.' });
}
