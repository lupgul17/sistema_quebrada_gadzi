import { Component, ElementRef, EventEmitter, Output, ViewChild, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Dialog } from 'primeng/dialog';
import { Button } from 'primeng/button';
import { Select } from 'primeng/select';
import { InputNumber } from 'primeng/inputnumber';
import { DatePicker } from 'primeng/datepicker';
import { Textarea } from 'primeng/textarea';
import { Message } from 'primeng/message';
import { API_URL } from '../../../core/api-config';
import { ERROR_EN_LINEA } from '../../../core/http-errores';
import { fechaLocalISO } from '../../../core/fechas';

interface Confirmacion {
  abono_minimo: number;
  abonado: number;
  total_cotizacion: number | null;
}

interface TipoPago {
  id_tipo_pago: number;
  descripcion: string;
}

/** Lo mismo que acepta el servidor (config/upload.ts). */
const TIPOS_COMPROBANTE = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
const MAX_COMPROBANTE_MB = 5;

/**
 * Confirmar un evento = registrar el abono de reserva + confirmar, en una sola operación.
 * El abono queda pendiente de revisión como cualquier pago; el mínimo lo define la base
 * (Q10,000, o el total de la cotización si es menor).
 */
@Component({
  selector: 'app-confirmar-evento-dialog',
  standalone: true,
  imports: [CommonModule, FormsModule, Dialog, Button, Select, InputNumber, DatePicker, Textarea, Message],
  templateUrl: './confirmar-evento-dialog.html',
  styleUrl: './confirmar-evento-dialog.scss',
})
export class ConfirmarEventoDialog {
  @Output() confirmado = new EventEmitter<void>();
  @ViewChild('inputArchivo') inputArchivo?: ElementRef<HTMLInputElement>;

  readonly visible = signal(false);
  readonly guardando = signal(false);
  readonly error = signal<string | null>(null);
  readonly info = signal<Confirmacion | null>(null);
  readonly tiposPago = signal<TipoPago[]>([]);
  readonly intento = signal(false);
  readonly errorArchivo = signal<string | null>(null);
  /** Límite del calendario: el final de hoy (con la hora exacta, una fecha creada segundos después
   *  quedaba "en el futuro" y el calendario no la mostraba). */
  readonly hoy = (() => { const d = new Date(); d.setHours(23, 59, 59, 999); return d; })();

  private idEvento = 0;
  form = { fecha_pago: new Date(), monto: null as number | null, id_tipo_pago: null as number | null, notas: '' };
  archivo: File | null = null;

  constructor(private http: HttpClient) {}

  abrir(idEvento: number): void {
    this.idEvento = idEvento;
    this.form = { fecha_pago: new Date(), monto: null, id_tipo_pago: null, notas: '' };
    this.archivo = null;
    this.errorArchivo.set(null);
    this.error.set(null);
    this.intento.set(false);
    this.info.set(null);
    this.visible.set(true);
    if (!this.tiposPago().length) {
      this.http.get<TipoPago[]>(`${API_URL}/catalogos/tipos-pago`).subscribe((d) => this.tiposPago.set(d));
    }
    this.http.get<Confirmacion>(`${API_URL}/eventos/${idEvento}/confirmacion`).subscribe((d) => {
      this.info.set(d);
      // Se sugiere lo que falta para el mínimo (si ya hay abonos de reserva registrados, menos)
      this.form.monto = Math.max(d.abono_minimo - d.abonado, 0) || null;
    });
  }

  /** Cuánto falta abonar para llegar al mínimo, contando lo que ya se registró como reserva. */
  faltante(): number {
    const i = this.info();
    return i ? Math.max(i.abono_minimo - i.abonado, 0) : 0;
  }

  errores(): { fecha?: string; monto?: string; tipo?: string; notas?: string } {
    const f = this.form;
    const e: { fecha?: string; monto?: string; tipo?: string; notas?: string } = {};
    const finDeHoy = new Date();
    finDeHoy.setHours(23, 59, 59, 999);
    if (!f.fecha_pago) e.fecha = 'Elegí la fecha del pago.';
    else if (f.fecha_pago > finDeHoy) e.fecha = 'La fecha no puede ser futura.';
    const faltante = this.faltante();
    if (!f.monto || f.monto <= 0) e.monto = 'Escribí el monto del abono.';
    else if (f.monto < faltante) e.monto = `El abono mínimo para confirmar es Q${faltante.toLocaleString('es-GT', { minimumFractionDigits: 2 })}.`;
    else if (f.monto > 1_000_000) e.monto = 'El monto es demasiado grande; revisalo.';
    if (!f.id_tipo_pago) e.tipo = 'Elegí la forma de pago.';
    if (f.notas.length > 500) e.notas = 'Máximo 500 caracteres.';
    return e;
  }

  abrirSelectorArchivo(): void {
    this.inputArchivo?.nativeElement.click();
  }

  onArchivo(event: Event): void {
    const input = event.target as HTMLInputElement;
    const archivo = input.files?.[0] ?? null;
    input.value = '';
    this.errorArchivo.set(null);
    if (archivo && !TIPOS_COMPROBANTE.includes(archivo.type)) return this.errorArchivo.set('Solo imágenes (jpg, png, webp) o PDF.');
    if (archivo && archivo.size > MAX_COMPROBANTE_MB * 1024 * 1024) return this.errorArchivo.set(`El archivo pesa más de ${MAX_COMPROBANTE_MB} MB.`);
    this.archivo = archivo;
  }

  confirmar(): void {
    this.intento.set(true);
    if (Object.keys(this.errores()).length || this.errorArchivo() || !this.info()) return;

    const datos = new FormData();
    datos.append('fecha_pago', fechaLocalISO(this.form.fecha_pago));
    datos.append('monto', String(this.form.monto));
    datos.append('id_tipo_pago', String(this.form.id_tipo_pago));
    if (this.form.notas.trim()) datos.append('notas', this.form.notas.trim());
    if (this.archivo) datos.append('comprobante', this.archivo);

    this.guardando.set(true);
    this.error.set(null);
    this.http.post(`${API_URL}/eventos/${this.idEvento}/confirmar`, datos, ERROR_EN_LINEA).subscribe({
      next: () => {
        this.guardando.set(false);
        this.visible.set(false);
        this.confirmado.emit();
      },
      error: (err) => {
        this.guardando.set(false);
        this.error.set(err.error?.error ?? 'No se pudo confirmar el evento.');
      },
    });
  }
}
