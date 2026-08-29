import { Component, computed } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive, Router, NavigationEnd } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { filter, map, startWith } from 'rxjs';
import { Button } from 'primeng/button';
import { AuthService } from '../auth.service';

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Button],
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
})
export class Shell {
  readonly usuario;
  private readonly rutaActual;
  readonly tituloPagina;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {
    this.usuario = this.authService.usuario;

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
      return '';
    });
  }

  logout(): void {
    this.authService.logout();
  }
}