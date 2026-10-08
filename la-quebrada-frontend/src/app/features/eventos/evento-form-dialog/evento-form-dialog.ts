import { Component, EventEmitter, Output, computed, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators, FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { InputNumber } from 'primeng/inputnumber';
import { Textarea } from 'primeng/textarea';
import { Select } from 'primeng/select';
import { DatePicker } from 'primeng/datepicker';
import { HoraRapida } from '../../../core/hora-rapida.directive';
import { Checkbox } from 'primeng/checkbox';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { Message } from 'primeng/message';
import { API_URL } from '../../../core/api-config';
import { ERROR_EN_LINEA } from '../../../core/http-errores';
import { fechaLocalISO } from '../../../core/fechas';
import { Validadores, revalidarAlCambiar } from '../../../core/validaciones';
import { ErrorCampo } from '../../../core/error-campo/error-campo';

interface ClienteOpcion {
  id_cliente: number;
  primer_nombre: string;
  primer_apellido: string;
  nombre_completo?: string;
}

interface TipoEventoOpcion {
  id_tipo_evento: number;
  descripcion: string;
}

interface SalonDisponibilidad {
  id_salon: number;
  nombre: string;
  capacidad: number;
  locacion: string;
  disponible: boolean;
}

@Component({
  selector: 'app-evento-form-dialog',
  standalone: true,
  imports: [
    CommonModule, ReactiveFormsModule, InputNumber, Textarea,
    Select, DatePicker, HoraRapida, Checkbox, Button, Dialog, Message, FormsModule, ErrorCampo
  ],
  templateUrl: './evento-form-dialog.html',
  styleUrl: './evento-form-dialog.scss',
})
export class EventoFormDialog {
  @Output() guardado = new EventEmitter<void>();
  /** Solo al crear: emite el id del evento nuevo (lo usa la conversión de prospectos). */
  @Output() creado = new EventEmitter<number>();

  readonly visible = signal(false);
  readonly cargando = signal(false);
  readonly error = signal<string | null>(null);
  readonly esEdicion = signal(false);
  readonly clientes = signal<ClienteOpcion[]>([]);
  readonly tiposEvento = signal<TipoEventoOpcion[]>([]);
  readonly salones = signal<SalonDisponibilidad[]>([]);
  readonly form;
  /** Se intentó guardar: muestra el aviso de "elegí un salón" aunque no se haya tocado nada. */
  readonly intentoGuardar = signal(false);
  private readonly valores;

  /** Capacidad sumada de los salones elegidos vs. invitados: aviso (no bloquea, puede haber mesas extra). */
  readonly avisoCapacidad = computed(() => {
    const v = this.valores();
    const elegidos = this.salones().filter((s) => (v?.salones ?? []).includes(s.id_salon));
    const capacidad = elegidos.reduce((acc, s) => acc + (s.capacidad ?? 0), 0);
    const personas = (v?.total_adultos ?? 0) + (v?.total_menores ?? 0);
    return elegidos.length && capacidad > 0 && personas > capacidad
      ? `Son ${personas} invitados y los salones elegidos tienen capacidad para ${capacidad}.`
      : null;
  });

  private idEvento: number | null = null;

  constructor(
    private fb: FormBuilder,
    private http: HttpClient
  ) {
    this.form = this.fb.group({
      id_cliente: this.fb.control<number | null>(null, Validators.required),
      id_tipo_evento: this.fb.control<number | null>(null),
      fecha: this.fb.control<Date | null>(null, Validators.required),
      hora_inicio: this.fb.control<Date | null>(null, Validators.required),
      hora_fin: this.fb.control<Date | null>(null, [Validators.required, Validadores.horaDespuesDe('hora_inicio', 1)]),
      total_adultos: this.fb.control<number | null>(0, [Validators.min(0), Validators.max(5000)]),
      total_menores: this.fb.control<number | null>(0, [Validators.min(0), Validators.max(5000)]),
      notas: ['', Validators.maxLength(2000)],
      reserva_temporal: [false],
      salones: this.fb.control<number[]>([]),
    });
    revalidarAlCambiar(this.form.controls.hora_inicio, this.form.controls.hora_fin);
    this.valores = toSignal(this.form.valueChanges, { initialValue: this.form.getRawValue() });
  }

  /** Un evento nuevo no puede ser en una fecha pasada; al editar sí (hay eventos ya realizados). */
  private reglasFecha(nuevo: boolean): void {
    const fecha = this.form.controls.fecha;
    fecha.setValidators(nuevo ? [Validators.required, Validadores.fechaNoPasada] : [Validators.required]);
    fecha.updateValueAndValidity({ emitEvent: false });
  }

  private cargarCatalogos(): void {
    this.http.get<ClienteOpcion[]>(`${API_URL}/clientes`).subscribe((data) => {
      const conNombreCompleto = data.map((c) => ({ ...c, nombre_completo: this.nombreCliente(c) }));
      this.clientes.set(conNombreCompleto);
    });
    this.http.get<TipoEventoOpcion[]>(`${API_URL}/tipos-evento`).subscribe((data) => this.tiposEvento.set(data));
  }

  abrirNuevo(
    datosIniciales?: Partial<{ id_cliente: number; id_tipo_evento: number | null; fecha: Date | null; total_adultos: number; total_menores: number; notas: string }>
  ): void {
    this.idEvento = null;
    this.esEdicion.set(false);
    this.error.set(null);
    this.intentoGuardar.set(false);
    this.reglasFecha(true);
    this.form.reset({ total_adultos: 0, total_menores: 0, reserva_temporal: false, salones: [], ...(datosIniciales ?? {}) });
    this.salones.set([]);
    this.cargarCatalogos();
    this.visible.set(true);
  }

  abrirEditar(idEvento: number): void {
    this.idEvento = idEvento;
    this.esEdicion.set(true);
    this.error.set(null);
    this.intentoGuardar.set(false);
    this.reglasFecha(false);
    this.cargarCatalogos();
    this.http.get<any>(`${API_URL}/eventos/${idEvento}`).subscribe((evento) => {
      this.form.patchValue({
        id_cliente: evento.id_cliente,
        id_tipo_evento: evento.id_tipo_evento,
        fecha: new Date(evento.fecha),
        hora_inicio: this.horaAFecha(evento.hora_inicio),
        hora_fin: this.horaAFecha(evento.hora_fin),
        total_adultos: evento.total_adultos,
        total_menores: evento.total_menores,
        notas: evento.notas,
        reserva_temporal: evento.reserva_temporal,
        salones: evento.salones_ids ?? [],
      });
      this.consultarDisponibilidad();
    });
    this.visible.set(true);
  }

  nombreCliente(c: ClienteOpcion): string {
    return `${c.primer_nombre} ${c.primer_apellido}`;
  }

  consultarDisponibilidad(): void {
    const { fecha, hora_inicio, hora_fin } = this.form.getRawValue();
    const c = this.form.controls;
    if (!fecha || !hora_inicio || !hora_fin || c.fecha.invalid || c.hora_fin.invalid) {
      // Marcar los campos para que se vea qué falta o qué está mal
      c.fecha.markAsTouched();
      c.hora_inicio.markAsTouched();
      c.hora_fin.markAsTouched();
      this.error.set('Revisá la fecha y el horario antes de consultar la disponibilidad.');
      return;
    }
    this.error.set(null);

    const params = new URLSearchParams({
      fecha: this.formatearFecha(fecha),
      hora_inicio: this.formatearHora(hora_inicio),
      hora_fin: this.formatearHora(hora_fin),
    });
    if (this.esEdicion() && this.idEvento) {
      params.set('excluir_evento', this.idEvento.toString());
    }

    this.http.get<SalonDisponibilidad[]>(`${API_URL}/eventos/disponibilidad-salones?${params}`).subscribe((data) => {
      this.salones.set(data);
    });
  }

  toggleSalon(idSalon: number): void {
    const actuales = this.form.controls.salones.value ?? [];
    const yaEsta = actuales.includes(idSalon);
    this.form.controls.salones.setValue(yaEsta ? actuales.filter((id) => id !== idSalon) : [...actuales, idSalon]);
  }

  salonSeleccionado(idSalon: number): boolean {
    return (this.form.controls.salones.value ?? []).includes(idSalon);
  }

  onSubmit(): void {
    this.intentoGuardar.set(true);
    const sinSalon = (this.form.controls.salones.value ?? []).length === 0;
    if (this.form.invalid || sinSalon) {
      this.form.markAllAsTouched();
      this.error.set(this.form.invalid ? 'Revisá los campos marcados en rojo.' : 'Elegí al menos un salón disponible.');
      return;
    }

    this.cargando.set(true);
    this.error.set(null);

    const v = this.form.getRawValue();
    const body = {
      id_cliente: v.id_cliente,
      id_tipo_evento: v.id_tipo_evento,
      fecha: this.formatearFecha(v.fecha!),
      hora_inicio: this.formatearHora(v.hora_inicio!),
      hora_fin: this.formatearHora(v.hora_fin!),
      total_adultos: v.total_adultos,
      total_menores: v.total_menores,
      notas: v.notas,
      reserva_temporal: v.reserva_temporal,
      salones: v.salones,
    };

    const peticion = this.esEdicion()
      ? this.http.put(`${API_URL}/eventos/${this.idEvento}`, body, ERROR_EN_LINEA)
      : this.http.post(`${API_URL}/eventos`, body, ERROR_EN_LINEA);

    peticion.subscribe({
      next: (res: any) => {
        this.cargando.set(false);
        this.visible.set(false);
        this.guardado.emit();
        if (!this.esEdicion() && res?.id_evento) this.creado.emit(res.id_evento);
      },
      error: (err) => {
        this.cargando.set(false);
        this.error.set(err.error?.error ?? 'Error al guardar el evento');
      },
    });
  }

  cancelar(): void {
    this.visible.set(false);
  }

  private formatearFecha(fecha: Date): string {
    return fechaLocalISO(fecha);
  }

  private formatearHora(fecha: Date): string {
    return fecha.toTimeString().split(' ')[0].substring(0, 5);
  }

  private horaAFecha(hora: string): Date {
    const [h, m] = hora.split(':').map(Number);
    const fecha = new Date();
    fecha.setHours(h, m, 0, 0);
    return fecha;
  }
}