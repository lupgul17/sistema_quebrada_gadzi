import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { API_URL } from './api-config';

/** Cantidad de solicitudes nuevas de la landing, para el badge del sidebar. */
@Injectable({ providedIn: 'root' })
export class ProspectosPendientesService {
  readonly count = signal(0);

  constructor(private http: HttpClient) {}

  actualizar(): void {
    this.http.get<{ count: number }>(`${API_URL}/prospectos/pendientes/count`).subscribe({
      next: (data) => this.count.set(data.count),
      error: () => this.count.set(0),
    });
  }
}
