// Utilidades compartidas por los tests. Ningún test usa la base de datos real:
// DATABASE_URL apunta a un puerto cerrado para que, si algo llegara a consultarla, falle.
process.env.DATABASE_URL ??= 'postgresql://test:test@127.0.0.1:1/test';
process.env.JWT_SECRET ??= 'secreto-de-prueba';

import express from 'express';
import type { Express } from 'express';
import type { AddressInfo } from 'node:net';

export interface RespuestaFalsa {
  statusCode: number;
  cuerpo: unknown;
  headers: Record<string, string>;
  status(code: number): RespuestaFalsa;
  json(body: unknown): RespuestaFalsa;
  setHeader(k: string, v: string): void;
}

/** Imitación mínima de `res` de Express para probar middlewares sin levantar servidor. */
export function respuestaFalsa(): RespuestaFalsa {
  const res: RespuestaFalsa = {
    statusCode: 200,
    cuerpo: undefined,
    headers: {},
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.cuerpo = body;
      return this;
    },
    setHeader(k, v) {
      this.headers[k] = v;
    },
  };
  return res;
}

/** Levanta la app en un puerto libre, ejecuta `fn` con la URL base y la cierra. */
export async function conServidor(app: Express, fn: (base: string) => Promise<void>): Promise<void> {
  const servidor = app.listen(0);
  await new Promise<void>((ok) => servidor.once('listening', () => ok()));
  const { port } = servidor.address() as AddressInfo;
  try {
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise<void>((ok) => servidor.close(() => ok()));
  }
}

export function appConJson(): Express {
  const app = express();
  app.use(express.json());
  return app;
}
