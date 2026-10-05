import './helpers.js';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { responderError } from '../src/utils/errores.js';
import { crearLimitador } from '../src/middleware/limitador.js';
import { respuestaFalsa } from './helpers.js';

function statusDe(err: unknown) {
  const res = respuestaFalsa();
  responderError(res as any, err);
  return { status: res.statusCode, error: (res.cuerpo as { error: string }).error };
}

test('RAISE EXCEPTION de un SP (P0001) → 400 con el mensaje del SP', () => {
  const r = statusDe({ code: 'P0001', message: 'El salón no está disponible' });
  assert.deepEqual(r, { status: 400, error: 'El salón no está disponible' });
});

test('dato con formato inválido (ej. cantidad "2.7") → 400', () => {
  assert.equal(statusDe({ code: '22P02', message: 'invalid input syntax for type integer' }).status, 400);
});

test('duplicado → 409, referencia rota → 400', () => {
  assert.equal(statusDe({ code: '23505' }).status, 409);
  assert.equal(statusDe({ code: '23503' }).status, 400);
});

test('error desconocido → 500 genérico, sin filtrar el detalle interno', (t) => {
  t.mock.method(console, 'error', () => undefined); // no ensuciar la salida del test
  const r = statusDe(new Error('relation "tabla_secreta" does not exist'));
  assert.equal(r.status, 500);
  assert.ok(!r.error.includes('tabla_secreta'));
});

test('el limitador corta al pasar el máximo y se reinicia', () => {
  const limitador = crearLimitador({ ventanaMs: 60_000, max: 3, mensaje: 'Esperá', clave: () => 'misma-clave' });
  const llamar = () => {
    const res = respuestaFalsa();
    let paso = false;
    limitador.middleware({} as any, res as any, () => {
      paso = true;
    });
    return { paso, res };
  };

  assert.ok(llamar().paso);
  assert.ok(llamar().paso);
  assert.ok(llamar().paso);
  const cuarto = llamar();
  assert.equal(cuarto.paso, false);
  assert.equal(cuarto.res.statusCode, 429);
  assert.ok(Number(cuarto.res.headers['Retry-After']) > 0);

  limitador.reiniciar({} as any);
  assert.ok(llamar().paso, 'después de reiniciar vuelve a dejar pasar');
});

test('el limitador cuenta por separado cada clave', () => {
  const limitador = crearLimitador({ ventanaMs: 60_000, max: 1, mensaje: 'Esperá', clave: (req: any) => req.ip });
  const pasa = (ip: string) => {
    let paso = false;
    limitador.middleware({ ip } as any, respuestaFalsa() as any, () => {
      paso = true;
    });
    return paso;
  };
  assert.ok(pasa('1.1.1.1'));
  assert.equal(pasa('1.1.1.1'), false);
  assert.ok(pasa('2.2.2.2'), 'otra IP no se ve afectada');
});
