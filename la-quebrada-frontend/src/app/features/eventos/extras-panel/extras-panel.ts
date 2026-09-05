import { Component, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Select } from 'primeng/select';
import { InputNumber } from 'primeng/inputnumber';
import { InputText } from 'primeng/inputtext';
import { Button } from 'primeng/button';
import { API_URL } from '../../../core/api-config';
import { SaldoEventoService } from '../../../core/saldo-evento.service';

interface ExtraServicio {
  id_extras_servicios: number;
  id_servicio: number | null;
  servicio: string | null;
  id_tipo_cargo_extra: number;
  tipo_cargo_extra: string;
  descripcion: string | null;
  cantidad: number;
  precio_unitario: number;
  subtotal: number;
  estado: string;
}

interface ExtraMenu {
  id_extras_menu: number;
  id_menu: number | null;
  menu: string | null;
  descripcion: string | null;
  cantidad: number;
  precio_base: number;
  subtotal: number;
  estado: string;
}

interface ExtrasEvento {
  id_extra: number | null;
  total: number;
  servicios: ExtraServicio[];
  menus: ExtraMenu[];
}

interface ServicioOpcion {
  id_servicio: number;
  nombre: string;
  precio_base: number;
}

interface MenuOpcion {
  id_menu: number;
  nombre: string;
  precio_base: number;
}

interface TipoCargoOpcion {
  id_tipo_cargo_extra: number;
  descripcion: string;
}

@Component({
  selector: 'app-extras-panel',
  standalone: true,
  imports: [CommonModule, FormsModule, Select, InputNumber, InputText, Button],
  templateUrl: './extras-panel.html',
  styleUrl: './extras-panel.scss',
})
export class ExtrasPanel implements OnInit {
  @Input({ required: true }) idEvento!: number;

  readonly extras = signal<ExtrasEvento | null>(null);
  readonly cargando = signal(true);
  readonly procesandoServicio = signal(false);
  readonly procesandoMenu = signal(false);
  readonly serviciosDisponibles = signal<ServicioOpcion[]>([]);
  readonly menusDisponibles = signal<MenuOpcion[]>([]);
  readonly tiposCargo = signal<TipoCargoOpcion[]>([]);

  servicioForm = {
    id_tipo_cargo_extra: null as number | null,
    modo: 'catalogo' as 'catalogo' | 'personalizado',
    id_servicio: null as number | null,
    descripcion: '',
    cantidad: 1,
    precio_unitario: null as number | null,
  };

  menuForm = {
    modo: 'catalogo' as 'catalogo' | 'personalizado',
    id_menu: null as number | null,
    descripcion: '',
    cantidad: 1,
    precio_base: null as number | null,
  };

  constructor(
  private http: HttpClient,
  private saldoService: SaldoEventoService
) {}

  ngOnInit(): void {
    this.http.get<ServicioOpcion[]>(`${API_URL}/servicios`).subscribe((data) => this.serviciosDisponibles.set(data));
    this.http.get<MenuOpcion[]>(`${API_URL}/menus`).subscribe((data) => this.menusDisponibles.set(data));
    this.http.get<TipoCargoOpcion[]>(`${API_URL}/catalogos/tipos-cargo-extra`).subscribe((data) => this.tiposCargo.set(data));
    this.cargarExtras();
  }

 cargarExtras(): void {
  this.http.get<ExtrasEvento>(`${API_URL}/eventos/${this.idEvento}/extras`).subscribe((data) => {
    this.extras.set(data);
    this.cargando.set(false);
    this.saldoService.actualizar(this.idEvento);
  });
}

  onServicioSeleccionado(idServicio: number | null): void {
    const servicio = this.serviciosDisponibles().find((s) => s.id_servicio === idServicio);
    if (servicio) this.servicioForm.precio_unitario = servicio.precio_base;
  }

  onMenuSeleccionado(idMenu: number | null): void {
    const menu = this.menusDisponibles().find((m) => m.id_menu === idMenu);
    if (menu) this.menuForm.precio_base = menu.precio_base;
  }

 agregarServicio(): void {
  const f = this.servicioForm;
  if (!f.id_tipo_cargo_extra || !f.cantidad || f.precio_unitario == null) return;
  if (f.modo === 'catalogo' && !f.id_servicio) return;
  if (f.modo === 'personalizado' && !f.descripcion.trim()) return;

  this.procesandoServicio.set(true);
  this.http.post(`${API_URL}/extras/servicio`, {
    id_evento: this.idEvento,
    id_tipo_cargo_extra: f.id_tipo_cargo_extra,
    id_servicio: f.modo === 'catalogo' ? f.id_servicio : null,
    descripcion: f.modo === 'personalizado' ? f.descripcion : null,
    cantidad: f.cantidad,
    precio_unitario: f.precio_unitario,
  }).subscribe(() => {
    this.procesandoServicio.set(false);
    this.servicioForm = { id_tipo_cargo_extra: null, modo: 'catalogo', id_servicio: null, descripcion: '', cantidad: 1, precio_unitario: null };
    this.cargarExtras();
  });
}

  agregarMenu(): void {
    const f = this.menuForm;
    if (!f.cantidad || f.precio_base == null) return;
    if (f.modo === 'catalogo' && !f.id_menu) return;
    if (f.modo === 'personalizado' && !f.descripcion.trim()) return;

    this.procesandoMenu.set(true);
    this.http.post(`${API_URL}/extras/menu`, {
      id_evento: this.idEvento,
      id_menu: f.modo === 'catalogo' ? f.id_menu : null,
      descripcion: f.modo === 'personalizado' ? f.descripcion : null,
      cantidad: f.cantidad,
      precio_base: f.precio_base,
    }).subscribe(() => {
      this.procesandoMenu.set(false);
      this.menuForm = { modo: 'catalogo', id_menu: null, descripcion: '', cantidad: 1, precio_base: null };
      this.cargarExtras();
    });
  }

  cancelarLinea(tipo: 'servicio' | 'menu', idLinea: number): void {
    this.http.patch(`${API_URL}/extras/${tipo}/${idLinea}/cancelar`, {}).subscribe(() => this.cargarExtras());
  }
}