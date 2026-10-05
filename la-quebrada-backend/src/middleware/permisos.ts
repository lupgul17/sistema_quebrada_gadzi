import type { Response, NextFunction } from 'express';
import type { AuthRequest } from './auth.middleware.js';

interface Regla {
  metodos: string[];
  ruta: RegExp;
  roles: string[]; // ['*'] = cualquier usuario con sesión
}

const ESCRITURA = ['POST', 'PUT', 'PATCH', 'DELETE'];

// La primera regla que coincide gana. El orden importa: lo más específico va primero.
const REGLAS: Regla[] = [
  { metodos: ['*'], ruta: /^\/auth(\/|$)/, roles: ['*'] },
  { metodos: ['*'], ruta: /^\/usuarios(\/|$)/, roles: ['Superusuario'] },
  { metodos: ['*'], ruta: /^\/recordatorios(\/|$)/, roles: ['Administrador', 'Superusuario'] },
  { metodos: ['GET'], ruta: /^\/reportes(\/|$)/, roles: ['Administrador', 'Administrador2', 'Superusuario'] },

  { metodos: ESCRITURA, ruta: /^\/cotizaciones\/descuentos(\/|$)/, roles: ['Administrador', 'Superusuario'] },
  { metodos: ESCRITURA, ruta: /^\/cotizaciones(\/|$)/, roles: ['Vendedor', 'Secretaria', 'Administrador', 'Superusuario'] },

  { metodos: ESCRITURA, ruta: /^\/pagos\/\d+\/verificar(\/|$)/, roles: ['Revisor', 'Administrador', 'Superusuario'] },
  { metodos: ESCRITURA, ruta: /^\/pagos(\/|$)/, roles: ['Vendedor', 'Administrador', 'Superusuario'] },

  { metodos: ESCRITURA, ruta: /^\/degustaciones\/fechas(\/|$)/, roles: ['Secretaria', 'Administrador', 'Superusuario'] },
  { metodos: ESCRITURA, ruta: /^\/degustaciones(\/|$)/, roles: ['Vendedor', 'Secretaria', 'Administrador', 'Superusuario'] },

  { metodos: ESCRITURA, ruta: /^\/extras(\/|$)/, roles: ['Vendedor', 'Administrador', 'Superusuario'] },
  { metodos: ESCRITURA, ruta: /^\/menus(\/|$)/, roles: ['Secretaria', 'Administrador', 'Superusuario'] },
  { metodos: ESCRITURA, ruta: /^\/(servicios|componentes-menu)(\/|$)/, roles: ['Administrador', 'Superusuario'] },
  { metodos: ESCRITURA, ruta: /^\/prospectos(\/|$)/, roles: ['Vendedor', 'Secretaria', 'Administrador', 'Superusuario'] },
  { metodos: ESCRITURA, ruta: /^\/clientes(\/|$)/, roles: ['Vendedor', 'Administrador', 'Superusuario'] },
  { metodos: ESCRITURA, ruta: /^\/eventos(\/|$)/, roles: ['Vendedor', 'Administrador', 'Superusuario'] },
];

export function aplicarPermisos(req: AuthRequest, res: Response, next: NextFunction): void {
  if (req.method === 'OPTIONS') return next();

  // Express no distingue mayúsculas en las rutas, así que se normaliza antes de comparar
  const ruta = req.originalUrl.split('?')[0].toLowerCase().replace(/^\/api/, '');
  if (ruta === '/auth/login') return next();

  const rol = req.usuario?.rol_acceso?.toLowerCase();
  if (!rol) {
    res.status(401).json({ error: 'Sesión inválida' });
    return;
  }

  // HEAD ejecuta las rutas GET, así que se evalúa exactamente igual que GET
  const metodo = req.method === 'HEAD' ? 'GET' : req.method;

  const regla = REGLAS.find((r) => (r.metodos.includes('*') || r.metodos.includes(metodo)) && r.ruta.test(ruta));
  const permitido = regla
    ? regla.roles.includes('*') || regla.roles.some((x) => x.toLowerCase() === rol)
    : metodo === 'GET';

  if (!permitido) {
    res.status(403).json({ error: `Tu rol (${req.usuario!.rol_acceso}) no tiene permiso para esta acción.` });
    return;
  }
  next();
}