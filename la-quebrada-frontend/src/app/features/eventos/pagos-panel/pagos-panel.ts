import { Component, Input, OnInit, signal, ElementRef, ViewChild } from '@angular/core';
import { CommonModule, DecimalPipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Select } from 'primeng/select';
import { InputNumber } from 'primeng/inputnumber';
import { DatePicker } from 'primeng/datepicker';
import { Textarea } from 'primeng/textarea';
import { Button } from 'primeng/button';
import { API_URL } from '../../../core/api-config';
import {VisorArchivoService} from "../../../core/visor-archivo.service";



interface Saldo {
  total_a_pagar: number;
  total_pagado: number;
  saldo_pendiente: number;
  porcentaje_pagado: number;
}

interface Pago {
  id_pago: number;
  fecha_pago: string;
  monto: number;
  tipo_pago: string;
  concepto: string;
  estado: string;
  origen: string;
  empleado: string | null;
  path_comprobante: string | null;
  motivo_rechazo: string | null;
  notas: string | null;
}

interface TipoPagoOpcion {
  id_tipo_pago: number;
  descripcion: string;
}

const CONCEPTOS = [
  { label: 'Reserva', value: 'reserva' },
  { label: 'Abono', value: 'abono' },
  { label: 'Saldo', value: 'saldo' },
  { label: 'Recargo', value: 'recargo' },
];

@Component({
  selector: 'app-pagos-panel',
  standalone: true,
  imports: [CommonModule, DecimalPipe, FormsModule, Select, InputNumber, DatePicker, Textarea, Button],
  templateUrl: './pagos-panel.html',
  styleUrl: './pagos-panel.scss',
})
export class PagosPanel implements OnInit {
  @Input({ required: true }) idEvento!: number;
  @ViewChild('inputArchivo') inputArchivo!: ElementRef<HTMLInputElement>;

  readonly saldo = signal<Saldo | null>(null);
  readonly pagos = signal<Pago[]>([]);
  readonly tiposPago = signal<TipoPagoOpcion[]>([]);
  readonly cargando = signal(true);
  readonly registrando = signal(false);
  readonly conceptos = CONCEPTOS;
  archivoComprobante: File | null = null;

  //modal de vista de pagos 

  pagoForm = {
    fecha_pago: new Date(),
    monto: null as number | null,
    id_tipo_pago: null as number | null,
    concepto: 'abono',
    notas: '',
  };

  constructor(private http: HttpClient, public visor: VisorArchivoService) {}

  ngOnInit(): void {
    this.http.get<TipoPagoOpcion[]>(`${API_URL}/catalogos/tipos-pago`).subscribe((data) => this.tiposPago.set(data));
    this.cargarTodo();
  }

 

abrirSelectorArchivo(): void {
  this.inputArchivo.nativeElement.click();
}
  cargarTodo(): void {
    this.cargando.set(true);
    this.http.get<Saldo>(`${API_URL}/eventos/${this.idEvento}/saldo`).subscribe((data) => this.saldo.set(data));
    this.http.get<Pago[]>(`${API_URL}/eventos/${this.idEvento}/pagos`).subscribe((data) => {
      this.pagos.set(data);
      this.cargando.set(false);
    });
  }

  private formatearFecha(fecha: Date): string {
    return fecha.toISOString().split('T')[0];
  }

  onArchivoSeleccionado(event: Event): void {
  const input = event.target as HTMLInputElement;
  this.archivoComprobante = input.files?.[0] ?? null;
}
urlComprobante(path: string): string {
  return `${API_URL}/pagos/comprobante/${path}`;
}
verComprobante(path: string): void {
  this.visor.abrir(`${API_URL}/pagos/comprobante/${path}`, 'Comprobante de pago');
}

registrarPago(): void {
  if (!this.pagoForm.monto || !this.pagoForm.id_tipo_pago) return;
  this.registrando.set(true);

  const formData = new FormData();
  formData.append('id_evento', this.idEvento.toString());
  formData.append('fecha_pago', this.formatearFecha(this.pagoForm.fecha_pago));
  formData.append('monto', this.pagoForm.monto.toString());
  formData.append('id_tipo_pago', this.pagoForm.id_tipo_pago.toString());
  formData.append('concepto', this.pagoForm.concepto);
  formData.append('origen', 'staff');
  if (this.pagoForm.notas) formData.append('notas', this.pagoForm.notas);
  if (this.archivoComprobante) formData.append('comprobante', this.archivoComprobante);

  this.http.post(`${API_URL}/pagos`, formData).subscribe(() => {
    this.registrando.set(false);
    this.pagoForm = { fecha_pago: new Date(), monto: null, id_tipo_pago: null, concepto: 'abono', notas: '' };
    this.archivoComprobante = null;
    this.cargarTodo();
  });
}
}