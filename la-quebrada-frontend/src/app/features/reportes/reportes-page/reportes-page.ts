import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Select } from 'primeng/select';
import { DatePicker } from 'primeng/datepicker';
import { Button } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { API_URL } from '../../../core/api-config';

type TipoReporte = 'eventos' | 'eventos-detallado' | 'pendientes-pago' | 'degustaciones';

const REPORTES = [
  { label: 'Lista de eventos', value: 'eventos' as TipoReporte, necesitaFechas: true },
  { label: 'Lista de eventos — Detallado', value: 'eventos-detallado' as TipoReporte, necesitaFechas: true },
  { label: 'Eventos pendientes de pago', value: 'pendientes-pago' as TipoReporte, necesitaFechas: false },
  { label: 'Degustaciones — Detallado', value: 'degustaciones' as TipoReporte, necesitaFechas: true },
];

const RANGOS_RAPIDOS = [
  { label: 'Semana actual', value: 'semana' },
  { label: 'Mes actual', value: 'mes' },
  { label: 'Año actual', value: 'anio' },
  { label: 'Personalizado', value: 'personalizado' },
];

@Component({
  selector: 'app-reportes-page',
  standalone: true,
  imports: [CommonModule, FormsModule, Select, DatePicker, Button, TableModule],
  templateUrl: './reportes-page.html',
  styleUrl: './reportes-page.scss',
})
export class ReportesPage {
  readonly reportes = REPORTES;
  readonly rangosRapidos = RANGOS_RAPIDOS;
  readonly filas = signal<any[]>([]);
  readonly columnas = signal<string[]>([]);
  readonly cargando = signal(false);
  readonly descargando = signal(false);

  tipoSeleccionado: TipoReporte = 'eventos';
  rangoRapido = 'semana';
  fechaDesde: Date | null = null;
  fechaHasta: Date | null = null;

  constructor(private http: HttpClient) {}

  reporteActual() {
    return this.reportes.find((r) => r.value === this.tipoSeleccionado)!;
  }

  private formatearFecha(fecha: Date): string {
    return fecha.toISOString().split('T')[0];
  }

  private calcularRango(): { desde: string; hasta: string } | null {
    const hoy = new Date();

    if (this.rangoRapido === 'personalizado') {
      if (!this.fechaDesde || !this.fechaHasta) return null;
      return { desde: this.formatearFecha(this.fechaDesde), hasta: this.formatearFecha(this.fechaHasta) };
    }

    if (this.rangoRapido === 'semana') {
      const diaSemana = hoy.getDay();
      const inicio = new Date(hoy);
      inicio.setDate(hoy.getDate() - diaSemana);
      const fin = new Date(inicio);
      fin.setDate(inicio.getDate() + 6);
      return { desde: this.formatearFecha(inicio), hasta: this.formatearFecha(fin) };
    }

    if (this.rangoRapido === 'mes') {
      const inicio = new Date(hoy.getFullYear(), hoy.getMonth(), 1);
      const fin = new Date(hoy.getFullYear(), hoy.getMonth() + 1, 0);
      return { desde: this.formatearFecha(inicio), hasta: this.formatearFecha(fin) };
    }

    // anio
    const inicio = new Date(hoy.getFullYear(), 0, 1);
    const fin = new Date(hoy.getFullYear(), 11, 31);
    return { desde: this.formatearFecha(inicio), hasta: this.formatearFecha(fin) };
  }

  private nombresColumna(tipo: TipoReporte): string[] {
    if (tipo === 'eventos') return ['fecha', 'cliente', 'tipo_evento', 'salones', 'estado'];
    if (tipo === 'eventos-detallado') return ['fecha', 'cliente', 'tipo_evento', 'estado', 'total_adultos', 'total_pagado', 'saldo_pendiente', 'tiene_degustacion'];
    if (tipo === 'pendientes-pago') return ['fecha', 'dias_para_evento', 'cliente', 'saldo_pendiente', 'checkpoint'];
    return ['fecha_sesion', 'hora_inicio', 'cliente', 'telefono', 'menus'];
  }

  generar(): void {
    const tipo = this.tipoSeleccionado;
    this.columnas.set(this.nombresColumna(tipo));
    this.cargando.set(true);

    if (tipo === 'pendientes-pago') {
      this.http.get<any[]>(`${API_URL}/reportes/pendientes-pago`).subscribe((data) => {
        this.filas.set(data);
        this.cargando.set(false);
      });
      return;
    }

    const rango = this.calcularRango();
    if (!rango) {
      this.cargando.set(false);
      return;
    }

    this.http.get<any[]>(`${API_URL}/reportes/${tipo}?fecha_desde=${rango.desde}&fecha_hasta=${rango.hasta}`).subscribe((data) => {
      this.filas.set(
        tipo === 'degustaciones'
          ? data.map((f) => ({
              ...f,
              menus: f.menus.map((m: { menu: string; es_adicional: boolean }) => m.menu + (m.es_adicional ? ' (extra)' : '')).join(', '),
            }))
          : data
      );
      this.cargando.set(false);
    });
  }

  descargarPdf(): void {
    const tipo = this.tipoSeleccionado;
    this.descargando.set(true);

    let url = `${API_URL}/reportes/${tipo}/pdf`;
    if (tipo !== 'pendientes-pago') {
      const rango = this.calcularRango();
      if (!rango) {
        this.descargando.set(false);
        return;
      }
      url += `?fecha_desde=${rango.desde}&fecha_hasta=${rango.hasta}`;
    }

    this.http.get(url, { responseType: 'blob' }).subscribe((blob) => {
      this.descargando.set(false);
      const objectUrl = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = objectUrl;
      a.download = `reporte-${tipo}.pdf`;
      a.click();
      URL.revokeObjectURL(objectUrl);
    });
  }
}