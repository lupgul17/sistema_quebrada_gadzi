import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { DatePicker } from 'primeng/datepicker';
import { Select } from 'primeng/select';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { API_URL } from '../../../core/api-config';

interface FechaDegustacion {
  id_fecha_degustacion: number;
  fecha: string;
  hora_inicio: string;
  hora_fin: string | null;
  estado: string;
  eventos_agendados: number;
}

interface Agendado {
  id_degustacion: number;
  id_evento: number;
  cliente: string;
  telefono: string | null;
  tipo_evento: string | null;
  fecha_evento: string;
  hora_llegada: string | null;
  estado: string;
  notas: string | null;
}

const ESTADOS = [
  { label: 'Disponible', value: 'disponible' },
  { label: 'Llena', value: 'llena' },
  { label: 'Cancelada', value: 'cancelada' },
];

@Component({
  selector: 'app-fechas-degustacion-list',
  standalone: true,
  imports: [CommonModule, FormsModule, TableModule, DatePicker, Select, Button, Dialog],
  templateUrl: './fechas-degustacion-list.html',
  styleUrl: './fechas-degustacion-list.scss',
})
export class FechasDegustacionList implements OnInit {
  readonly fechas = signal<FechaDegustacion[]>([]);
  readonly cargando = signal(true);
  readonly guardando = signal(false);
  readonly dialogoVisible = signal(false);
  readonly estados = ESTADOS;

  readonly dialogoAgendadosVisible = signal(false);
  readonly fechaSeleccionada = signal<FechaDegustacion | null>(null);
  readonly agendados = signal<Agendado[]>([]);
  readonly cargandoAgendados = signal(false);

  nuevaFecha: Date | null = null;
  nuevaHoraInicio: Date | null = null;
  nuevaHoraFin: Date | null = null;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.cargarFechas();
  }

  cargarFechas(): void {
    this.cargando.set(true);
    this.http.get<FechaDegustacion[]>(`${API_URL}/degustaciones/fechas`).subscribe((data) => {
      this.fechas.set(data);
      this.cargando.set(false);
    });
  }

  abrirNueva(): void {
    this.nuevaFecha = null;
    this.nuevaHoraInicio = null;
    this.nuevaHoraFin = null;
    this.dialogoVisible.set(true);
  }

  private formatearFecha(fecha: Date): string {
    return fecha.toISOString().split('T')[0];
  }

  private formatearHora(fecha: Date): string {
    return fecha.toTimeString().split(' ')[0].substring(0, 5);
  }

  crearFecha(): void {
    if (!this.nuevaFecha || !this.nuevaHoraInicio) return;
    this.guardando.set(true);
    this.http.post(`${API_URL}/degustaciones/fechas`, {
      fecha: this.formatearFecha(this.nuevaFecha),
      hora_inicio: this.formatearHora(this.nuevaHoraInicio),
      hora_fin: this.nuevaHoraFin ? this.formatearHora(this.nuevaHoraFin) : null,
    }).subscribe(() => {
      this.guardando.set(false);
      this.dialogoVisible.set(false);
      this.cargarFechas();
    });
  }

  cambiarEstado(fecha: FechaDegustacion, nuevoEstado: string): void {
    this.http.patch(`${API_URL}/degustaciones/fechas/${fecha.id_fecha_degustacion}/estado`, { estado: nuevoEstado }).subscribe(() => {
      this.cargarFechas();
    });
  }

  verAgendados(fecha: FechaDegustacion): void {
    this.fechaSeleccionada.set(fecha);
    this.cargandoAgendados.set(true);
    this.dialogoAgendadosVisible.set(true);
    this.http.get<Agendado[]>(`${API_URL}/degustaciones/fechas/${fecha.id_fecha_degustacion}/agendados`).subscribe((data) => {
      this.agendados.set(data);
      this.cargandoAgendados.set(false);
    });
  }

  imprimir(): void {
    window.print();
  }
}