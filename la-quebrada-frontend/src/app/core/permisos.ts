export type Capacidad =
  | 'reportes' | 'usuarios' | 'catalogos' | 'menus'
  | 'clientes' | 'eventos'
  | 'cotizaciones' | 'descuentos'
  | 'degustaciones' | 'fechasDegustacion'
  | 'extras' | 'pagosRegistrar' | 'pagosVerificar' | 'prospectos';

// Espejo de src/middleware/permisos.ts del backend: si cambia uno, cambia el otro.
// El backend es el que manda; esto solo decide qué se muestra en pantalla.
export const PERMISOS: Record<Capacidad, string[]> = {
  reportes: ['Administrador', 'Administrador2', 'Superusuario'],
  usuarios: ['Superusuario'],
  catalogos: ['Administrador', 'Superusuario'],
  menus: ['Secretaria', 'Administrador', 'Superusuario'],
  clientes: ['Vendedor', 'Administrador', 'Superusuario'],
  eventos: ['Vendedor', 'Administrador', 'Superusuario'],
  cotizaciones: ['Vendedor', 'Secretaria', 'Administrador', 'Superusuario'],
  descuentos: ['Administrador', 'Superusuario'],
  degustaciones: ['Vendedor', 'Secretaria', 'Administrador', 'Superusuario'],
  fechasDegustacion: ['Secretaria', 'Administrador', 'Superusuario'],
  extras: ['Vendedor', 'Administrador', 'Superusuario'],
  pagosRegistrar: ['Vendedor', 'Administrador', 'Superusuario'],
  pagosVerificar: ['Revisor', 'Administrador', 'Superusuario'],
  prospectos: ['Vendedor', 'Secretaria', 'Administrador', 'Superusuario'],
};