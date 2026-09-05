import { Component, computed,signal } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive, Router, NavigationEnd } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { filter, map, startWith } from 'rxjs';
import { Button } from 'primeng/button';
import { AuthService } from '../auth.service';
import {VisorArchivoDialog} from '../visor-archivo-dialog/visor-archivo-dialog';
import { PagosPendientesService } from '../pagos-pendientes.service';
import { HttpClient } from '@angular/common/http';
import { API_URL } from '../api-config';

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Button, VisorArchivoDialog],
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
})
export class Shell {
  readonly usuario;
  private readonly rutaActual;
  readonly tituloPagina;

  constructor(
    private authService: AuthService,
    private router: Router,
    public pagosPendientesService: PagosPendientesService,

  ) {
    this.usuario = this.authService.usuario;
    this.pagosPendientesService.actualizar();

    this.rutaActual = toSignal(
      this.router.events.pipe(
        filter((e) => e instanceof NavigationEnd),
        map((e) => (e as NavigationEnd).urlAfterRedirects),
        startWith(this.router.url)
      )
    );

    this.tituloPagina = computed(() => {
      const ruta = this.rutaActual();
      if (ruta === '/') return 'Inicio';
      if (ruta?.startsWith('/clientes')) return 'Clientes';
      if (ruta?.startsWith('/eventos')) return 'Eventos';
      if (ruta?.startsWith('/servicios')) return 'Servicios';
      if (ruta?.startsWith('/menu')) return 'Menú';
      if (ruta?.startsWith('/pagos')) return 'Pagos';
      if (ruta?.startsWith('/degustaciones')) return 'Degustaciones';
      return '';
    });
  }

  logout(): void {
    this.authService.logout();
  }
}