import { Component, OnInit, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { Table, TableModule } from 'primeng/table';
import { InputText } from 'primeng/inputtext';
import { Button } from 'primeng/button';
import { API_URL } from '../../../core/api-config';

interface Cliente {
  id_cliente: number;
  primer_nombre: string;
  segundo_nombre: string | null;
  primer_apellido: string;
  segundo_apellido: string | null;
  telefono: string | null;
  correo: string | null;
}

@Component({
  selector: 'app-clientes-list',
  standalone: true,
  imports: [TableModule, InputText, Button, FormsModule],
  templateUrl: './clientes-list.html',
  styleUrl: './clientes-list.scss',
})
export class ClientesList implements OnInit {
  readonly clientes = signal<Cliente[]>([]);

  readonly editarButtonTokens = {
  colorScheme: {
    light: {
      root: {
        secondary: {
          background: '#E67E22',
          hoverBackground: '#D35400',
          activeBackground: '#B8460E',
          color: '#ffffff',
        },
      },
    },
  },
};
  busqueda = '';

  private readonly busquedaSubject = new Subject<string>();

  constructor(
    private http: HttpClient,
    private router: Router
  ) {
    this.busquedaSubject.pipe(debounceTime(350), distinctUntilChanged()).subscribe((texto) => {
      this.cargarClientes(texto);
    });
  }

  ngOnInit(): void {
    this.cargarClientes('');
  }

  onBusquedaChange(texto: string): void {
    this.busquedaSubject.next(texto);
  }

  cargarClientes(texto: string): void {
  const url = texto ? `${API_URL}/clientes?q=${encodeURIComponent(texto)}` : `${API_URL}/clientes`;
  this.http.get<Cliente[]>(url).subscribe((data) => {
    const conNombreCompleto = data.map((c) => ({
      ...c,
      nombre_completo: this.nombreCompleto(c),
    }));
    this.clientes.set(conNombreCompleto);
  });
}

  irADetalle(cliente: Cliente): void {
    this.router.navigate(['/clientes', cliente.id_cliente]);
  }

  irANuevo(): void {
    this.router.navigate(['/clientes/nuevo']);
  }
  irAEditar(cliente: Cliente): void {
  this.router.navigate(['/clientes', cliente.id_cliente, 'editar']);
}

  nombreCompleto(c: Cliente): string {
    return [c.primer_nombre, c.segundo_nombre, c.primer_apellido, c.segundo_apellido]
      .filter(Boolean)
      .join(' ');
  }
}