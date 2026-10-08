import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../db/pool.js';
import type { AuthRequest } from '../middleware/auth.middleware.js';
import { responderError } from '../utils/errores.js';

const router = Router();

const MIN_PASSWORD = 8;


// GET /api/usuarios
router.get('/', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_usuarios()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/usuarios/roles
router.get('/roles', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_roles_acceso()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/usuarios/tipos-empleado
router.get('/tipos-empleado', async (_req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_listar_tipos_empleado()');
    res.json(result.rows);
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/usuarios
router.post('/', async (req: AuthRequest, res) => {
  try {
    const {
      primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
      cui, telefono, correo, password, id_rol_acceso, id_tipo_empleado,
    } = req.body;
    // Usuarios siempre en minúsculas (el login también los busca así)
    const username = typeof req.body.username === 'string' ? req.body.username.trim().toLowerCase() : '';

    if (!username || !password || !id_rol_acceso || !id_tipo_empleado) {
      res.status(400).json({ error: 'Falta usuario, contraseña, rol o tipo de empleado' });
      return;
    }
    if (String(password).length < MIN_PASSWORD) {
      res.status(400).json({ error: `La contraseña debe tener al menos ${MIN_PASSWORD} caracteres` });
      return;
    }

    const hash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `CALL sp_crear_usuario($1::varchar, $2::varchar, $3::varchar, $4::varchar, $5::varchar, $6::varchar, $7::varchar,
                             $8::varchar, $9::varchar, $10::integer, $11::integer, NULL)`,
      [
        primer_nombre ?? null, segundo_nombre ?? null, primer_apellido ?? null, segundo_apellido ?? null,
        cui ?? null, telefono ?? null, correo ?? null, username, hash, id_rol_acceso, id_tipo_empleado,
      ]
    );
    res.status(201).json({ id_usuario: result.rows[0].p_id_usuario });
  } catch (err) {
    responderError(res, err);
  }
});

// PATCH /api/usuarios/:id  (rol y estado)
router.patch('/:id', async (req: AuthRequest, res) => {
  try {
    const { id_rol_acceso, activo } = req.body;
    if (!id_rol_acceso || typeof activo !== 'boolean') {
      res.status(400).json({ error: 'Falta id_rol_acceso o activo' });
      return;
    }
    if (Number(req.params.id) === req.usuario!.id_usuario) {
      res.status(400).json({ error: 'No podés cambiar tu propio rol ni desactivar tu cuenta. Pedíselo a otro Superusuario.' });
      return;
    }
    await pool.query('CALL sp_editar_usuario($1::integer, $2::integer, $3::boolean)', [req.params.id, id_rol_acceso, activo]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

// PATCH /api/usuarios/:id/password  (reseteo por un Superusuario)
router.patch('/:id/password', async (req, res) => {
  try {
    const { password } = req.body;
    if (!password || String(password).length < MIN_PASSWORD) {
      res.status(400).json({ error: `La contraseña debe tener al menos ${MIN_PASSWORD} caracteres` });
      return;
    }
    const hash = await bcrypt.hash(password, 10);
    await pool.query('CALL sp_cambiar_password($1::integer, $2::varchar)', [req.params.id, hash]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

export default router;