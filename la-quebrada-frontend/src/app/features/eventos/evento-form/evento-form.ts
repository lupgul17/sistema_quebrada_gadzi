import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators, FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { InputText } from 'primeng/inputtext';
import { InputNumber } from 'primeng/inputnumber';
import { Textarea } from 'primeng/textarea';
import { Select } from 'primeng/select';
import { DatePicker } from 'primeng/datepicker';
import { Checkbox } from 'primeng/checkbox';
import { Button } from 'primeng/button';
import { Message } from 'primeng/message';
import { API_URL } from '../../../core/api-config';


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
  selector: 'app-evento-form',
  standalone: true,
  imports: [
    CommonModule, ReactiveFormsModule, FormsModule, InputText, InputNumber, Textarea,
    Select, DatePicker, Checkbox, Button, Message,
  ],
  templateUrl: './evento-form.html',
  styleUrl: './evento-form.scss',
})
export class EventoForm implements OnInit {
  readonly cargando = signal(false);
  readonly error = signal<string | null>(null);
  readonly esEdicion = signal(false);
  readonly clientes = signal<ClienteOpcion[]>([]);
  readonly tiposEvento = signal<TipoEventoOpcion[]>([]);
  readonly salones = signal<SalonDisponibilidad[]>([]);
  readonly form;

  private idEvento: string | null = null;

  constructor(
    private fb: FormBuilder,
    private http: HttpClient,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.form = this.fb.group({
  id_cliente: this.fb.control<number | null>(null, Validators.required),
  id_tipo_evento: this.fb.control<number | null>(null),
  fecha: this.fb.control<Date | null>(null, Validators.required),
  hora_inicio: this.fb.control<Date | null>(null, Validators.required),
  hora_fin: this.fb.control<Date | null>(null, Validators.required),
  total_adultos: [0],
  total_menores: [0],
  notas: [''],
  reserva_temporal: [false],
  salones: this.fb.control<number[]>([]),
});
  }

  ngOnInit(): void {
    this.http.get<ClienteOpcion[]>(`${API_URL}/clientes`).subscribe((data) => {
  const conNombreCompleto = data.map((c) => ({ ...c, nombre_completo: this.nombreCliente(c) }));
  this.clientes.set(conNombreCompleto);
});
    this.http.get<TipoEventoOpcion[]>(`${API_URL}/tipos-evento`).subscribe((data) => this.tiposEvento.set(data));

    this.idEvento = this.route.snapshot.paramMap.get('id');

    if (this.idEvento && this.idEvento !== 'nuevo') {
      this.esEdicion.set(true);
      this.http.get<any>(`${API_URL}/eventos/${this.idEvento}`).subscribe((evento) => {
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
    }
  }

  nombreCliente(c: ClienteOpcion): string {
    return `${c.primer_nombre} ${c.primer_apellido}`;
  }

  consultarDisponibilidad(): void {
    const { fecha, hora_inicio, hora_fin } = this.form.getRawValue();
    if (!fecha || !hora_inicio || !hora_fin) return;

    const params = new URLSearchParams({
      fecha: this.formatearFecha(fecha),
      hora_inicio: this.formatearHora(hora_inicio),
      hora_fin: this.formatearHora(hora_fin),
    });
    if (this.esEdicion() && this.idEvento) {
      params.set('excluir_evento', this.idEvento);
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
    if (this.form.invalid || (this.form.controls.salones.value ?? []).length === 0) {
      this.form.markAllAsTouched();
      this.error.set('Completá los campos obligatorios y elegí al menos un salón disponible.');
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
      ? this.http.put(`${API_URL}/eventos/${this.idEvento}`, body)
      : this.http.post(`${API_URL}/eventos`, body);

    peticion.subscribe({
      next: (res: any) => {
        this.cargando.set(false);
        this.router.navigate(['/eventos', this.esEdicion() ? this.idEvento : res.id_evento]);
      },
      error: (err) => {
        this.cargando.set(false);
        this.error.set(err.error?.error ?? 'Error al guardar el evento');
      },
    });
  }

  cancelar(): void {
    this.router.navigate(['/eventos']);
  }

  private formatearFecha(fecha: Date): string {
    return fecha.toISOString().split('T')[0];
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