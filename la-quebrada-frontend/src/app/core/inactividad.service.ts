import { Injectable, signal, NgZone } from '@angular/core';
import { AuthService } from './auth.service';

const MINUTOS_INACTIVIDAD = 1;
const SEGUNDOS_AVISO = 60;
const EVENTOS_ACTIVIDAD = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'];

@Injectable({ providedIn: 'root' })
export class InactividadService {
  readonly mostrandoAviso = signal(false);
  readonly segundosRestantes = signal(SEGUNDOS_AVISO);

  private timerInactividad: ReturnType<typeof setTimeout> | null = null;
  private intervalAviso: ReturnType<typeof setInterval> | null = null;
  private activo = false;

  constructor(
    private authService: AuthService,
    private ngZone: NgZone
  ) {}

  iniciar(): void {
    if (this.activo) return;
    this.activo = true;
    EVENTOS_ACTIVIDAD.forEach((evento) => {
      document.addEventListener(evento, this.onActividad, { passive: true });
    });
    this.reiniciarTimer();
  }

  detener(): void {
    this.activo = false;
    EVENTOS_ACTIVIDAD.forEach((evento) => {
      document.removeEventListener(evento, this.onActividad);
    });
    this.limpiarTimers();
  }

  private onActividad = (): void => {
    if (this.mostrandoAviso()) return;
    this.reiniciarTimer();
  };

  private reiniciarTimer(): void {
    this.limpiarTimers();
    this.ngZone.runOutsideAngular(() => {
      this.timerInactividad = setTimeout(() => {
        this.ngZone.run(() => this.mostrarAviso());
      }, MINUTOS_INACTIVIDAD * 60 * 1000);
    });
  }

  private mostrarAviso(): void {
    this.mostrandoAviso.set(true);
    this.segundosRestantes.set(SEGUNDOS_AVISO);

    this.ngZone.runOutsideAngular(() => {
      this.intervalAviso = setInterval(() => {
        this.ngZone.run(() => {
          const restante = this.segundosRestantes() - 1;
          this.segundosRestantes.set(restante);
          if (restante <= 0) {
            this.cerrarPorInactividad();
          }
        });
      }, 1000);
    });
  }

  seguirActivo(): void {
    this.mostrandoAviso.set(false);
    this.reiniciarTimer();
  }

  private cerrarPorInactividad(): void {
    this.limpiarTimers();
    this.mostrandoAviso.set(false);
    this.authService.logout();
  }

  private limpiarTimers(): void {
    if (this.timerInactividad) clearTimeout(this.timerInactividad);
    if (this.intervalAviso) clearInterval(this.intervalAviso);
    this.timerInactividad = null;
    this.intervalAviso = null;
  }
}