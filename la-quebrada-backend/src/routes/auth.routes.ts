import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db/pool.js';
import { requireAuth } from '../middleware/auth.middleware.js';
import type { AuthRequest } from '../middleware/auth.middleware.js';
import { responderError } from '../utils/errores.js';
import { crearLimitador } from '../middleware/limitador.js';

const router = Router();

// 10 intentos cada 15 minutos por IP + usuario: frena a quien prueba contraseñas,
// sin bloquear a otros usuarios que entran desde la misma red del salón.
const limiteLogin = crearLimitador({
  ventanaMs: 15 * 60 * 1000,
  max: 10,
  mensaje: 'Demasiados intentos de inicio de sesión. Esperá unos minutos e intentá de nuevo.',
  clave: (req) => `${req.ip}|${String(req.body?.username ?? '').trim().toLowerCase()}`,
});

router.post('/login', limiteLogin.middleware, async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    res.status(400).json({ error: 'Falta username o password' });
    return;
  }
  
  try {
    const busqueda = await pool.query('SELECT * FROM fn_buscar_usuario_login($1)', [username]);
    const usuario = busqueda.rows[0];

    if (!usuario) {
      res.status(401).json({ error: 'Usuario o contraseña incorrectos' });
      return;
    }


    const passwordValida = await bcrypt.compare(password, usuario.password_hash);
    if (!passwordValida) {
      res.status(401).json({ error: 'Usuario o contraseña incorrectos' });
      return;
    }

    if (!usuario.confirmacion) {
      res.status(403).json({ error: 'Cuenta no confirmada' });
      return;
    }

        if (!usuario.activo) {
      res.status(403).json({ error: 'Cuenta desactivada. Contactá al administrador.' });
      return;
    }

    if (!usuario.id_rol_acceso) {
      res.status(403).json({ error: 'Tu cuenta no tiene un rol asignado. Contactá al administrador.' });
      return;
    }

    limiteLogin.reiniciar(req);
    await pool.query('CALL sp_registrar_acceso($1::integer)', [usuario.id_usuario]);

    const token = jwt.sign(
  {
    id_usuario: usuario.id_usuario,
    id_persona: usuario.id_persona,
    username: usuario.username,
    tipo_usuario: usuario.tipo_usuario,
    id_rol_acceso: usuario.id_rol_acceso,
    rol_acceso: usuario.rol_acceso,
  },
  process.env.JWT_SECRET as string,
  { expiresIn: '8h' }
);

res.json({
  token,
  usuario: {
    id_usuario: usuario.id_usuario,
    username: usuario.username,
    nombre: usuario.nombre_completo,
    tipo_usuario: usuario.tipo_usuario,
    rol_acceso: usuario.rol_acceso,
  },
});
  } catch (err) {
    responderError(res, err);
  }
});

// POST /api/auth/cambiar-password
router.post('/cambiar-password', requireAuth, async (req: AuthRequest, res) => {
  try {
    const { password_actual, password_nueva } = req.body;
    if (!password_actual || !password_nueva) {
      res.status(400).json({ error: 'Falta la contraseña actual o la nueva' });
      return;
    }
    if (String(password_nueva).length < 8) {
      res.status(400).json({ error: 'La contraseña nueva debe tener al menos 8 caracteres' });
      return;
    }
    if (password_actual === password_nueva) {
      res.status(400).json({ error: 'La contraseña nueva debe ser distinta a la actual' });
      return;
    }

    const busqueda = await pool.query('SELECT * FROM fn_buscar_usuario_login($1)', [req.usuario!.username]);
    const usuario = busqueda.rows[0];
    const coincide = usuario && (await bcrypt.compare(password_actual, usuario.password_hash));
    if (!coincide) {
      res.status(400).json({ error: 'La contraseña actual no es correcta' });
      return;
    }

    const hash = await bcrypt.hash(password_nueva, 10);
    await pool.query('CALL sp_cambiar_password($1::integer, $2::varchar)', [req.usuario!.id_usuario, hash]);
    res.json({ ok: true });
  } catch (err) {
    responderError(res, err);
  }
});

// GET /api/auth/me
router.get('/me', requireAuth, (req: AuthRequest, res) => {
  res.json({ username: req.usuario!.username, rol_acceso: req.usuario!.rol_acceso });
});
export default router;