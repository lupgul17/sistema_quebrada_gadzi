import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { MessageService } from 'primeng/api';
import { AuthService } from './auth.service';
import { SIN_TOAST_ERROR, mensajeDeError } from './http-errores';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const messageService = inject(MessageService);
  const token = authService.getToken();

  if (token) {
    req = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` },
    });
  }

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        // Sesión vencida o cuenta desactivada: se vuelve al login, sin toast
        authService.logout();
        return throwError(() => error);
      }

      // Red de seguridad: ninguna petición falla en silencio.
      // El login y los formularios que muestran el error en línea quedan afuera.
      const omitir = req.context.get(SIN_TOAST_ERROR) || req.url.includes('/auth/login');
      if (!omitir) {
        messageService.add({
          severity: error.status === 403 ? 'warn' : 'error',
          summary: error.status === 403 ? 'Sin permiso' : 'No se pudo completar',
          detail: mensajeDeError(error),
          life: 6000,
        });
      }
      return throwError(() => error);
    })
  );
};
