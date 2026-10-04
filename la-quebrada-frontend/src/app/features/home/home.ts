import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Card } from 'primeng/card';
import { EventosCalendario } from './eventos-calendario/eventos-calendario';
import { API_URL } from '../../core/api-config';
import { TemaService } from '../../core/tema.service';

interface EventoResumen {
  id_evento: number;
  fecha: string;
  cliente: string;
  tipo_evento: string | null;
  locaciones: string | null;
}

interface EventoPendientePago {
  id_evento: number;
  fecha: string;
  cliente: string;
  saldo_pendiente: number;
  porcentaje_pagado: number;
}

interface CotizacionPorVencer {
  id_cotizacion: number;
  id_evento: number;
  cliente: string;
  dias_restantes: number;
}

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, Card, EventosCalendario],
  templateUrl: './home.html',
  styleUrl: './home.scss',
})
export class Home implements OnInit {
  readonly eventosProximos = signal<EventoResumen[]>([]);
  readonly eventosPendientesPago = signal<EventoPendientePago[]>([]);
  readonly cotizacionesPorVencer = signal<CotizacionPorVencer[]>([]);

  constructor(
    private http: HttpClient,
    private router: Router,
    private temaService: TemaService
  ) {}

  ngOnInit(): void {
    const hoy = new Date().toISOString().split('T')[0];

    this.http.get<EventoResumen[]>(`${API_URL}/eventos?fecha_desde=${hoy}&estado=confirmado`).subscribe((data) => {
      const ordenados = [...data].sort((a, b) => a.fecha.localeCompare(b.fecha));
      this.eventosProximos.set(ordenados.slice(0, 5));
    });

    this.http.get<EventoPendientePago[]>(`${API_URL}/eventos/pendientes-pago`).subscribe((data) => {
      this.eventosPendientesPago.set(data.slice(0, 5));
    });

    this.http.get<CotizacionPorVencer[]>(`${API_URL}/cotizaciones/por-vencer`).subscribe((data) => {
      this.cotizacionesPorVencer.set(data.slice(0, 5));
    });
  }

  colorLocacion(locaciones: string | null): string {
    const enGadzi = locaciones?.includes('GADZI') ?? false;
    if (this.temaService.oscuro()) return enGadzi ? '#b48ce0' : '#84a56c';
    return enGadzi ? '#7d3c98' : '#415737';
  }

  irAEvento(idEvento: number): void {
    this.router.navigate(['/eventos', idEvento]);
  }
}