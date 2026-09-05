import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { API_URL } from './api-config';

@Injectable({ providedIn: 'root' })
export class PagosPendientesService {
  readonly count = signal(0);

  constructor(private http: HttpClient) {}

  actualizar(): void {
    this.http.get<any[]>(`${API_URL}/pagos/pendientes`).subscribe((data) => {
      this.count.set(data.length);
    });
  }
}