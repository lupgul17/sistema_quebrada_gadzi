import type { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface UsuarioToken {
  id_usuario: number;
  id_persona: number;
  username: string;
  tipo_usuario: string;
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