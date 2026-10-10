import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../db/pool.js';
import type { AuthRequest } from '../middleware/auth.middleware.js';
import { formato, leerPersona, textoONull } from '../utils/validar.js';
import { responderError } from '../utils/errores.js';

const router = Router();

const MIN_PASSWORD = 8;


// GET /api/usuarios
router.get('/', async (_req, res) => {
  try {
    const result = await pool.query('SELECT u.*, fn_areas_usuario(u.id_usuario) AS areas FROM fn_listar_usuarios() u');
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
    if (!/^[a-z0-9._-]{3,30}$/.test(username)) {
      res.status(400).json({ error: 'El usuario solo puede tener minúsculas, números, punto o guiones (3 a 30).' });
      return;
    }
    // Vacío → null: el SP reutiliza a la persona con el mismo CUI o correo, y un "" se confundía
    // con el de otra persona que también lo tuviera vacío
    const cuiLimpio = textoONull(cui)?.replace(/\s/g, '') ?? null;
    const telLimpio = textoONull(telefono)?.replace(/[\s-]/g, '') ?? null;
    const correoLimpio = textoONull(correo)?.toLowerCase() ?? null;
    if (cuiLimpio && !formato.cui(cuiLimpio)) {
      res.status(400).json({ error: 'El CUI debe tener 13 dígitos.' });
      return;
    }
    if (telLimpio && !formato.telefono(telLimpio)) {
      res.status(400).json({ error: 'El teléfono debe tener 8 dígitos.' });
      return;
    }
    if (correoLimpio && !formato.correo(correoLimpio)) {
      res.status(400).json({ error: 'El correo no es válido.' });
      return;
    }

    const hash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `CALL sp_crear_usuario($1::varchar, $2::varchar, $3::varchar, $4::varchar, $5::varchar, $6::varchar, $7::varchar,
                             $8::varchar, $9::varchar, $10::integer, $11::integer, NULL)`,
      [
        textoONull(primer_nombre), textoONull(segundo_nombre), textoONull(primer_apellido), textoONull(segundo_apellido),
        cuiLimpio, telLimpio, correoLimpio, username, hash, id_rol_acceso, id_tipo_empleado,
      ]
    );
    res.status(201).json({ id_usuario: result.rows[0].p_id_usuario });
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/usuarios/:id  (datos personales, para el diálogo Editar)
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM fn_obtener_usuario($1::integer)', [req.params.id]);
    if (!result.rows.length) {
      res.status(404).json({ error: 'No existe el usuario.' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err) {
    responderError(res, err);
  }
});

// PUT /api/usuarios/:id/datos  (nombres, CUI, teléfono y correo; el NIT no se toca)
router.put('/:id/datos', async (req, res) => {
  try {
    const leido = leerPersona({ ...req.body, nit: null });
    if ('error' in leido) {
      res.status(400).json({ error: leido.error });
      return;
    }
    const { primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cui, telefono, correo } = leido.datos;
    await pool.query(
      `CALL sp_editar_datos_usuario($1::integer, $2::varchar, $3::varchar, $4::varchar, $5::varchar,
                                    $6::varchar, $7::varchar, $8::varchar)`,
      [req.params.id, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cui, telefono, correo]
    );
    res.json({ ok: true });
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

// PUT /api/usuarios/:id/areas  { locaciones: [ids], salones: [ids] }  (vacío = ve todo)
router.put('/:id/areas', async (req, res) => {
  try {
    const locaciones = Array.isArray(req.body.locaciones) ? req.body.locaciones : [];
    const salones = Array.isArray(req.body.salones) ? req.body.salones : [];
    const valido = (v: unknown) => Number.isInteger(v) && (v as number) > 0;
    if (![...locaciones, ...salones].every(valido)) {
      res.status(400).json({ error: 'Las áreas no son válidas' });
      return;
    }
    await pool.query('CALL sp_guardar_areas_usuario($1::integer, $2::integer[], $3::integer[])', [req.params.id, locaciones, salones]);
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