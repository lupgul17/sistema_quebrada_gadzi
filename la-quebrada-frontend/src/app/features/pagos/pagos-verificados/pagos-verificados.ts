import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { TableModule } from 'primeng/table';
import { API_URL } from '../../../core/api-config';
import { Button } from 'primeng/button';
import {VisorArchivoService} from "../../../core/visor-archivo.service";

interface PagoVerificado {
  id_pago: number;
  id_evento: number;
  cliente: string;
  fecha_evento: string;
  fecha_pago: string;
  monto: number;
  tipo_pago: string;
  concepto: string;
  origen: string;
  path_comprobante: string | null;
  verifico: string | null;
}

@Component({
  selector: 'app-pagos-verificados',
  standalone: true,
  imports: [CommonModule, TableModule, Button],
  templateUrl: './pagos-verificados.html',
  styleUrl: './pagos-verificados.scss',
})
export class PagosVerificados implements OnInit {
  readonly pagos = signal<PagoVerificado[]>([]);
  readonly cargando = signal(true);

  constructor(
    private http: HttpClient,
    private router: Router,
    private visor: VisorArchivoService
  ) {}

  ngOnInit(): void {
    this.http.get<PagoVerificado[]>(`${API_URL}/pagos/verificados`).subscribe((data) => {
      this.pagos.set(data);
      this.cargando.set(false);
    });
  }

  verComprobante(path: string): void {
    this.visor.abrir(`${API_URL}/pagos/comprobante/${path}`, 'Comprobante de pago');
  }

  irAEvento(idEvento: number): void {
    this.router.navigate(['/eventos', idEvento]);
  }
}