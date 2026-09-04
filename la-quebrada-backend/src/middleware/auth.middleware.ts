import type { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

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
}

export function requireAuth(req: AuthRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Token no proporcionado' });
    return;
  }

  const token = authHeader.slice('Bearer '.length);

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET as string);
    req.usuario = payload as UsuarioToken;
    next();
  } catch {
    res.status(401).json({ error: 'Token inválido o expirado' });
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