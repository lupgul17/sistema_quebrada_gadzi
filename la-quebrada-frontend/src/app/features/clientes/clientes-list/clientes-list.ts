import { Component, OnInit, signal , ViewChild} from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { Table, TableModule } from 'primeng/table';
import { InputText } from 'primeng/inputtext';
import { Button } from 'primeng/button';
import { API_URL } from '../../../core/api-config';
import { AuthService } from '../../../core/auth.service';
import { ClienteFormDialog } from '../cliente-form-dialog/cliente-form-dialog';
import { TelefonoPipe } from '../../../core/telefono.pipe';

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
  imports: [TableModule, InputText, Button, FormsModule, ClienteFormDialog, TelefonoPipe],
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
          borderColor: '#E67E22',
          hoverBorderColor: '#D35400',
          color: '#ffffff',
          hoverColor: '#ffffff',
        },
      },
    },
    dark: {
      root: {
        secondary: {
          background: '#d9894a',
          hoverBackground: '#e69a5e',
          activeBackground: '#c27638',
          borderColor: '#d9894a',
          hoverBorderColor: '#e69a5e',
          color: '#0f0d0d',
          hoverColor: '#0f0d0d',
        },
      },
    },
  },
};
  busqueda = '';

  private readonly busquedaSubject = new Subject<string>();
  @ViewChild('clienteFormDialog') clienteFormDialog!: ClienteFormDialog;

  constructor(
    private http: HttpClient,
    private router: Router,
    public auth: AuthService
  ) {
    this.busquedaSubject.pipe(debounceTime(350), distinctUntilChanged()).subscribe((texto) => {
      this.cargarClientes(texto);
    });
  }

  ngOnInit(): void {
    this.cargarClientes('');
  }

  /** El teléfono se guarda sin guion: "5502-41" también encuentra 55024196. */
  sinGuiones(texto: string): string {
    return texto.replace(/[\s-]/g, '');
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

 

abrirNuevo(): void {
  this.clienteFormDialog.abrirNuevo();
}

abrirEditar(cliente: Cliente, event: Event): void {
  event.stopPropagation();
  this.clienteFormDialog.abrirEditar(cliente.id_cliente);
}

  nombreCompleto(c: Cliente): string {
    return [c.primer_nombre, c.segundo_nombre, c.primer_apellido, c.segundo_apellido]
      .filter(Boolean)
      .join(' ');
  }
}