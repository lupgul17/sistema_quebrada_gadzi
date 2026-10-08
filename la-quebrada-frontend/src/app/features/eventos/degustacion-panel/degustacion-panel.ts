import { Component, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Select } from 'primeng/select';
import { Textarea } from 'primeng/textarea';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { DatePicker } from 'primeng/datepicker';
import { HoraRapida } from '../../../core/hora-rapida.directive';
import { fechaLocalISO } from '../../../core/fechas';
import { API_URL } from '../../../core/api-config';
import { conEtiqueta } from '../../../core/menus';
import { AuthService } from '../../../core/auth.service';
import { SaldoEventoService } from '../../../core/saldo-evento.service';
import { DegustacionEventoService } from '../../../core/degustacion-evento';

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
  etiqueta: string;
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
  imports: [CommonModule, FormsModule, Select, Textarea, Button, Dialog, DatePicker, HoraRapida, ],
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

  constructor(private http: HttpClient, private saldoService: SaldoEventoService, public auth: AuthService, private degustacionEventoService: DegustacionEventoService,) {}

  ngOnInit(): void {
    // Solo los menús que se pueden usar en este evento (según sus salones)
    this.http.get<any[]>(`${API_URL}/menus?id_evento=${this.idEvento}`).subscribe((data) => this.menusDisponibles.set(conEtiqueta(data)));
    this.cargarDegustaciones();
  }

  cargarDegustaciones(): void {
    this.http.get<DegustacionResumen[]>(`${API_URL}/eventos/${this.idEvento}/degustaciones`).subscribe((data) => {
      this.degustaciones.set(data);
      this.degustacionEventoService.fijar(this.idEvento, DegustacionEventoService.hayAprobada(data));
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
    this.http.patch(`${API_URL}/degustaciones/${id}/estado`, { estado: nuevoEstado }).subscribe({ next: () => {
      this.procesando.set(false);
      this.cargarDegustaciones();
    }, error: () => this.procesando.set(false) });
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
      },
    });
  }

  abrirAgendar(): void {
    this.fechaElegida = null;
    this.notasAgendar = '';
    this.horaLlegada = null;
    this.http.get<FechaDisponible[]>(`${API_URL}/degustaciones/fechas`).subscribe((data) => {
      // Solo las que se pueden elegir: disponibles y de hoy en adelante (no pasadas, llenas ni canceladas)
      const hoy = fechaLocalISO(new Date());
      const conLabel = data
        .filter((f) => f.estado === 'disponible' && f.fecha.slice(0, 10) >= hoy)
        .map((f) => {
          const [a, m, d] = f.fecha.slice(0, 10).split('-');
          const horario = f.hora_inicio.substring(0, 5) + (f.hora_fin ? `–${f.hora_fin.substring(0, 5)}` : '');
          return { ...f, label: `${d}/${m}/${a} · ${horario} (${f.eventos_agendados} agendados)` };
        });
      this.fechasDisponibles.set(conLabel);
    });
    this.dialogoAgendarVisible.set(true);
  }

  private formatearHora(fecha: Date): string {
    return fecha.toTimeString().split(' ')[0].substring(0, 5);
  }

  /** Hora de inicio de la fecha elegida (para sugerir la llegada y validarla). */
  horaInicioElegida(): Date | null {
    const f = this.fechasDisponibles().find((x) => x.id_fecha_degustacion === this.fechaElegida);
    return f ? this.horaComoFecha(f.hora_inicio) : null;
  }

  /** La hora de llegada tiene que caer dentro del horario de la fecha elegida. */
  errorLlegada(): string | null {
    const f = this.fechasDisponibles().find((x) => x.id_fecha_degustacion === this.fechaElegida);
    if (!f || !this.horaLlegada) return null;
    const min = (d: Date) => d.getHours() * 60 + d.getMinutes();
    const llegada = min(this.horaLlegada);
    if (llegada < min(this.horaComoFecha(f.hora_inicio))) return `La degustación empieza a las ${f.hora_inicio.substring(0, 5)}.`;
    if (f.hora_fin && llegada >= min(this.horaComoFecha(f.hora_fin))) return `La degustación termina a las ${f.hora_fin.substring(0, 5)}.`;
    return null;
  }

  private horaComoFecha(hora: string): Date {
    const [h, m] = hora.split(':').map(Number);
    const d = new Date();
    d.setHours(h, m, 0, 0);
    return d;
  }

  confirmarAgendar(): void {
    if (!this.fechaElegida || this.errorLlegada() || this.notasAgendar.length > 500) return;
    this.procesando.set(true);
    this.http.post<{ id_degustacion: number }>(`${API_URL}/degustaciones`, {
      id_evento: this.idEvento,
      id_fecha_degustacion: this.fechaElegida,
      hora_llegada: this.horaLlegada ? this.formatearHora(this.horaLlegada) : null,
      notas: this.notasAgendar.trim() || null,
    }).subscribe({ next: () => {
      this.procesando.set(false);
      this.dialogoAgendarVisible.set(false);
      this.degustacionSeleccionada.set(null);
      this.cargarDegustaciones();
    }, error: () => this.procesando.set(false) });
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