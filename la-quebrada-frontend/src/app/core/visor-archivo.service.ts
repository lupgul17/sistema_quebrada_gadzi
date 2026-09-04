import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({ providedIn: 'root' })
export class VisorArchivoService {
  readonly visible = signal(false);
  readonly cargando = signal(false);
  readonly url = signal<string | null>(null);
  readonly esPdf = signal(false);
  readonly titulo = signal('Archivo');

  constructor(private http: HttpClient) {}

  abrir(urlBackend: string, titulo = 'Archivo'): void {
    this.titulo.set(titulo);
    this.esPdf.set(urlBackend.toLowerCase().endsWith('.pdf'));
    this.visible.set(true);
    this.cargando.set(true);
    this.http.get(urlBackend, { responseType: 'blob' }).subscribe((blob) => {
      this.url.set(URL.createObjectURL(blob));
      this.cargando.set(false);
    });
  }

  cerrar(): void {
    this.visible.set(false);
    const actual = this.url();
    if (actual) URL.revokeObjectURL(actual);
    this.url.set(null);
  }
}