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
        path: 'clientes/:id',
        loadComponent: () => import('./features/clientes/cliente-detail/cliente-detail').then((m) => m.ClienteDetail),
      },
      {
        path: 'eventos',
        loadComponent: () => import('./features/eventos/eventos-list/eventos-list').then((m) => m.EventosList),
      },
      {
        path: 'eventos/:id',
        loadComponent: () => import('./features/eventos/evento-detail/evento-detail').then((m) => m.EventoDetail),
      },
      {
        path: 'servicios',
        loadComponent: () => import('./features/servicios/servicios-list/servicios-list').then((m) => m.ServiciosList),
      },
      {
      path: 'menu',
      loadComponent: () => import('./features/menu/menu-page/menu-page').then((m) => m.MenuPage),
      },
      {
        path: 'pagos',
        loadComponent: () => import('./features/pagos/pagos-page/pagos-page').then((m) => m.PagosPage),
      },
      {
        path: 'degustaciones',
        loadComponent: () => import('./features/degustaciones/fechas-degustacion-list/fechas-degustacion-list').then((m) => m.FechasDegustacionList),
      },
      {
        path: 'reportes',
        loadComponent: () => import('./features/reportes/reportes-page/reportes-page').then((m) => m.ReportesPage),
      },
            
    ],
  },
  { path: '**', redirectTo: '' },
];