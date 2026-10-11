import { Component, OnInit, computed, signal, ViewChild } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute, Router } from '@angular/router';
import { Button } from 'primeng/button';
import { Card } from 'primeng/card';
import { Tabs, TabList, Tab, TabPanels, TabPanel } from 'primeng/tabs';
import { API_URL } from '../../../core/api-config';
import { AuthService } from '../../../core/auth.service';
import { DatePipe, Location } from '@angular/common';
import { CotizacionPanel } from '../cotizacion-panel/cotizacion-panel';
import { PagosPanel } from '../pagos-panel/pagos-panel';
import { DegustacionPanel } from '../degustacion-panel/degustacion-panel';
import { ExtrasPanel } from '../extras-panel/extras-panel';
import { EventoFormDialog } from '../evento-form-dialog/evento-form-dialog';
import { ConfirmarEventoDialog } from '../confirmar-evento-dialog/confirmar-evento-dialog';
import { TelefonoPipe } from '../../../core/telefono.pipe';

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

// Degustación, extras y pagos solo aplican desde que el evento se confirma
const ESTADOS_CONFIRMADOS = ['confirmado', 'en_curso', 'cerrado'];

@Component({
  selector: 'app-evento-detail',
  standalone: true,
  imports: [Button, Card, Tabs, TabList, Tab, TabPanels, TabPanel,DatePipe, CotizacionPanel, PagosPanel, DegustacionPanel,ExtrasPanel,EventoFormDialog, TelefonoPipe, ConfirmarEventoDialog],
  templateUrl: './evento-detail.html',
  styleUrl: './evento-detail.scss',
})
export class EventoDetail implements OnInit {
  readonly evento = signal<EventoDetalle | null>(null);
  readonly cambiandoEstado = signal(false);
  readonly eventoConfirmado = computed(() => ESTADOS_CONFIRMADOS.includes(this.evento()?.estado ?? ''));
  private idEvento!: string;
  @ViewChild('eventoFormDialog') eventoFormDialog!: EventoFormDialog;
  @ViewChild('confirmarDialog') confirmarDialog!: ConfirmarEventoDialog;
  /** Pestaña abierta: después de confirmar se pasa a Pagos para ver el abono registrado. */
  readonly pestana = signal('cotizacion');

  constructor(
    private http: HttpClient,
    private route: ActivatedRoute,
    private router: Router,
    private location: Location,
    public auth: AuthService,
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
    // Confirmar exige el abono de reserva: se registra en el modal junto con la confirmación
    if (nuevoEstado === 'confirmado') {
      this.confirmarDialog.abrir(Number(this.idEvento));
      return;
    }
    this.cambiandoEstado.set(true);
    this.http.patch(`${API_URL}/eventos/${this.idEvento}/estado`, { estado: nuevoEstado }).subscribe({
      next: () => {
        this.cambiandoEstado.set(false);
        this.cargarEvento();
      },
      error: (err) => {
        this.cambiandoEstado.set(false);
      },
    });
  }

  alConfirmar(): void {
    this.cargarEvento();
    this.pestana.set('pagos');
  }

  abrirEditar(): void {
  this.eventoFormDialog.abrirEditar(Number(this.idEvento));
}

  /** Regresa a donde se vino (calendario, cliente, pagos...); si se abrió el link directo, a la lista. */
  volver(): void {
    // Angular numera cada navegación en history.state: > 1 = hay una pantalla anterior del sistema
    if ((window.history.state?.navigationId ?? 0) > 1) {
      this.location.back();
      return;
    }
    this.router.navigate(['/eventos']);
  }
}