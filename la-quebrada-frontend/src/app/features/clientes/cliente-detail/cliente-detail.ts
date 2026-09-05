import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute, Router } from '@angular/router';
import { Button } from 'primeng/button';
import { Card } from 'primeng/card';
import { API_URL } from '../../../core/api-config';

interface Cliente {
  id_cliente: number;
  primer_nombre: string;
  segundo_nombre: string | null;
  primer_apellido: string;
  segundo_apellido: string | null;
  cui: string | null;
  nit: string | null;
  telefono: string | null;
  correo: string | null;
}

interface EventoCliente {
  id_evento: number;
  fecha: string;
  estado: string;
  tipo_evento: string | null;
  salones: string;
}

interface PagoCliente {
  id_pago: number;
  id_evento: number;
  fecha_pago: string;
  monto: number;
  concepto: string;
  estado: string;
}

@Component({
  selector: 'app-cliente-detail',
  standalone: true,
  imports: [CommonModule, Button, Card],
  templateUrl: './cliente-detail.html',
  styleUrl: './cliente-detail.scss',
})
export class ClienteDetail implements OnInit {
  readonly cliente = signal<Cliente | null>(null);
  readonly eventos = signal<EventoCliente[]>([]);
  readonly pagos = signal<PagoCliente[]>([]);
  private idCliente!: string;

  constructor(
    private http: HttpClient,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.idCliente = this.route.snapshot.paramMap.get('id')!;
    this.http.get<Cliente>(`${API_URL}/clientes/${this.idCliente}`).subscribe((data) => this.cliente.set(data));
    this.http.get<EventoCliente[]>(`${API_URL}/eventos?id_cliente=${this.idCliente}`).subscribe((data) => this.eventos.set(data));
    this.http.get<PagoCliente[]>(`${API_URL}/clientes/${this.idCliente}/pagos`).subscribe((data) => this.pagos.set(data));
  }

  nombreCompleto(): string {
    const c = this.cliente();
    if (!c) return '';
    return [c.primer_nombre, c.segundo_nombre, c.primer_apellido, c.segundo_apellido].filter(Boolean).join(' ');
  }

  irAEditar(): void {
    this.router.navigate(['/clientes', this.idCliente, 'editar']);
  }

  irAEvento(idEvento: number): void {
    this.router.navigate(['/eventos', idEvento]);
  }
  colorEstadoPago(estado: string): string {
  if (estado === 'verificado') return '#155724';
  if (estado === 'rechazado') return '#721c24';
  return '#856404'; // pendiente
}

colorEstadoEvento(estado: string): string {
  if (estado === 'cancelado') return '#721c24';
  if (estado === 'cotizacion') return '#856404';
  return '#155724'; // confirmado, en_curso, cerrado
}
  volver(): void {
    this.router.navigate(['/clientes']);
  }
}