import { Component, OnInit, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute, Router } from '@angular/router';
import { Button } from 'primeng/button';
import { Card } from 'primeng/card';
import { Tabs, TabList, Tab, TabPanels, TabPanel } from 'primeng/tabs';
import { API_URL } from '../../../core/api-config';
import { DatePipe } from '@angular/common';
import { CotizacionPanel } from '../cotizacion-panel/cotizacion-panel';
import { PagosPanel } from '../pagos-panel/pagos-panel';
import { DegustacionPanel } from '../degustacion-panel/degustacion-panel';
import { ExtrasPanel } from '../extras-panel/extras-panel';

interface EventoDetalle {
  id_evento: number;
  fecha: string;
  hora_inicio: string;
  hora_fin: string;
  estado: string;
  reserva_temporal: boolean;
  total_adultos: number;
  total_menores: number;
  notas: string | null;
  id_cliente: number;
  cliente: string;
  telefono_cliente: string | null;
  tipo_evento: string | null;
  salones: string;
}

const SIGUIENTE_ESTADO: Record<string, { estado: string; label: string }[]> = {
  cotizacion: [
    { estado: 'confirmado', label: 'Confirmar evento' },
    { estado: 'cancelado', label: 'Cancelar' },
  ],
  confirmado: [
    { estado: 'en_curso', label: 'Marcar en curso' },
    { estado: 'cancelado', label: 'Cancelar' },
  ],
  en_curso: [{ estado: 'cerrado', label: 'Cerrar evento' }],
  cerrado: [],
  cancelado: [],
};

@Component({
  selector: 'app-evento-detail',
  standalone: true,
  imports: [Button, Card, Tabs, TabList, Tab, TabPanels, TabPanel,DatePipe, CotizacionPanel, PagosPanel, DegustacionPanel,ExtrasPanel],
  templateUrl: './evento-detail.html',
  styleUrl: './evento-detail.scss',
})
export class EventoDetail implements OnInit {
  readonly evento = signal<EventoDetalle | null>(null);
  readonly cambiandoEstado = signal(false);
  private idEvento!: string;

  constructor(
    private http: HttpClient,
    private route: ActivatedRoute,
    private router: Router,
  ) {}

  ngOnInit(): void {
    this.idEvento = this.route.snapshot.paramMap.get('id')!;
    this.cargarEvento();
  }

  cargarEvento(): void {
    this.http.get<EventoDetalle>(`${API_URL}/eventos/${this.idEvento}`).subscribe((data) => this.evento.set(data));
  }

  opcionesEstado(): { estado: string; label: string }[] {
    const e = this.evento();
    return e ? SIGUIENTE_ESTADO[e.estado] ?? [] : [];
  }

  cambiarEstado(nuevoEstado: string): void {
    this.cambiandoEstado.set(true);
    this.http.patch(`${API_URL}/eventos/${this.idEvento}/estado`, { estado: nuevoEstado }).subscribe({
      next: () => {
        this.cambiandoEstado.set(false);
        this.cargarEvento();
      },
      error: (err) => {
        this.cambiandoEstado.set(false);
        alert(err.error?.error ?? 'Error al cambiar el estado');
      },
    });
  }

  irAEditar(): void {
    this.router.navigate(['/eventos', this.idEvento, 'editar']);
  }

  volver(): void {
    this.router.navigate(['/eventos']);
  }
}