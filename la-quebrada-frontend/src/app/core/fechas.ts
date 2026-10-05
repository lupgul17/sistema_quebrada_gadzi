/**
 * Fecha en formato YYYY-MM-DD según la hora LOCAL (Guatemala).
 *
 * No usar `toISOString()` para esto: convierte a UTC, y en Guatemala (UTC-6)
 * desde las 6 PM ya devuelve el día siguiente.
 */
export function fechaLocalISO(fecha: Date = new Date()): string {
  const anio = fecha.getFullYear();
  const mes = String(fecha.getMonth() + 1).padStart(2, '0');
  const dia = String(fecha.getDate()).padStart(2, '0');
  return `${anio}-${mes}-${dia}`;
}
