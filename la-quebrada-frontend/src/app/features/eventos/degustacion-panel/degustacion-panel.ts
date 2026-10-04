import { Component, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Select } from 'primeng/select';
import { Textarea } from 'primeng/textarea';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { DatePicker } from 'primeng/datepicker';
import { API_URL } from '../../../core/api-config';
import { SaldoEventoService } from '../../../core/saldo-evento.service';

interface DegustacionResumen {
  id_degustacion: number;
  id_fecha_degustacion: number;
  fecha: string;
  hora_inicio: string;
  hora_fin: string | null;
  hora_llegada: string | null;
  estado: string;
  notas: string | null;
  resultado: string;
  motivo_rechazo: string | null;
}

interface FechaDisponible {
  id_fecha_degustacion: number;
  fecha: string;
  hora_inicio: string;
  hora_fin: string | null;
  estado: string;
  eventos_agendados: number;
  label?: string;
}

interface MenuDegustado {
  id_degustacion_menu: number;
  menu: string;
  tipo_menu: string;
  resultado: string;
  es_adicional: boolean;
  notas: string | null;
}

interface MenuOpcion {
  id_menu: number;
  nombre: string;
}

const SIGUIENTE_ESTADO_DEGUSTACION: Record<string, { estado: string; label: string }[]> = {
  agendada: [
    { estado: 'realizada', label: 'Marcar realizada' },
    { estado: 'cancelada', label: 'Cancelar' },
  ],
  realizada: [],
  cancelada: [],
};

@Component({
  selector: 'app-degustacion-panel',
  standalone: true,
  imports: [CommonModule, FormsModule, Select, Textarea, Button, Dialog, DatePicker, ],
  templateUrl: './degustacion-panel.html',
  styleUrl: './degustacion-panel.scss',
})
export class DegustacionPanel implements OnInit {
  @Input({ required: true }) idEvento!: number;

  readonly degustaciones = signal<DegustacionResumen[]>([]);
  readonly degustacionSeleccionada = signal<number | null>(null);
  readonly menusDegustados = signal<MenuDegustado[]>([]);
  readonly fechasDisponibles = signal<FechaDisponible[]>([]);
  readonly menusDisponibles = signal<MenuOpcion[]>([]);
  readonly cargando = signal(true);
  readonly procesando = signal(false);
  readonly dialogoAgendarVisible = signal(false);
  readonly dialogoRechazoVisible = signal(false);

  fechaElegida: number | null = null;
  notasAgendar = '';
  horaLlegada: Date | null = null;
  menuParaAgregar: number | null = null;
  motivoRechazo = '';

  constructor(private http: HttpClient,private saldoService: SaldoEventoService) {}

  ngOnInit(): void {
    this.http.get<MenuOpcion[]>(`${API_URL}/menus`).subscribe((data) => this.menusDisponibles.set(data));
    this.cargarDegustaciones();
  }

  cargarDegustaciones(): void {
    this.http.get<DegustacionResumen[]>(`${API_URL}/eventos/${this.idEvento}/degustaciones`).subscribe((data) => {
      this.degustaciones.set(data);
      this.cargando.set(false);
      if (data.length > 0 && !this.degustacionSeleccionada()) {
        this.seleccionar(data[0].id_degustacion);
      }
    });
  }

  seleccionar(idDegustacion: number): void {
    this.degustacionSeleccionada.set(idDegustacion);
    this.http.get<any>(`${API_URL}/degustaciones/${idDegustacion}`).subscribe((data) => {
      this.menusDegustados.set(data.menus ?? []);
    });
  }

  degustacionActual(): DegustacionResumen | null {
    return this.degustaciones().find((d) => d.id_degustacion === this.degustacionSeleccionada()) ?? null;
  }

  opcionesEstado(): { estado: string; label: string }[] {
    const d = this.degustacionActual();
    return d ? SIGUIENTE_ESTADO_DEGUSTACION[d.estado] ?? [] : [];
  }

  cambiarEstado(nuevoEstado: string): void {
    const id = this.degustacionSeleccionada();
    if (!id) return;
    this.procesando.set(true);
    this.http.patch(`${API_URL}/degustaciones/${id}/estado`, { estado: nuevoEstado }).subscribe(() => {
      this.procesando.set(false);
      this.cargarDegustaciones();
    });
  }

  aprobarDegustacion(): void {
    const id = this.degustacionSeleccionada();
    if (!id) return;
    this.procesando.set(true);
    this.http.patch(`${API_URL}/degustaciones/${id}/resultado`, { resultado: 'aprobada' }).subscribe({
      next: () => {
        this.procesando.set(false);
        this.cargarDegustaciones();
      },
      error: (err) => {
        this.procesando.set(false);
        alert(err.error?.error ?? 'Error al aprobar la degustación');
      },
    });
  }

  abrirRechazo(): void {
    this.motivoRechazo = '';
    this.dialogoRechazoVisible.set(true);
  }

  confirmarRechazo(): void {
    const id = this.degustacionSeleccionada();
    if (!id || !this.motivoRechazo.trim()) return;
    this.procesando.set(true);
    this.http.patch(`${API_URL}/degustaciones/${id}/resultado`, {
      resultado: 'rechazada',
      motivo_rechazo: this.motivoRechazo,
    }).subscribe({
      next: () => {
        this.procesando.set(false);
        this.dialogoRechazoVisible.set(false);
        this.cargarDegustaciones();
      },
      error: (err) => {
        this.procesando.set(false);
        alert(err.error?.error ?? 'Error al rechazar la degustación');
      },
    });
  }

  abrirAgendar(): void {
    this.fechaElegida = null;
    this.notasAgendar = '';
    this.horaLlegada = null;
    this.http.get<FechaDisponible[]>(`${API_URL}/degustaciones/fechas`).subscribe((data) => {
      const conLabel = data.map((f) => ({
        ...f,
        label: `${f.fecha} ${f.hora_inicio.substring(0, 5)} — ${f.estado} (${f.eventos_agendados} agendados)`,
      }));
      this.fechasDisponibles.set(conLabel);
    });
    this.dialogoAgendarVisible.set(true);
  }

  private formatearHora(fecha: Date): string {
    return fecha.toTimeString().split(' ')[0].substring(0, 5);
  }

  confirmarAgendar(): void {
    if (!this.fechaElegida) return;
    this.procesando.set(true);
    this.http.post<{ id_degustacion: number }>(`${API_URL}/degustaciones`, {
      id_evento: this.idEvento,
      id_fecha_degustacion: this.fechaElegida,
      hora_llegada: this.horaLlegada ? this.formatearHora(this.horaLlegada) : null,
      notas: this.notasAgendar || null,
    }).subscribe(() => {
      this.procesando.set(false);
      this.dialogoAgendarVisible.set(false);
      this.degustacionSeleccionada.set(null);
      this.cargarDegustaciones();
    });
  }

  agregarMenu(): void {
    const id = this.degustacionSeleccionada();
    if (!id || !this.menuParaAgregar) return;
    if (this.menusDegustados().length >= 4) return;

    this.procesando.set(true);
    this.http.post(`${API_URL}/degustaciones/${id}/menu`, { id_menu: this.menuParaAgregar }).subscribe({
      next: () => {
        this.procesando.set(false);
        this.menuParaAgregar = null;
        this.seleccionar(id);
      },
      error: (err) => {
        this.procesando.set(false);
        alert(err.error?.error ?? 'Error al agregar el menú');
      },
    });
  }

  resolverMenu(idLinea: number, resultado: 'aprobado' | 'rechazado'): void {
    const id = this.degustacionSeleccionada();
    if (!id) return;
    this.http.patch(`${API_URL}/degustaciones/menu/${idLinea}`, { resultado }).subscribe(() => {
        this.seleccionar(id);
        this.saldoService.actualizar(this.idEvento);});
  }

  quitarMenu(idLinea: number): void {
  const id = this.degustacionSeleccionada();
  if (!id) return;
  this.http.patch(`${API_URL}/degustaciones/menu/${idLinea}/quitar`, {}).subscribe(() => {
    this.seleccionar(id);
    this.saldoService.actualizar(this.idEvento);
  });
}
}