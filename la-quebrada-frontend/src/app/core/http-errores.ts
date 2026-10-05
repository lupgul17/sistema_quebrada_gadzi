import { HttpContext, HttpContextToken, HttpErrorResponse } from '@angular/common/http';

/**
 * Por defecto el interceptor muestra un toast con cualquier error HTTP.
 * Las pantallas que ya muestran el error dentro del formulario pasan esta opción
 * para no repetir el mensaje dos veces.
 */
export const SIN_TOAST_ERROR = new HttpContextToken<boolean>(() => false);

/** Opciones para pasar a http.post/put/patch cuando el error se muestra en el propio formulario. */
export const ERROR_EN_LINEA = { context: new HttpContext().set(SIN_TOAST_ERROR, true) };

/** Mensaje legible de un error HTTP (el backend manda { error: '...' }). */
export function mensajeDeError(error: HttpErrorResponse): string {
  if (error.status === 0) return 'No hay conexión con el servidor. Revisá tu internet e intentá de nuevo.';
  const cuerpo = error.error;
  if (cuerpo && typeof cuerpo === 'object' && !(cuerpo instanceof Blob) && typeof cuerpo.error === 'string') {
    return cuerpo.error;
  }
  if (error.status >= 500) return 'Ocurrió un error en el servidor. Intentá de nuevo en un momento.';
  return 'No se pudo completar la acción.';
}
