import { Component, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Select } from 'primeng/select';
import { InputNumber } from 'primeng/inputnumber';
import { Checkbox } from 'primeng/checkbox';
import { Textarea } from 'primeng/textarea';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { ProgressSpinner } from 'primeng/progressspinner';
import { API_URL } from '../../../core/api-config';

interface CotizacionResumen {
  id_cotizacion: number;
  version: number;
  activa: boolean;
  estado: string;
  total: number;
}

interface LineaMenu {
  id_cotizacion_menu: number;
  menu: string;
  tipo_menu: string;
  precio_unitario_congelado: number;
  subtotal: number;
}

interface LineaServicio {
  id_cotizacion_servicios: number;
  servicio: string;
  categoria: string;
  cantidad: number;
  precio_unitario_congelado: number;
  subtotal: number;
  tiene_descuento_pendiente: boolean;
}

interface CotizacionDetalle {
  id_cotizacion: number;
  version: number;
  fecha_cotizacion: string;
  vigencia_dias: number;
  deposito_garantia: number;
  activa: boolean;
  estado: string;
  vendedor: string | null;
  subtotal_menus: number;
  subtotal_servicios: number;
  total_descuento: number;
  total: number;
  menus: LineaMenu[];
  servicios: LineaServicio[];
  brindis: boolean;
  cantidad_mesa_principal: number | null;
  cantidad_mesas_reservadas: number | null;
  id_color_mantel: number | null;
  color_mantel: string | null;
  id_color_cubremanteles: number | null;
  color_cubremanteles: string | null;
  observaciones: string | null;
  boquitas: string | null;
}

interface MenuOpcion {
  id_menu: number;
  nombre: string;
}

interface ServicioOpcion {
  id_servicio: number;
  nombre: string;
}

interface ColorOpcion {
  id: number;
  descripcion: string;
}

interface TipoDescuentoOpcion {
  id_tipo_descuento: number;
  descripcion: string;
}

interface DescuentoLinea {
  id_descuento: number;
  tipo_descuento: string;
  porcentaje: number | null;
  monto_descontado: number;
  motivo: string | null;
  estado: string;
}

const SIGUIENTE_ESTADO_COTIZACION: Record<string, { estado: string; label: string }[]> = {
  estimada: [{ estado: 'enviada', label: 'Marcar enviada' }],
  enviada: [{ estado: 'aceptada', label: 'Marcar aceptada' }],
  aceptada: [],
  vencida: [],
  reemplazada: [],
};

@Component({
  selector: 'app-cotizacion-panel',
  standalone: true,
  imports: [CommonModule, FormsModule, Select, InputNumber, Checkbox, Textarea, Button, Dialog, ProgressSpinner],
  templateUrl: './cotizacion-panel.html',
  styleUrl: './cotizacion-panel.scss',
})
export class CotizacionPanel implements OnInit {
  @Input({ required: true }) idEvento!: number;

  readonly cotizacion = signal<CotizacionDetalle | null>(null);
  readonly versiones = signal<CotizacionResumen[]>([]);
  readonly cargandoInicial = signal(true);
  readonly procesando = signal(false);
  readonly guardandoDetalles = signal(false);
  readonly descargandoPdf = signal(false);
  readonly menusDisponibles = signal<MenuOpcion[]>([]);
  readonly serviciosDisponibles = signal<ServicioOpcion[]>([]);
  readonly coloresMantel = signal<ColorOpcion[]>([]);
  readonly coloresCubremanteles = signal<ColorOpcion[]>([]);
  readonly tiposDescuento = signal<TipoDescuentoOpcion[]>([]);
  readonly dialogoDescuentoVisible = signal(false);
  readonly lineaDescuentoActual = signal<LineaServicio | null>(null);
  readonly descuentosLinea = signal<DescuentoLinea[]>([]);
  readonly guardandoDescuento = signal(false);

  menuSeleccionado: number | null = null;
  servicioSeleccionado: number | null = null;
  cantidadServicio = 1;
  aplicaDeposito = true;

  detalleForm = {
    brindis: false,
    cantidad_mesa_principal: null as number | null,
    cantidad_mesas_reservadas: null as number | null,
    id_color_mantel: null as number | null,
    id_color_cubremanteles: null as number | null,
    observaciones: '',
    boquitas: '',
  };

  descuentoForm = {
    id_tipo_descuento: null as number | null,
    modo: 'porcentaje' as 'porcentaje' | 'monto',
    porcentaje: null as number | null,
    monto: null as number | null,
    motivo: '',
  };

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.http.get<MenuOpcion[]>(`${API_URL}/menus`).subscribe((data) => this.menusDisponibles.set(data));
    this.http.get<ServicioOpcion[]>(`${API_URL}/servicios`).subscribe((data) => this.serviciosDisponibles.set(data));
    this.http.get<any[]>(`${API_URL}/catalogos/colores-mantel`).subscribe((data) =>
      this.coloresMantel.set(data.map((c) => ({ id: c.id_color_mantel, descripcion: c.descripcion })))
    );
    this.http.get<any[]>(`${API_URL}/catalogos/colores-cubremanteles`).subscribe((data) =>
      this.coloresCubremanteles.set(data.map((c) => ({ id: c.id_color_cubremanteles, descripcion: c.descripcion })))
    );
    this.http.get<TipoDescuentoOpcion[]>(`${API_URL}/catalogos/tipos-descuento`).subscribe((data) => this.tiposDescuento.set(data));
    this.cargarCotizacionActiva();
  }

  cargarVersiones(): void {
    this.http.get<CotizacionResumen[]>(`${API_URL}/eventos/${this.idEvento}/cotizaciones`).subscribe((lista) => this.versiones.set(lista));
  }

  cargarCotizacionActiva(): void {
    this.cargandoInicial.set(true);
    this.http.get<CotizacionResumen[]>(`${API_URL}/eventos/${this.idEvento}/cotizaciones`).subscribe((lista) => {
      this.versiones.set(lista);
      const activa = lista.find((c) => c.activa);
      if (activa) {
        this.cargarDetalle(activa.id_cotizacion);
      } else {
        this.cotizacion.set(null);
        this.cargandoInicial.set(false);
      }
    });
  }

  cargarDetalle(idCotizacion: number): void {
    this.http.get<CotizacionDetalle>(`${API_URL}/cotizaciones/${idCotizacion}`).subscribe((data) => {
      this.cotizacion.set(data);
      this.aplicaDeposito = data.deposito_garantia > 0;
      this.detalleForm = {
        brindis: data.brindis,
        cantidad_mesa_principal: data.cantidad_mesa_principal,
        cantidad_mesas_reservadas: data.cantidad_mesas_reservadas,
        id_color_mantel: data.id_color_mantel,
        id_color_cubremanteles: data.id_color_cubremanteles,
        observaciones: data.observaciones ?? '',
        boquitas: data.boquitas ?? '',
      };
      this.cargandoInicial.set(false);
      this.procesando.set(false);
    });
  }

  verVersion(idCotizacion: number): void {
    this.cargarDetalle(idCotizacion);
  }

  verVersionActiva(): void {
    const activa = this.versiones().find((v) => v.activa);
    if (activa) this.cargarDetalle(activa.id_cotizacion);
  }

  guardarDetalles(): void {
    if (!this.cotizacion()) return;
    this.guardandoDetalles.set(true);
    this.http.put(`${API_URL}/cotizaciones/${this.cotizacion()!.id_cotizacion}`, this.detalleForm).subscribe(() => {
      this.guardandoDetalles.set(false);
      this.cargarDetalle(this.cotizacion()!.id_cotizacion);
    });
  }

  descargarPdf(): void {
    if (!this.cotizacion()) return;
    this.descargandoPdf.set(true);
    this.http.get(`${API_URL}/cotizaciones/${this.cotizacion()!.id_cotizacion}/pdf`, { responseType: 'blob' }).subscribe((blob) => {
      this.descargandoPdf.set(false);
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `cotizacion-v${this.cotizacion()!.version}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
    });
  }

  private montoDeposito(): number {
    return this.aplicaDeposito ? 1000 : 0;
  }

  crearCotizacion(): void {
    this.procesando.set(true);
    this.http.post<{ id_cotizacion: number }>(`${API_URL}/cotizaciones`, {
      id_evento: this.idEvento,
      vigencia_dias: 8,
      deposito_garantia: this.montoDeposito(),
    }).subscribe((res) => {
      this.cargarDetalle(res.id_cotizacion);
      this.cargarVersiones();
    });
  }

  agregarMenu(): void {
    if (!this.menuSeleccionado || !this.cotizacion()) return;
    this.procesando.set(true);
    this.http.post(`${API_URL}/cotizaciones/${this.cotizacion()!.id_cotizacion}/menu`, { id_menu: this.menuSeleccionado }).subscribe(() => {
      this.menuSeleccionado = null;
      this.cargarDetalle(this.cotizacion()!.id_cotizacion);
      this.cargarVersiones();
    });
  }

  agregarServicio(): void {
    if (!this.servicioSeleccionado || !this.cotizacion()) return;
    this.procesando.set(true);
    this.http.post(`${API_URL}/cotizaciones/${this.cotizacion()!.id_cotizacion}/servicios`, {
      id_servicio: this.servicioSeleccionado,
      cantidad: this.cantidadServicio,
    }).subscribe(() => {
      this.servicioSeleccionado = null;
      this.cantidadServicio = 1;
      this.cargarDetalle(this.cotizacion()!.id_cotizacion);
      this.cargarVersiones();
    });
  }

  quitarMenu(idLinea: number): void {
    this.procesando.set(true);
    this.http.delete(`${API_URL}/cotizaciones/menu/${idLinea}`).subscribe(() => {
      this.cargarDetalle(this.cotizacion()!.id_cotizacion);
      this.cargarVersiones();
    });
  }

  quitarServicio(idLinea: number): void {
    this.procesando.set(true);
    this.http.delete(`${API_URL}/cotizaciones/servicios/${idLinea}`).subscribe(() => {
      this.cargarDetalle(this.cotizacion()!.id_cotizacion);
      this.cargarVersiones();
    });
  }

  opcionesEstado(): { estado: string; label: string }[] {
    const c = this.cotizacion();
    return c ? SIGUIENTE_ESTADO_COTIZACION[c.estado] ?? [] : [];
  }

  cambiarEstado(nuevoEstado: string): void {
    if (!this.cotizacion()) return;
    this.procesando.set(true);
    this.http.patch(`${API_URL}/cotizaciones/${this.cotizacion()!.id_cotizacion}/estado`, { estado: nuevoEstado }).subscribe(() => {
      this.cargarDetalle(this.cotizacion()!.id_cotizacion);
      this.cargarVersiones();
    });
  }

  abrirDescuentos(linea: LineaServicio): void {
    this.lineaDescuentoActual.set(linea);
    this.descuentoForm = { id_tipo_descuento: null, modo: 'porcentaje', porcentaje: null, monto: null, motivo: '' };
    this.cargarDescuentosLinea(linea.id_cotizacion_servicios);
    this.dialogoDescuentoVisible.set(true);
  }

  cargarDescuentosLinea(idLinea: number): void {
    this.http.get<DescuentoLinea[]>(`${API_URL}/cotizaciones/servicios/${idLinea}/descuentos`).subscribe((data) => this.descuentosLinea.set(data));
  }

  crearDescuento(): void {
    const linea = this.lineaDescuentoActual();
    if (!linea || !this.descuentoForm.id_tipo_descuento) return;
    this.guardandoDescuento.set(true);
    this.http.post<{ id_descuento: number }>(`${API_URL}/cotizaciones/servicios/${linea.id_cotizacion_servicios}/descuentos`, {
      id_tipo_descuento: this.descuentoForm.id_tipo_descuento,
      porcentaje: this.descuentoForm.modo === 'porcentaje' ? this.descuentoForm.porcentaje : null,
      monto_descontado: this.descuentoForm.modo === 'monto' ? this.descuentoForm.monto : null,
      motivo: this.descuentoForm.motivo,
    }).subscribe(() => {
      this.guardandoDescuento.set(false);
      this.descuentoForm = { id_tipo_descuento: null, modo: 'porcentaje', porcentaje: null, monto: null, motivo: '' };
      this.cargarDescuentosLinea(linea.id_cotizacion_servicios);
    });
  }

  resolverDescuento(idDescuento: number, estado: 'aprobado' | 'rechazado'): void {
    const linea = this.lineaDescuentoActual();
    if (!linea || !this.cotizacion()) return;
    this.http.patch(`${API_URL}/cotizaciones/descuentos/${idDescuento}`, { estado }).subscribe(() => {
      this.cargarDescuentosLinea(linea.id_cotizacion_servicios);
      this.cargarDetalle(this.cotizacion()!.id_cotizacion);
      this.cargarVersiones();
    });
  }

  cerrarDialogoDescuento(): void {
    this.dialogoDescuentoVisible.set(false);
  }
}