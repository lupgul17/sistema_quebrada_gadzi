import { Component, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Button } from 'primeng/button';
import { API_URL } from '../../../core/api-config';

interface EventoCalendario {
  id_evento: number;
  fecha: string;
  hora_inicio: string;
  cliente: string;
  tipo_evento: string | null;
  estado: string;
  reserva_temporal: boolean;
  locaciones: string | null;
}

interface DiaCalendario {
  fecha: Date;
  numeroDia: number;
  esDelMesActual: boolean;
  esHoy: boolean;
  eventos: EventoCalendario[];
}

const MESES = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
const DIAS_SEMANA = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

@Component({
  selector: 'app-eventos-calendario',
  standalone: true,
  imports: [CommonModule, Button],
  templateUrl: './eventos-calendario.html',
  styleUrl: './eventos-calendario.scss',
})
export class EventosCalendario implements OnInit {
  readonly anioActual = signal(new Date().getFullYear());
  readonly mesActual = signal(new Date().getMonth());
  readonly eventos = signal<EventoCalendario[]>([]);
  readonly cargando = signal(true);
  readonly diasSemana = DIAS_SEMANA;

  readonly nombreMes = computed(() => `${MESES[this.mesActual()]} ${this.anioActual()}`);

  private readonly eventosPorFecha = computed(() => {
    const mapa = new Map<string, EventoCalendario[]>();
    for (const ev of this.eventos()) {
      const clave = this.claveFechaIso(ev.fecha);
      if (!mapa.has(clave)) mapa.set(clave, []);
      mapa.get(clave)!.push(ev);
    }
    return mapa;
  });

  readonly celdas = computed<DiaCalendario[]>(() => {
    const anio = this.anioActual();
    const mes = this.mesActual();

    const primerDiaMes = new Date(Date.UTC(anio, mes, 1));
    const diaSemanaInicio = primerDiaMes.getUTCDay();
    const ultimoDiaMes = new Date(Date.UTC(anio, mes + 1, 0));
    const diasEnMes = ultimoDiaMes.getUTCDate();

    const hoy = new Date();
    const claveHoy = this.claveFechaUtc(hoy.getFullYear(), hoy.getMonth(), hoy.getDate());

    const celdas: DiaCalendario[] = [];

    for (let i = diaSemanaInicio - 1; i >= 0; i--) {
      celdas.push(this.crearCelda(new Date(Date.UTC(anio, mes, -i)), false, claveHoy));
    }
    for (let dia = 1; dia <= diasEnMes; dia++) {
      celdas.push(this.crearCelda(new Date(Date.UTC(anio, mes, dia)), true, claveHoy));
    }
    const diasFaltantes = (7 - (celdas.length % 7)) % 7;
    for (let dia = 1; dia <= diasFaltantes; dia++) {
      celdas.push(this.crearCelda(new Date(Date.UTC(anio, mes + 1, dia)), false, claveHoy));
    }

    return celdas;
  });

  constructor(
    private http: HttpClient,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.cargarMes();
  }

  private crearCelda(fecha: Date, esDelMesActual: boolean, claveHoy: string): DiaCalendario {
    const clave = this.claveFechaUtc(fecha.getUTCFullYear(), fecha.getUTCMonth(), fecha.getUTCDate());
    return {
      fecha,
      numeroDia: fecha.getUTCDate(),
      esDelMesActual,
      esHoy: clave === claveHoy,
      eventos: this.eventosPorFecha().get(clave) ?? [],
    };
  }

  private claveFechaUtc(anio: number, mes: number, dia: number): string {
    return `${anio}-${(mes + 1).toString().padStart(2, '0')}-${dia.toString().padStart(2, '0')}`;
  }

  private claveFechaIso(fechaIso: string): string {
    const d = new Date(fechaIso);
    return this.claveFechaUtc(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
  }

  cargarMes(): void {
    const anio = this.anioActual();
    const mes = this.mesActual();
    const desde = `${anio}-${(mes + 1).toString().padStart(2, '0')}-01`;
    const ultimoDia = new Date(Date.UTC(anio, mes + 1, 0)).getUTCDate();
    const hasta = `${anio}-${(mes + 1).toString().padStart(2, '0')}-${ultimoDia.toString().padStart(2, '0')}`;

    this.http.get<EventoCalendario[]>(`${API_URL}/eventos?fecha_desde=${desde}&fecha_hasta=${hasta}`).subscribe((data) => {
      this.eventos.set(data.filter((ev) => this.colorEvento(ev) !== null));
      this.cargando.set(false);
    });
  }

  colorEvento(ev: EventoCalendario): string | null {
    const esConfirmadoOMasAlla = ['confirmado', 'en_curso', 'cerrado'].includes(ev.estado);
    const esTemporal = ev.estado === 'cotizacion' && ev.reserva_temporal;

    if (!esConfirmadoOMasAlla && !esTemporal) return null;

    const enGadzi = ev.locaciones?.includes('GADZI') ?? false;

    if (enGadzi) {
      return esTemporal ? '#e67e22' : '#8e44ad';
    }
    return esTemporal ? '#f1c40f' : '#27ae60';
  }

  mesAnterior(): void {
    let mes = this.mesActual() - 1;
    let anio = this.anioActual();
    if (mes < 0) { mes = 11; anio--; }
    this.mesActual.set(mes);
    this.anioActual.set(anio);
    this.cargarMes();
  }

  mesSiguiente(): void {
    let mes = this.mesActual() + 1;
    let anio = this.anioActual();
    if (mes > 11) { mes = 0; anio++; }
    this.mesActual.set(mes);
    this.anioActual.set(anio);
    this.cargarMes();
  }

  irAEvento(idEvento: number): void {
    this.router.navigate(['/eventos', idEvento]);
  }
}