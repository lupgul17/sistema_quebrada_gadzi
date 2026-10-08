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
import { AuthService } from '../../../core/auth.service';
import {VisorArchivoService} from "../../../core/visor-archivo.service";
import { SaldoEventoService } from '../../../core/saldo-evento.service';
import { fechaLocalISO } from '../../../core/fechas';
import { MessageService } from 'primeng/api';

/** Lo mismo que acepta el servidor (config/upload.ts). */
const TIPOS_COMPROBANTE = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
const MAX_COMPROBANTE_MB = 5;



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
  /** Se intentó registrar: muestra los errores de los campos. */
  readonly intentoPago = signal(false);
  readonly hoy = new Date();
  readonly errorArchivo = signal<string | null>(null);

  //modal de vista de pagos 

  pagoForm = {
    fecha_pago: new Date(),
    monto: null as number | null,
    id_tipo_pago: null as number | null,
    concepto: 'abono',
    notas: '',
  };

  constructor(
    private http: HttpClient,
    public visor: VisorArchivoService,
    public saldoService: SaldoEventoService,
    public auth: AuthService,
    private messageService: MessageService
  ) {}

  ngOnInit(): void {
    this.http.get<TipoPagoOpcion[]>(`${API_URL}/catalogos/tipos-pago`).subscribe((data) => this.tiposPago.set(data));
    this.cargarTodo();
  }

 

abrirSelectorArchivo(): void {
  this.inputArchivo.nativeElement.click();
}
cargarTodo(): void {
  this.cargando.set(true);
  this.saldoService.actualizar(this.idEvento);
  this.http.get<Pago[]>(`${API_URL}/eventos/${this.idEvento}/pagos`).subscribe({ next: (data) => {
    this.pagos.set(data);
    this.cargando.set(false);
  }, error: () => this.cargando.set(false) });
}

  private formatearFecha(fecha: Date): string {
    return fechaLocalISO(fecha);
  }

  onArchivoSeleccionado(event: Event): void {
  const input = event.target as HTMLInputElement;
  const archivo = input.files?.[0] ?? null;
  input.value = ''; // permite volver a elegir el mismo archivo después de corregir
  this.errorArchivo.set(null);
  if (archivo && !TIPOS_COMPROBANTE.includes(archivo.type)) {
    this.errorArchivo.set('Solo imágenes (jpg, png, webp) o PDF.');
    return;
  }
  if (archivo && archivo.size > MAX_COMPROBANTE_MB * 1024 * 1024) {
    this.errorArchivo.set(`El archivo pesa más de ${MAX_COMPROBANTE_MB} MB.`);
    return;
  }
  this.archivoComprobante = archivo;
}

  /** Errores de cada campo del pago (vacío = se puede registrar). */
  erroresPago(): { fecha?: string; monto?: string; tipo?: string; notas?: string } {
    const f = this.pagoForm;
    const e: { fecha?: string; monto?: string; tipo?: string; notas?: string } = {};
    const finDeHoy = new Date();
    finDeHoy.setHours(23, 59, 59, 999);
    if (!f.fecha_pago) e.fecha = 'Elegí la fecha del pago.';
    else if (f.fecha_pago > finDeHoy) e.fecha = 'La fecha no puede ser futura.';
    if (!f.monto || f.monto <= 0) e.monto = 'El monto debe ser mayor a Q0.';
    else if (f.monto > 1_000_000) e.monto = 'El monto es demasiado grande; revisalo.';
    if (!f.id_tipo_pago) e.tipo = 'Elegí la forma de pago.';
    if ((f.notas ?? '').length > 500) e.notas = 'Máximo 500 caracteres.';
    return e;
  }

  /** Aviso (no bloquea): el monto pasa del saldo pendiente. Un recargo sí puede pasarlo. */
  avisoSaldo(): string | null {
    const saldo = this.saldoService.saldo();
    const monto = this.pagoForm.monto ?? 0;
    if (!saldo || this.pagoForm.concepto === 'recargo' || monto <= 0) return null;
    const pendiente = Number(saldo.saldo_pendiente);
    return monto > pendiente
      ? `El monto pasa del saldo pendiente (Q${pendiente.toFixed(2)}). Revisá que sea correcto.`
      : null;
  }
urlComprobante(path: string): string {
  return `${API_URL}/pagos/comprobante/${path}`;
}
verComprobante(path: string): void {
  this.visor.abrir(`${API_URL}/pagos/comprobante/${path}`, 'Comprobante de pago');
}

registrarPago(): void {
  this.intentoPago.set(true);
  if (Object.keys(this.erroresPago()).length || this.errorArchivo()) return;
  this.registrando.set(true);

  const formData = new FormData();
  formData.append('id_evento', this.idEvento.toString());
  formData.append('fecha_pago', this.formatearFecha(this.pagoForm.fecha_pago));
  formData.append('monto', String(this.pagoForm.monto));
  formData.append('id_tipo_pago', String(this.pagoForm.id_tipo_pago));
  formData.append('concepto', this.pagoForm.concepto);
  formData.append('origen', 'staff');
  if (this.pagoForm.notas?.trim()) formData.append('notas', this.pagoForm.notas.trim());
  if (this.archivoComprobante) formData.append('comprobante', this.archivoComprobante);

  this.http.post(`${API_URL}/pagos`, formData).subscribe({
    next: () => {
      this.registrando.set(false);
      this.intentoPago.set(false);
      this.pagoForm = { fecha_pago: new Date(), monto: null, id_tipo_pago: null, concepto: 'abono', notas: '' };
      this.archivoComprobante = null;
      this.messageService.add({ severity: 'success', summary: 'Pago registrado', life: 2500 });
      this.cargarTodo();
    },
    // Antes solo se manejaba el éxito: si fallaba, el botón quedaba cargando para siempre
    error: () => this.registrando.set(false),
  });
}
}