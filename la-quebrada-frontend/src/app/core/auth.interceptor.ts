import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { AuthService } from './auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.getToken();

  if (token) {
    req = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` },
    });
  }

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        authService.logout();
      }
      // Red de seguridad: con los botones escondidos esto casi no debería verse.
      // El login queda afuera porque ya muestra su propio mensaje.
      if (error.status === 403 && !req.url.includes('/auth/login')) {
        alert(error.error?.error ?? 'No tenés permiso para esta acción.');
      }
      return throwError(() => error);
    })
  );
};