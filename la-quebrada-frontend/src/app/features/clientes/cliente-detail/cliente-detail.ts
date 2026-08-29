import { Component, OnInit, signal } from '@angular/core';
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

@Component({
  selector: 'app-cliente-detail',
  standalone: true,
  imports: [Button, Card],
  templateUrl: './cliente-detail.html',
  styleUrl: './cliente-detail.scss',
})
export class ClienteDetail implements OnInit {
  readonly cliente = signal<Cliente | null>(null);
  private idCliente!: string;

  constructor(
    private http: HttpClient,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.idCliente = this.route.snapshot.paramMap.get('id')!;
    this.http.get<Cliente>(`${API_URL}/clientes/${this.idCliente}`).subscribe((data) => this.cliente.set(data));
  }

  nombreCompleto(): string {
    const c = this.cliente();
    if (!c) return '';
    return [c.primer_nombre, c.segundo_nombre, c.primer_apellido, c.segundo_apellido].filter(Boolean).join(' ');
  }

  irAEditar(): void {
    this.router.navigate(['/clientes', this.idCliente, 'editar']);
  }

  volver(): void {
    this.router.navigate(['/clientes']);
  }
}