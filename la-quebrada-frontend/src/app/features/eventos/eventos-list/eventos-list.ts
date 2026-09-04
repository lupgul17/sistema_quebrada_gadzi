import { Component, OnInit, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TableModule } from 'primeng/table';
import { Select } from 'primeng/select';
import { DatePicker } from 'primeng/datepicker';
import { Button } from 'primeng/button';
import { API_URL } from '../../../core/api-config';
import { DatePipe } from '@angular/common';

interface Evento {
  id_evento: number;
  fecha: string;
  hora_inicio: string;
  hora_fin: string;
  estado: string;
  tipo_evento: string | null;
  total_adultos: number;
  total_menores: number;
  cliente: string;
  salones: string;
}

const ESTADOS = [
  { label: 'Todos', value: null },
  { label: 'Cotización', value: 'cotizacion' },
  { label: 'Confirmado', value: 'confirmado' },
  { label: 'En curso', value: 'en_curso' },
  { label: 'Cerrado', value: 'cerrado' },
  { label: 'Cancelado', value: 'cancelado' },
];

@Component({
  selector: 'app-eventos-list',
  standalone: true,
  imports: [TableModule, Select, DatePicker, Button, FormsModule,DatePipe],
  templateUrl: './eventos-list.html',
  styleUrl: './eventos-list.scss',
})
export class EventosList implements OnInit {
  readonly eventos = signal<Evento[]>([]);
  readonly estados = ESTADOS;

  estadoFiltro: string | null = null;
  fechaDesde: Date | null = null;
  fechaHasta: Date | null = null;

  constructor(
    private http: HttpClient,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.cargarEventos();
  }

  cargarEventos(): void {
    const params: Record<string, string> = {};
    if (this.estadoFiltro) params['estado'] = this.estadoFiltro;
    if (this.fechaDesde) params['fecha_desde'] = this.formatearFecha(this.fechaDesde);
    if (this.fechaHasta) params['fecha_hasta'] = this.formatearFecha(this.fechaHasta);

    const query = new URLSearchParams(params).toString();
    this.http.get<Evento[]>(`${API_URL}/eventos${query ? '?' + query : ''}`).subscribe((data) => this.eventos.set(data));
  }

  private formatearFecha(fecha: Date): string {
    return fecha.toISOString().split('T')[0];
  }

  irADetalle(evento: Evento): void {
    this.router.navigate(['/eventos', evento.id_evento]);
  }

  irANuevo(): void {
    this.router.navigate(['/eventos/nuevo']);
  }

  estadoSeverity(estado: string): 'success' | 'info' | 'warn' | 'danger' | 'secondary' {
    const mapa: Record<string, 'success' | 'info' | 'warn' | 'danger' | 'secondary'> = {
      cotizacion: 'secondary',
      confirmado: 'info',
      en_curso: 'warn',
      cerrado: 'success',
      cancelado: 'danger',
    };
    return mapa[estado] ?? 'secondary';
  }
}
