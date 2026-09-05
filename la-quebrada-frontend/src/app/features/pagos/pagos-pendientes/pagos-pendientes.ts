import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Button } from 'primeng/button';
import { API_URL } from '../../../core/api-config';
import {VisorArchivoService} from "../../../core/visor-archivo.service";
import { Dialog } from 'primeng/dialog';
import { Textarea } from 'primeng/textarea';
import { FormsModule } from '@angular/forms';
import { PagosPendientesService } from '../../../core/pagos-pendientes.service';

interface PagoPendiente {
  id_pago: number;
  id_evento: number;
  cliente: string;
  fecha_evento: string;
  fecha_pago: string;
  monto: number;
  tipo_pago: string;
  concepto: string;
  origen: string;
  path_comprobante: string;
  fecha_registro: string;
}

@Component({
  selector: 'app-pagos-pendientes',
  standalone: true,
  imports: [CommonModule, Button, Dialog, Textarea, FormsModule],
  templateUrl: './pagos-pendientes.html',
  styleUrl: './pagos-pendientes.scss',
})
export class PagosPendientes implements OnInit {
  readonly pagos = signal<PagoPendiente[]>([]);
  readonly cargando = signal(true);
  readonly procesandoId = signal<number | null>(null);
  readonly dialogoRechazoVisible = signal(false);
  readonly pagoARechazar = signal<PagoPendiente | null>(null);
  motivoRechazo = '';

  constructor(
    private http: HttpClient,
    private router: Router,
    private visor: VisorArchivoService,
    private pagosPendientesService: PagosPendientesService
  ) {}

  ngOnInit(): void {
    this.cargarPendientes();
  }

  verComprobante(path: string): void {
  this.visor.abrir(`${API_URL}/pagos/comprobante/${path}`, 'Comprobante de pago');
  }
  cargarPendientes(): void {
    this.cargando.set(true);
    this.http.get<PagoPendiente[]>(`${API_URL}/pagos/pendientes`).subscribe((data) => {
      this.pagos.set(data);
      this.cargando.set(false);
    });
  }

 resolver(idPago: number, estado: 'verificado' | 'rechazado'): void {
  if (estado === 'rechazado') {
    const pago = this.pagos().find((p) => p.id_pago === idPago);
    this.pagoARechazar.set(pago ?? null);
    this.motivoRechazo = '';
    this.dialogoRechazoVisible.set(true);
    return;
  }

  this.procesandoId.set(idPago);
  this.http.patch(`${API_URL}/pagos/${idPago}/verificar`, { estado }).subscribe(() => {
    this.procesandoId.set(null);
    this.cargarPendientes();
    this.pagosPendientesService.actualizar();
  });
}

confirmarRechazo(): void {
  const pago = this.pagoARechazar();
  if (!pago || !this.motivoRechazo.trim()) return;
  this.procesandoId.set(pago.id_pago);
  this.dialogoRechazoVisible.set(false);
  this.http.patch(`${API_URL}/pagos/${pago.id_pago}/verificar`, { estado: 'rechazado', motivo_rechazo: this.motivoRechazo }).subscribe(() => {
    this.procesandoId.set(null);
    this.cargarPendientes();
    this.pagosPendientesService.actualizar();
  });
}

  irAEvento(idEvento: number): void {
    this.router.navigate(['/eventos', idEvento]);
  }
}