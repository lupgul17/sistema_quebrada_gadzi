import './helpers.js';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import publicoRouter from '../src/routes/publico.routes.js';
import { appConJson, conServidor } from './helpers.js';

// Solo se prueban los casos que se resuelven ANTES de llegar a la base de datos.
const app = appConJson();
app.use('/api/publico', publicoRouter);

async function enviar(base: string, cuerpo: unknown) {
  const r = await fetch(`${base}/api/publico/solicitudes`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(cuerpo),
  });
  return { status: r.status, cuerpo: (await r.json()) as { error?: string; ok?: boolean } };
}

test('formulario público de solicitudes', async (t) => {
  await conServidor(app, async (base) => {
    await t.test('honeypot lleno: responde 201 sin guardar (el bot no se entera)', async () => {
      const r = await enviar(base, { nombre: 'Bot', telefono: '55555555', sitio_web: 'spam.example' });
      assert.equal(r.status, 201);
    });

    await t.test('faltan nombre o teléfono → 400', async () => {
      assert.equal((await enviar(base, { nombre: 'Ana' })).status, 400);
    });

    await t.test('teléfono con letras → 400', async () => {
      assert.equal((await enviar(base, { nombre: 'Ana', telefono: 'abc' })).status, 400);
    });

    await t.test('correo inválido → 400', async () => {
      assert.equal((await enviar(base, { nombre: 'Ana', telefono: '5555 5555', correo: 'x@' })).status, 400);
    });

    await t.test('después de 5 solicitudes por hora desde la misma IP → 429', async () => {
      // Ya van 4 en esta IP; la 5ta pasa la validación de límite, la 6ta no
      await enviar(base, { nombre: 'Ana' });
      const sexta = await enviar(base, { nombre: 'Ana', telefono: '55555555' });
      assert.equal(sexta.status, 429);
    });
  });
});

test('fechas ocupadas: valida formato y rango antes de consultar', async () => {
  await conServidor(app, async (base) => {
    const malFormato = await fetch(`${base}/api/publico/fechas-ocupadas?desde=hoy&hasta=x`);
    assert.equal(malFormato.status, 400);
    const rangoLargo = await fetch(`${base}/api/publico/fechas-ocupadas?desde=2026-01-01&hasta=2026-12-31`);
    assert.equal(rangoLargo.status, 400);
  });
});
