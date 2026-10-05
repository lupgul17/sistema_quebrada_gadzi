import { Injectable, effect, signal } from '@angular/core';

const CLAVE_TEMA = 'lq-tema';
const CLASE_OSCURO = 'app-dark';

/** Maneja el modo claro/oscuro: clase `app-dark` en <html> + preferencia en localStorage. */
@Injectable({ providedIn: 'root' })
export class TemaService {
  readonly oscuro = signal(this.leerPreferencia());

  constructor() {
    effect(() => {
      const oscuro = this.oscuro();
      document.documentElement.classList.toggle(CLASE_OSCURO, oscuro);
      try {
        localStorage.setItem(CLAVE_TEMA, oscuro ? 'oscuro' : 'claro');
      } catch {
        // almacenamiento no disponible: el tema solo dura la sesión
      }
    });
  }

  alternar(): void {
    this.oscuro.update((v) => !v);
  }

  /** Claro por defecto (imagen de marca); oscuro solo si el usuario lo eligió. */
  private leerPreferencia(): boolean {
    try {
      return localStorage.getItem(CLAVE_TEMA) === 'oscuro';
    } catch {
      return false;
    }
  }
}
