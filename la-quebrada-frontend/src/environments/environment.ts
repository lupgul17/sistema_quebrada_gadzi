// Producción (Railway): el mismo servicio del frontend (Caddy) reenvía /api al backend,
// así que la API está en el mismo dominio y no hace falta poner su URL acá.
export const environment = {
  production: true,
  apiUrl: '/api',
};
