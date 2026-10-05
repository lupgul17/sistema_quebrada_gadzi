import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';
import { Capacidad } from './permisos';

export const permisoGuard = (capacidad: Capacidad): CanActivateFn => () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return auth.puede(capacidad) ? true : router.createUrlTree(['/']);
};