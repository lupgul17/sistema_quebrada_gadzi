import type { Request, Response, NextFunction } from 'express';

interface OpcionesLimitador {
  ventanaMs: number;
  max: number;
  mensaje: string;
  /** Qué identifica a quien hace el pedido (por defecto, la IP). */
  clave?: (req: Request) => string;
}

/**
 * Límite simple de pedidos en memoria. Alcanza para una sola instancia del servidor;
 * si algún día corre en varias, habría que moverlo a Redis o a la base de datos.
 */
export function crearLimitador({ ventanaMs, max, mensaje, clave = (req) => req.ip ?? 'desconocida' }: OpcionesLimitador) {
  const intentos = new Map<string, number[]>();

  // Limpieza periódica para que el mapa no crezca indefinidamente
  setInterval(() => {
    const ahora = Date.now();
    for (const [k, tiempos] of intentos) {
      const vigentes = tiempos.filter((t) => ahora - t < ventanaMs);
      if (vigentes.length === 0) intentos.delete(k);
      else intentos.set(k, vigentes);
    }
  }, ventanaMs).unref();

  function middleware(req: Request, res: Response, next: NextFunction): void {
    const k = clave(req);
    const ahora = Date.now();
    const recientes = (intentos.get(k) ?? []).filter((t) => ahora - t < ventanaMs);
    if (recientes.length >= max) {
      const reintentoSeg = Math.ceil((ventanaMs - (ahora - recientes[0])) / 1000);
      res.setHeader('Retry-After', String(reintentoSeg));
      res.status(429).json({ error: mensaje });
      return;
    }
    recientes.push(ahora);
    intentos.set(k, recientes);
    next();
  }

  /** Borra los intentos de esa clave (ej. después de un login correcto). */
  function reiniciar(req: Request): void {
    intentos.delete(clave(req));
  }

  return { middleware, reiniciar };
}
