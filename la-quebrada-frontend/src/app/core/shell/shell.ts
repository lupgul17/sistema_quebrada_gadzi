import { Component, computed,signal } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive, Router, NavigationEnd } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { filter, map, startWith } from 'rxjs';
import { Button } from 'primeng/button';
import { Tooltip } from 'primeng/tooltip';
import { AuthService } from '../auth.service';
import {VisorArchivoDialog} from '../visor-archivo-dialog/visor-archivo-dialog';
import { PagosPendientesService } from '../pagos-pendientes.service';
import { ProspectosPendientesService } from '../prospectos-pendientes.service';
import { HttpClient } from '@angular/common/http';
import { API_URL } from '../api-config';
import { InactividadDialog } from '../inactividad-dialog/inactividad-dialog';
import { InactividadService } from '../inactividad.service';
import { TemaService } from '../tema.service';
import { ViewChild } from '@angular/core';   // sumalo al import de '@angular/core' que ya tenés
import { CambiarPasswordDialog } from '../cambiar-password-dialog/cambiar-password-dialog';

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Button, Tooltip, VisorArchivoDialog, InactividadDialog,CambiarPasswordDialog],
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
})
export class Shell {
  readonly usuario;
  private readonly rutaActual;
  readonly tituloPagina;

   @ViewChild('cambiarPasswordDialog') cambiarPasswordDialog!: CambiarPasswordDialog;



  constructor(
    public authService: AuthService,
    private router: Router,
    public pagosPendientesService: PagosPendientesService,
    public prospectosPendientesService: ProspectosPendientesService,
    private inactividadService: InactividadService,
    
    public temaService: TemaService,

  ) {
    this.usuario = this.authService.usuario;
    this.pagosPendientesService.actualizar();
    this.prospectosPendientesService.actualizar();
    this.inactividadService.iniciar();
    this.authService.refrescarPerfil();


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
      if (ruta?.startsWith('/reportes')) return 'Reportes';
      if (ruta?.startsWith('/prospectos')) return 'Solicitudes web';
      if (ruta?.startsWith('/usuarios')) return 'Usuarios';
      return '';
    });
  }
abrirCambiarPassword(): void {
  this.cambiarPasswordDialog.abrir();
}
  logout(): void {
    this.authService.logout();
  }

 
}