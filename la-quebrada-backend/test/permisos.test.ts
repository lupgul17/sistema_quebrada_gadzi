import './helpers.js';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { aplicarPermisos } from '../src/middleware/permisos.js';
import { respuestaFalsa } from './helpers.js';

/** Devuelve el status final: 200 si dejó pasar, o el código con que cortó. */
function probar(rol: string | null, metodo: string, url: string): number {
  const req = { method: metodo, originalUrl: url, usuario: rol ? { rol_acceso: rol } : undefined } as any;
  const res = respuestaFalsa();
  let paso = false;
  aplicarPermisos(req, res as any, () => {
    paso = true;
  });
  return paso ? 200 : res.statusCode;
}

test('sin rol en la sesión → 401', () => {
  assert.equal(probar(null, 'GET', '/api/clientes'), 401);
});

test('el login no exige sesión', () => {
  assert.equal(probar(null, 'POST', '/api/auth/login'), 200);
});

test('solo Superusuario administra usuarios', () => {
  assert.equal(probar('Superusuario', 'GET', '/api/usuarios'), 200);
  assert.equal(probar('Administrador', 'GET', '/api/usuarios'), 403);
  assert.equal(probar('Vendedor', 'POST', '/api/usuarios'), 403);
});

test('cambiar mayúsculas en la URL no salta el permiso', () => {
  for (const url of ['/api/USUARIOS', '/API/usuarios', '/api/Usuarios/3']) {
    assert.equal(probar('Vendedor', 'GET', url), 403, url);
  }
  assert.equal(probar('Vendedor', 'GET', '/api/Reportes/x'), 403);
});

test('HEAD se evalúa igual que GET', () => {
  assert.equal(probar('Vendedor', 'HEAD', '/api/usuarios'), 403);
  assert.equal(probar('Vendedor', 'HEAD', '/api/clientes'), 200);
});

test('reportes: solo administradores', () => {
  assert.equal(probar('Administrador2', 'GET', '/api/reportes/eventos'), 200);
  assert.equal(probar('Secretaria', 'GET', '/api/reportes/eventos'), 403);
});

test('Secretaria crea menús pero no componentes ni servicios', () => {
  assert.equal(probar('Secretaria', 'POST', '/api/menus'), 200);
  assert.equal(probar('Secretaria', 'PUT', '/api/menus/4'), 200);
  assert.equal(probar('Secretaria', 'POST', '/api/componentes-menu'), 403);
  assert.equal(probar('Secretaria', 'POST', '/api/servicios'), 403);
});

test('verificar pagos: Revisor sí, Vendedor no; registrar pagos al revés', () => {
  assert.equal(probar('Revisor', 'PATCH', '/api/pagos/12/verificar'), 200);
  assert.equal(probar('Vendedor', 'PATCH', '/api/pagos/12/verificar'), 403);
  assert.equal(probar('Vendedor', 'POST', '/api/pagos'), 200);
  assert.equal(probar('Revisor', 'POST', '/api/pagos'), 403);
});

test('aprobar descuentos es más específico que editar cotizaciones', () => {
  assert.equal(probar('Vendedor', 'POST', '/api/cotizaciones/3/menu'), 200);
  assert.equal(probar('Vendedor', 'PATCH', '/api/cotizaciones/descuentos/7'), 403);
  assert.equal(probar('Administrador', 'PATCH', '/api/cotizaciones/descuentos/7'), 200);
});

test('sin regla: lectura permitida, escritura negada por defecto', () => {
  assert.equal(probar('Revisor', 'GET', '/api/salones'), 200);
  assert.equal(probar('Superusuario', 'POST', '/api/salones'), 403);
});

test('/auth acepta cualquier rol con sesión, incluso uno nuevo', () => {
  assert.equal(probar('RolQueNoExisteTodavia', 'POST', '/api/auth/cambiar-password'), 200);
});
