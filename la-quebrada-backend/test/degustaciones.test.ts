import './helpers.js';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import degustacionesRouter from '../src/routes/degustaciones.routes.js';
import { agruparSesionesDegustacion } from '../src/templates/reports/reporte-degustacion.template.js';
import { appConJson, conServidor } from './helpers.js';

test('PDF de una sesión: ID inválido → 400 sin consultar la base', async () => {
  const app = appConJson();
  app.use('/api/degustaciones', degustacionesRouter);
  await conServidor(app, async (base) => {
    for (const id of ['abc', '0', '-3', '2.5']) {
      const r = await fetch(`${base}/api/degustaciones/fechas/${id}/pdf`);
      assert.equal(r.status, 400, id);
    }
  });
});

test('agrupa las filas del reporte por sesión (fecha + hora)', () => {
  const fila = (hora: string, cliente: string) => ({
    fecha_sesion: '2026-10-10',
    hora_inicio: hora,
    cliente,
    tipo_evento: 'Boda',
    fecha_evento: '2026-12-05',
    menus: [],
  });
  const sesiones = agruparSesionesDegustacion([fila('10:00:00', 'Ana'), fila('10:00:00', 'Luis'), fila('15:00:00', 'Marta')]);
  assert.equal(sesiones.length, 2);
  assert.equal(sesiones[0].cards.length, 2);
  assert.match(sesiones[0].titulo, /10:00$/);
  assert.equal(sesiones[1].cards[0].cliente, 'Marta');
});
