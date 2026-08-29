import { Routes } from '@angular/router';
import { Login } from './features/login/login';
import { Shell } from './core/shell/shell';
import { authGuard } from './core/auth.guard';

export const routes: Routes = [
  { path: 'login', component: Login },
  {
    path: '',
    component: Shell,
    canActivate: [authGuard],
    children: [
      {
        path: '',
        loadComponent: () => import('./features/home/home').then((m) => m.Home),
      },
      {
        path: 'clientes',
        loadComponent: () => import('./features/clientes/clientes-list/clientes-list').then((m) => m.ClientesList),
      },
     {
        path: 'clientes/nuevo',
        loadComponent: () => import('./features/clientes/cliente-form/cliente-form').then((m) => m.ClienteForm),
      },
      {
        path: 'clientes/:id',
        loadComponent: () => import('./features/clientes/cliente-detail/cliente-detail').then((m) => m.ClienteDetail),
      },
      {
        path: 'clientes/:id/editar',
        loadComponent: () => import('./features/clientes/cliente-form/cliente-form').then((m) => m.ClienteForm),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];