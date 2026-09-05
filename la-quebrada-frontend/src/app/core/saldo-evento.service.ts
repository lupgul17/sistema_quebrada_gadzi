import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { API_URL } from './api-config';

interface Saldo {
  total_a_pagar: number;
  total_pagado: number;
  saldo_pendiente: number;
  porcentaje_pagado: number;
}

@Injectable({ providedIn: 'root' })
export class SaldoEventoService {
  readonly saldo = signal<Saldo | null>(null);

  constructor(private http: HttpClient) {}

  actualizar(idEvento: number): void {
    this.http.get<Saldo>(`${API_URL}/eventos/${idEvento}/saldo`).subscribe((data) => {
      this.saldo.set(data);
    });
  }
}