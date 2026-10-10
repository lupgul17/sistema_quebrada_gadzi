import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { DatePicker } from 'primeng/datepicker';
import { HoraRapida } from '../../../core/hora-rapida.directive';
import { Select } from 'primeng/select';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { API_URL } from '../../../core/api-config';
import { AuthService } from '../../../core/auth.service';
import { fechaLocalISO } from '../../../core/fechas';
import { TelefonoPipe } from '../../../core/telefono.pipe';

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

/**
 * Pantalla que se ve en la pestaña nueva mientras se genera el PDF (con los colores y el logo
 * del tema actual). Las rutas van absolutas porque la pestaña nace en blanco, sin dirección propia.
 */
function paginaCargando(oscuro: boolean): string {
  const fondo = oscuro ? '#0f0d0d' : '#fbfaf7';
  const texto = oscuro ? '#c9c6c2' : '#5f5d5b';
  const acento = oscuro ? '#84a56c' : '#547043';
  const pista = oscuro ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)';
  const logo = `${location.origin}/brand/${oscuro ? 'logo-claro' : 'logo'}.png`;
  return `<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Generando reporte de degustación…</title>
<style>
  html, body { height: 100%; margin: 0; }
  body { background: ${fondo}; color: ${texto}; font-family: Inter, system-ui, -apple-system, 'Segoe UI', sans-serif;
         display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 1.5rem; }
  img { width: 200px; height: auto; }
  .spinner { width: 42px; height: 42px; border-radius: 50%; border: 3px solid ${pista}; border-top-color: ${acento};
             animation: girar 0.9s linear infinite; }
  p { margin: 0; font-size: 0.95rem; letter-spacing: 0.01em; }
  @keyframes girar { to { transform: rotate(360deg); } }
</style></head>
<body>
  <img src="${logo}" alt="La Quebrada">
  <div class="spinner" role="status" aria-label="Cargando"></div>
  <p>Generando reporte de degustación…</p>
</body></html>`;
}

@Component({
  selector: 'app-fechas-degustacion-list',
  standalone: true,
  imports: [CommonModule, FormsModule, TableModule, DatePicker, HoraRapida, Select, Button, Dialog, TelefonoPipe],
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
  readonly imprimiendo = signal(false);
  readonly agendados = signal<Agendado[]>([]);
  readonly cargandoAgendados = signal(false);

  nuevaFecha: Date | null = null;
  nuevaHoraInicio: Date | null = null;
  nuevaHoraFin: Date | null = null;
  /** Se intentó crear: muestra los errores de los campos. */
  readonly intentoCrear = signal(false);
  readonly hoy = new Date();

  constructor(
    private http: HttpClient,
    public auth: AuthService
  ) {}

  ngOnInit(): void {
    this.cargarFechas();
  }

  cargarFechas(): void {
    this.cargando.set(true);
    this.http.get<FechaDegustacion[]>(`${API_URL}/degustaciones/fechas`).subscribe({ next: (data) => {
      this.fechas.set(data);
      this.cargando.set(false);
    }, error: () => this.cargando.set(false) });
  }

  abrirNueva(): void {
    this.nuevaFecha = null;
    this.nuevaHoraInicio = null;
    this.nuevaHoraFin = null;
    this.intentoCrear.set(false);
    this.dialogoVisible.set(true);
  }

  private formatearFecha(fecha: Date): string {
    return fechaLocalISO(fecha);
  }

  private formatearHora(fecha: Date): string {
    return fecha.toTimeString().split(' ')[0].substring(0, 5);
  }

  /** Errores de la fecha nueva: fecha de hoy en adelante, hora de inicio y fin después del inicio. */
  erroresFecha(): { fecha?: string; inicio?: string; fin?: string } {
    const e: { fecha?: string; inicio?: string; fin?: string } = {};
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);
    if (!this.nuevaFecha) e.fecha = 'Elegí la fecha.';
    else if (new Date(this.nuevaFecha).setHours(0, 0, 0, 0) < hoy.getTime()) e.fecha = 'La fecha ya pasó.';
    if (!this.nuevaHoraInicio) e.inicio = 'Elegí la hora de inicio.';
    if (this.nuevaHoraInicio && this.nuevaHoraFin) {
      const min = (d: Date) => d.getHours() * 60 + d.getMinutes();
      if (min(this.nuevaHoraFin) <= min(this.nuevaHoraInicio)) e.fin = 'Debe ser después de la hora de inicio.';
    }
    return e;
  }

  crearFecha(): void {
    this.intentoCrear.set(true);
    if (Object.keys(this.erroresFecha()).length) return;
    if (!this.nuevaFecha || !this.nuevaHoraInicio) return;
    this.guardando.set(true);
    this.http.post(`${API_URL}/degustaciones/fechas`, {
      fecha: this.formatearFecha(this.nuevaFecha),
      hora_inicio: this.formatearHora(this.nuevaHoraInicio),
      hora_fin: this.nuevaHoraFin ? this.formatearHora(this.nuevaHoraFin) : null,
    }).subscribe({ next: () => {
      this.guardando.set(false);
      this.dialogoVisible.set(false);
      this.cargarFechas();
    }, error: () => this.guardando.set(false) });
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
    this.http.get<Agendado[]>(`${API_URL}/degustaciones/fechas/${fecha.id_fecha_degustacion}/agendados`).subscribe({ next: (data) => {
      this.agendados.set(data);
      this.cargandoAgendados.set(false);
    }, error: () => this.cargandoAgendados.set(false) });
  }

  /** Abre el reporte de degustación (el mismo de Reportes) de esta sesión, listo para imprimir. */
  imprimir(): void {
    const fecha = this.fechaSeleccionada();
    if (!fecha) return;

    // La pestaña se abre ya, dentro del clic: si se abre al llegar el PDF, el navegador la bloquea
    const ventana = window.open('', '_blank');
    if (ventana) {
      ventana.document.write(paginaCargando(document.documentElement.classList.contains('app-dark')));
      ventana.document.close();
    }
    this.imprimiendo.set(true);

    this.http.get(`${API_URL}/degustaciones/fechas/${fecha.id_fecha_degustacion}/pdf`, { responseType: 'blob' }).subscribe({
      next: (pdf) => {
        const url = URL.createObjectURL(pdf);
        if (ventana) ventana.location.href = url;
        else window.open(url, '_blank');
        setTimeout(() => URL.revokeObjectURL(url), 60_000);
        this.imprimiendo.set(false);
      },
      error: () => {
        ventana?.close();
        this.imprimiendo.set(false);
      },
    });
  }
}