import { Router } from 'express';
import puppeteer from 'puppeteer';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from '../db/pool.js';
import { armarHtmlReporte } from '../templates/reports/reporte.template.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const router = Router();

// GET /api/reportes/eventos?fecha_desde&fecha_hasta
router.get('/eventos', async (req, res) => {
  try {
    const { fecha_desde, fecha_hasta } = req.query;
    const result = await pool.query('SELECT * FROM fn_listar_eventos(NULL, $1::date, $2::date, NULL)', [fecha_desde ?? null, fecha_hasta ?? null]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// GET /api/reportes/eventos-detallado?fecha_desde&fecha_hasta
router.get('/eventos-detallado', async (req, res) => {
  try {
    const { fecha_desde, fecha_hasta } = req.query;
    if (!fecha_desde || !fecha_hasta) {
      res.status(400).json({ error: 'Falta fecha_desde o fecha_hasta' });
      return;
    }
    const result = await pool.query('SELECT * FROM fn_reporte_eventos_detallado($1::date, $2::date)', [fecha_desde, fecha_hasta]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// GET /api/reportes/pendientes-pago
router.get('/pendientes-pago', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_reporte_pendientes_pago()');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// GET /api/reportes/degustaciones?fecha_desde&fecha_hasta
router.get('/degustaciones', async (req, res) => {
  try {
    const { fecha_desde, fecha_hasta } = req.query;
    if (!fecha_desde || !fecha_hasta) {
      res.status(400).json({ error: 'Falta fecha_desde o fecha_hasta' });
      return;
    }
    const result = await pool.query('SELECT * FROM fn_reporte_degustaciones_detallado($1::date, $2::date)', [fecha_desde, fecha_hasta]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// GET /api/reportes/:tipo/pdf?fecha_desde&fecha_hasta
router.get('/:tipo/pdf', async (req, res) => {
  try {
    const { tipo } = req.params;
    const { fecha_desde, fecha_hasta } = req.query;

    let titulo = '';
    let subtitulo = '';
    let columnas: string[] = [];
    let filas: (string | number)[][] = [];

    if (tipo === 'eventos') {
      const result = await pool.query('SELECT * FROM fn_listar_eventos(NULL, $1::date, $2::date, NULL)', [fecha_desde ?? null, fecha_hasta ?? null]);
      titulo = 'Lista de eventos';
      subtitulo = fecha_desde && fecha_hasta ? `${fecha_desde} al ${fecha_hasta}` : 'Todos';
      columnas = ['Fecha', 'Cliente', 'Tipo', 'Salón(es)', 'Estado'];
      filas = result.rows.map((r) => [new Date(r.fecha).toLocaleDateString('es-GT'), r.cliente, r.tipo_evento ?? '—', r.salones ?? '—', r.estado]);
    } else if (tipo === 'eventos-detallado') {
      const result = await pool.query('SELECT * FROM fn_reporte_eventos_detallado($1::date, $2::date)', [fecha_desde, fecha_hasta]);
      titulo = 'Lista de eventos — Detallado';
      subtitulo = `${fecha_desde} al ${fecha_hasta}`;
      columnas = ['Fecha', 'Cliente', 'Tipo', 'Estado', 'Personas', 'Total a pagar', 'Pagado', 'Saldo', 'Degustación', 'Extras'];
      filas = result.rows.map((r) => [
        new Date(r.fecha).toLocaleDateString('es-GT'), r.cliente, r.tipo_evento ?? '—', r.estado,
        `${r.total_adultos + r.total_menores}`, `Q${Number(r.total_a_pagar).toFixed(2)}`, `Q${Number(r.total_pagado).toFixed(2)}`,
        `Q${Number(r.saldo_pendiente).toFixed(2)}`, r.tiene_degustacion ? 'Sí' : 'No', `Q${Number(r.total_extras).toFixed(2)}`,
      ]);
    } else if (tipo === 'pendientes-pago') {
      const result = await pool.query('SELECT * FROM fn_reporte_pendientes_pago()');
      titulo = 'Eventos pendientes de pago';
      columnas = ['Fecha', 'Días restantes', 'Cliente', 'Total', 'Pagado', 'Saldo', 'Checkpoint'];
      filas = result.rows.map((r) => [
        new Date(r.fecha).toLocaleDateString('es-GT'), r.dias_para_evento, r.cliente,
        `Q${Number(r.total_a_pagar).toFixed(2)}`, `Q${Number(r.total_pagado).toFixed(2)}`, `Q${Number(r.saldo_pendiente).toFixed(2)}`, r.checkpoint,
      ]);
    } else if (tipo === 'degustaciones') {
      const result = await pool.query('SELECT * FROM fn_reporte_degustaciones_detallado($1::date, $2::date)', [fecha_desde, fecha_hasta]);
      titulo = 'Degustaciones — Detallado';
      subtitulo = `${fecha_desde} al ${fecha_hasta}`;
      columnas = ['Fecha sesión', 'Hora', 'Cliente', 'Teléfono', 'Tipo evento', 'Menús a probar'];
      filas = result.rows.map((r) => [
        new Date(r.fecha_sesion).toLocaleDateString('es-GT'), r.hora_inicio.substring(0, 5), r.cliente, r.telefono ?? '—', r.tipo_evento ?? '—', r.menus,
      ]);
    } else {
      res.status(400).json({ error: 'Tipo de reporte inválido' });
      return;
    }

    const logoPath = path.join(__dirname, '..', '..', 'assets', 'logo-quebrada.png');
    const logoBase64 = fs.readFileSync(logoPath).toString('base64');

    const html = armarHtmlReporte({
      titulo,
      subtitulo,
      columnas,
      filas,
      logoUrl: `data:image/png;base64,${logoBase64}`,
    });

    const browser = await puppeteer.launch();
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: 'domcontentloaded' });
    const pdfBuffer = await page.pdf({ format: 'Letter', printBackground: true, landscape: true, margin: { top: '20px', bottom: '20px' } });
    await browser.close();

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="reporte-${tipo}.pdf"`);
    res.send(Buffer.from(pdfBuffer));
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

export default router;