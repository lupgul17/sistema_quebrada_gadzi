import type { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { pool } from '../db/pool.js';

export interface UsuarioToken {
  id_usuario: number;
  id_persona: number;
  username: string;
  tipo_usuario: string;
  id_rol_acceso: number | null;
  rol_acceso: string | null;
}

export interface AuthRequest extends Request {
  usuario?: UsuarioToken;
  authCargado?: boolean;
}

export async function requireAuth(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
  if (req.authCargado || req.method === 'OPTIONS') return next();
  if (req.originalUrl.split('?')[0] === '/api/auth/login') return next();

  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'No autenticado' });
    return;
  }

  let payload: { id_usuario: number; tipo_usuario?: string };
  try {
    payload = jwt.verify(header.slice(7), process.env.JWT_SECRET as string) as typeof payload;
  } catch {
    res.status(401).json({ error: 'Token inválido o expirado' });
    return;
  }

  try {
    const result = await pool.query('SELECT * FROM fn_usuario_auth($1::integer)', [payload.id_usuario]);
    const u = result.rows[0];

    if (!u || !u.activo || !u.confirmacion) {
      res.status(401).json({ error: 'Cuenta inexistente o desactivada' });
      return;
    }
    if (!u.id_rol_acceso) {
      res.status(401).json({ error: 'Tu cuenta no tiene un rol asignado' });
      return;
    }

    req.usuario = {
      id_usuario: u.id_usuario,
      id_persona: u.id_persona,
      username: u.username,
      tipo_usuario: payload.tipo_usuario ?? 'staff',
      id_rol_acceso: u.id_rol_acceso,
      rol_acceso: u.rol_acceso,
    };
    req.authCargado = true;
    next();
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
}

export function requireRole(...rolesPermitidos: string[]) {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    const rolUsuario = req.usuario?.rol_acceso?.toLowerCase();
    if (!rolUsuario || !rolesPermitidos.map((r) => r.toLowerCase()).includes(rolUsuario)) {
      res.status(403).json({ error: 'No tenés permiso para acceder a esto' });
      return;
    }
    next();
  };
}