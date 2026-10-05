import { Router } from 'express';
import { pool } from '../db/pool.js';
import { responderError } from '../utils/errores.js';

const router = Router();

router.get('/categorias-servicio', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_categorias_servicio()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

router.get('/categorias-componente-menu', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_categorias_componente_menu()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

router.get('/tipos-menu', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_tipos_menu()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});
router.get('/colores-mantel', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_colores_mantel()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

router.get('/colores-cubremanteles', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_colores_cubremanteles()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});
router.get('/tipos-descuento', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_tipos_descuento()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});
router.get('/tipos-pago', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_tipos_pago()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

router.get('/tipos-cargo-extra', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_tipos_cargo_extra()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

export default router;