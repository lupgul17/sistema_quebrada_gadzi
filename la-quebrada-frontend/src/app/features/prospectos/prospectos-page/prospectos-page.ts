import { Component, OnInit, ViewChild, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TableModule } from 'primeng/table';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { Textarea } from 'primeng/textarea';
import { API_URL } from '../../../core/api-config';
import { AuthService } from '../../../core/auth.service';
import { ProspectosPendientesService } from '../../../core/prospectos-pendientes.service';
import { ClienteFormDialog } from '../../clientes/cliente-form-dialog/cliente-form-dialog';
import { EventoFormDialog } from '../../eventos/evento-form-dialog/evento-form-dialog';

import { BuscadorTabla } from '../../../core/buscador-tabla/buscador-tabla';
interface Prospecto {
  id_prospecto: number;
  nombre: string;
  telefono: string;
  correo: string | null;
  id_tipo_evento: number | null;
  tipo_evento: string | null;
  id_salon: number | null;
  salon: string | null;
  locacion: string | null;
  fecha_tentativa: string | null;
  invitados: number | null;
  mensaje: string | null;
  estado: 'nuevo' | 'contactado' | 'convertido' | 'descartado';
  notas_internas: string | null;
  id_cliente: number | null;
  id_evento: number | null;
  fecha_creacion: string;
}

const FILTROS = [
  { valor: 'activos', label: 'Por atender' },
  { valor: 'nuevo', label: 'Nuevos' },
  { valor: 'contactado', label: 'Contactados' },
  { valor: 'convertido', label: 'Convertidos' },
  { valor: 'descartado', label: 'Descartados' },
  { valor: 'todos', label: 'Todos' },
];

@Component({
  selector: 'app-prospectos-page',
  standalone: true,
  imports: [BuscadorTabla, CommonModule, FormsModule, TableModule, Button, Dialog, Textarea, ClienteFormDialog, EventoFormDialog],
  templateUrl: './prospectos-page.html',
  styleUrl: './prospectos-page.scss',
})
export class ProspectosPage implements OnInit {
  @ViewChild('clienteFormDialog') clienteFormDialog!: ClienteFormDialog;
  @ViewChild('eventoFormDialog') eventoFormDialog!: EventoFormDialog;

  readonly filtros = FILTROS;
  readonly prospectos = signal<Prospecto[]>([]);
  readonly cargando = signal(true);
  readonly filtro = signal('activos');
  readonly seleccionado = signal<Prospecto | null>(null);
  readonly procesando = signal(false);

  notasEdicion = '';
  /** Prospecto que se está convirtiendo (entre crear el cliente y crear el evento). */
  private enConversion: Prospecto | null = null;

  readonly visibles = computed(() => {
    const f = this.filtro();
    const todos = this.prospectos();
    if (f === 'todos') return todos;
    if (f === 'activos') return todos.filter((p) => p.estado === 'nuevo' || p.estado === 'contactado');
    return todos.filter((p) => p.estado === f);
  });

  constructor(
    private http: HttpClient,
    private router: Router,
    private pendientesService: ProspectosPendientesService,
    public auth: AuthService
  ) {}

  ngOnInit(): void {
    this.cargar();
  }

  cargar(): void {
    this.http.get<Prospecto[]>(`${API_URL}/prospectos`).subscribe({
      next: (data) => {
        this.prospectos.set(data);
        this.cargando.set(false);
        // Mantener el detalle abierto sincronizado con los datos nuevos
        const sel = this.seleccionado();
        if (sel) this.seleccionado.set(data.find((p) => p.id_prospecto === sel.id_prospecto) ?? null);
      },
      error: () => this.cargando.set(false),
    });
    this.pendientesService.actualizar();
  }

  contar(valor: string): number {
    const todos = this.prospectos();
    if (valor === 'todos') return todos.length;
    if (valor === 'activos') return todos.filter((p) => p.estado === 'nuevo' || p.estado === 'contactado').length;
    return todos.filter((p) => p.estado === valor).length;
  }

  abrirDetalle(p: Prospecto): void {
    this.seleccionado.set(p);
    this.notasEdicion = p.notas_internas ?? '';
  }

  cerrarDetalle(): void {
    this.seleccionado.set(null);
  }

  /** Link de WhatsApp: si el número tiene 8 dígitos se asume Guatemala (+502). */
  linkWhatsapp(telefono: string): string {
    const digitos = telefono.replace(/\D/g, '');
    const numero = digitos.length === 8 ? `502${digitos}` : digitos;
    return `https://wa.me/${numero}`;
  }

  cambiarEstado(estado: Prospecto['estado'], extra: { id_cliente?: number; id_evento?: number } = {}): void {
    const p = this.seleccionado() ?? this.enConversion;
    if (!p) return;
    this.procesando.set(true);
    this.http
      .patch(`${API_URL}/prospectos/${p.id_prospecto}`, {
        estado,
        notas_internas: this.notasEdicion || null,
        id_cliente: extra.id_cliente ?? null,
        id_evento: extra.id_evento ?? null,
      })
      .subscribe({
        next: () => {
          this.procesando.set(false);
          this.cargar();
        },
        error: (err) => {
          this.procesando.set(false);
        },
      });
  }

  guardarNotas(): void {
    const p = this.seleccionado();
    if (p) this.cambiarEstado(p.estado);
  }

  /** Paso 1 de la conversión: crear el cliente con los datos de la solicitud. */
  convertir(): void {
    const p = this.seleccionado();
    if (!p) return;
    this.enConversion = p;
    const [primerNombre, ...resto] = p.nombre.trim().split(/\s+/);
    this.seleccionado.set(null);
    this.clienteFormDialog.abrirNuevo({
      primer_nombre: primerNombre,
      primer_apellido: resto.length ? resto[resto.length - 1] : '',
      telefono: p.telefono,
      correo: p.correo ?? '',
    });
  }

  /** Paso 2: el cliente ya existe → se marca convertido y se ofrece crear el evento. */
  onClienteCreado(idCliente: number): void {
    const p = this.enConversion;
    if (!p) return;
    this.cambiarEstado('convertido', { id_cliente: idCliente });
    this.eventoFormDialog.abrirNuevo({
      id_cliente: idCliente,
      id_tipo_evento: p.id_tipo_evento,
      fecha: p.fecha_tentativa ? new Date(`${p.fecha_tentativa}T00:00:00`) : null,
      total_adultos: p.invitados ?? 0,
      notas: p.mensaje ? `Solicitud web: ${p.mensaje}` : '',
    });
  }

  /** Paso 3 (opcional): el evento se creó → se enlaza al prospecto. */
  onEventoCreado(idEvento: number): void {
    const p = this.enConversion;
    if (!p) return;
    this.cambiarEstado('convertido', { id_evento: idEvento });
    this.enConversion = null;
  }

  irAEvento(idEvento: number): void {
    this.router.navigate(['/eventos', idEvento]);
  }

  irACliente(idCliente: number): void {
    this.router.navigate(['/clientes', idCliente]);
  }
}
