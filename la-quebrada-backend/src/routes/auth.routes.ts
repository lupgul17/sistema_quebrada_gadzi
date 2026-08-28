import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db/pool.js';

const router = Router();

router.post('/login', async (req, res) => {
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

    await pool.query('CALL sp_registrar_acceso($1::integer)', [usuario.id_usuario]);

    const token = jwt.sign(
      {
        id_usuario: usuario.id_usuario,
        id_persona: usuario.id_persona,
        username: usuario.username,
        tipo_usuario: usuario.tipo_usuario,
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
      },
    });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

export default router;