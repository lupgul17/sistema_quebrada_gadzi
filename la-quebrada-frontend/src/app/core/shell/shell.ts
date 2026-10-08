import { Component, HostListener, OnDestroy, computed, effect, signal } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive, Router, NavigationEnd } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { filter, map, startWith } from 'rxjs';
import { Menu } from 'primeng/menu';
import { MenuItem } from 'primeng/api';
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
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Menu, VisorArchivoDialog, InactividadDialog,CambiarPasswordDialog],
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
})
export class Shell implements OnDestroy {
  readonly usuario;
  private readonly rutaActual;
  readonly tituloPagina;
  /** Menú lateral abierto (solo aplica en celular; en pantallas grandes siempre se ve). */
  readonly menuAbierto = signal(false);

  /** Usuario solo de GADZI: el menú lateral lleva el logo de GADZI. */
  readonly esGadzi = computed(() => this.authService.usuario()?.logo === 'logo-gadzi.png');
  readonly logoMarca = computed(() => {
    const oscuro = this.temaService.oscuro();
    if (this.esGadzi()) return oscuro ? '/brand/logo-gadzi-claro.png' : '/brand/logo-gadzi.png';
    return oscuro ? '/brand/logo-claro.png' : '/brand/logo.png';
  });

  /** Iniciales para el avatar del menú de usuario (ej. "Ana Admin" → "AA"). */
  readonly iniciales = computed(() =>
    (this.authService.usuario()?.nombre ?? '?')
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((p) => p[0].toUpperCase())
      .join('')
  );

  /** Opciones del menú de usuario; computed para que el texto del tema cambie al alternarlo. */
  readonly opcionesUsuario = computed<MenuItem[]>(() => [
    {
      label: this.temaService.oscuro() ? 'Modo claro' : 'Modo oscuro',
      icon: this.temaService.oscuro() ? 'pi pi-sun' : 'pi pi-moon',
      command: () => this.temaService.alternar(),
    },
    { label: 'Cambiar contraseña', icon: 'pi pi-key', command: () => this.abrirCambiarPassword() },
    { separator: true },
    { label: 'Cerrar sesión', icon: 'pi pi-sign-out', command: () => this.logout() },
  ]);

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

    // Al navegar se cierra el menú del celular
    effect(() => {
      this.rutaActual();
      this.menuAbierto.set(false);
    });

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
@HostListener('document:keydown.escape')
cerrarMenu(): void {
  this.menuAbierto.set(false);
}

abrirCambiarPassword(): void {
  this.cambiarPasswordDialog.abrir();
}
  // El shell se destruye al salir del sistema por cualquier motivo (botón, inactividad o token vencido).
  // Sin esto, el temporizador seguía corriendo en el login y al volver a entrar no se reiniciaba.
  ngOnDestroy(): void {
    this.inactividadService.detener();
  }

  logout(): void {
    this.authService.logout();
  }

 
}