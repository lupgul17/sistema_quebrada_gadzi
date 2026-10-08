import './helpers.js';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { leerPersona } from '../src/utils/validar.js';

const base = { primer_nombre: 'Juan', primer_apellido: 'Gudiel' };

test('datos vacíos se guardan como null (un CUI "" no debe confundirse con el de otra persona)', () => {
  const r = leerPersona({ ...base, cui: '', nit: '  ', telefono: '', correo: '' });
  assert.ok('datos' in r);
  assert.deepEqual([r.datos.cui, r.datos.nit, r.datos.telefono, r.datos.correo], [null, null, null, null]);
});

test('limpia formatos: CUI sin espacios, teléfono sin guiones, correo en minúsculas', () => {
  const r = leerPersona({ ...base, cui: '1234 56789 0123', telefono: '5502-4196', correo: ' Juan@Correo.COM ' });
  assert.ok('datos' in r);
  assert.equal(r.datos.cui, '1234567890123');
  assert.equal(r.datos.telefono, '55024196');
  assert.equal(r.datos.correo, 'juan@correo.com');
});

test('rechaza formatos inválidos con un mensaje claro', () => {
  assert.deepEqual(leerPersona({ ...base, cui: '123' }), { error: 'El CUI debe tener 13 dígitos.' });
  assert.deepEqual(leerPersona({ ...base, telefono: '1234' }), { error: 'El teléfono debe tener 8 dígitos.' });
  assert.deepEqual(leerPersona({ ...base, correo: 'juan@' }), { error: 'El correo no es válido.' });
  assert.ok('error' in leerPersona({ primer_nombre: 'Juan' }));
  assert.ok('error' in leerPersona({ ...base, primer_nombre: 'Juan123' }));
});

test('acepta teléfono con +502, internacional y NIT CF', () => {
  assert.ok('datos' in leerPersona({ ...base, telefono: '+502 5502 4196', nit: 'cf' }));
  assert.ok('datos' in leerPersona({ ...base, telefono: '+1 305 555 0101', nit: '1234567-8' }));
});
