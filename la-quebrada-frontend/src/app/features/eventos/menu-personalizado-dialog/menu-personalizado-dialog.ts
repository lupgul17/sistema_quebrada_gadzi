import { Component, EventEmitter, Output, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Dialog } from 'primeng/dialog';
import { Button } from 'primeng/button';
import { Select } from 'primeng/select';
import { InputText } from 'primeng/inputtext';
import { InputNumber } from 'primeng/inputnumber';
import { Textarea } from 'primeng/textarea';
import { MultiSelect } from 'primeng/multiselect';
import { Message } from 'primeng/message';
import { API_URL } from '../../../core/api-config';
import { ERROR_EN_LINEA } from '../../../core/http-errores';

interface Componente {
  id_componente: number;
  nombre: string;
  recargo: number;
  activo: boolean;
  categoria: string;
}

interface TipoMenu {
  id_tipo_menu: number;
  descripcion: string;
}

interface MenuBase {
  id_menu: number;
  nombre: string;
  precio_base: number;
  id_tipo_menu: number;
  activo: boolean;
}

@Component({
  selector: 'app-menu-personalizado-dialog',
  standalone: true,
  imports: [CommonModule, FormsModule, Dialog, Button, Select, InputText, InputNumber, Textarea, MultiSelect, Message],
  templateUrl: './menu-personalizado-dialog.html',
  styleUrl: './menu-personalizado-dialog.scss',
})
export class MenuPersonalizadoDialog {
  @Output() guardado = new EventEmitter<void>();

  readonly visible = signal(false);
  readonly guardando = signal(false);
  readonly error = signal<string | null>(null);
  readonly componentes = signal<Componente[]>([]);
  readonly tipos = signal<TipoMenu[]>([]);
  readonly menusBase = signal<MenuBase[]>([]);
  readonly seleccionados = signal<number[]>([]);

  /** Componentes y precio del menú base elegido (para calcular el precio sugerido). */
  private readonly idsBase = signal<number[]>([]);
  private readonly precioBase = signal<number | null>(null);

  readonly grupos = computed(() => {
    const mapa = new Map<string, Componente[]>();
    for (const c of this.componentes()) {
      if (!mapa.has(c.categoria)) mapa.set(c.categoria, []);
      mapa.get(c.categoria)!.push(c);
    }
    return Array.from(mapa.entries()).map(([categoria, items]) => ({ categoria, items }));
  });

  /**
   * Elegidos por categoría, cada una es un multiselect como en el catálogo de menús.
   * Es computed para que cada arreglo mantenga su referencia entre renders: si el template
   * llamara a un método que arma un arreglo nuevo cada vez, el multiselect lo tomaría como
   * un valor distinto en cada ciclo y la pantalla se congela.
   */
  readonly seleccionPorGrupo = computed(() => {
    const elegidos = new Set(this.seleccionados());
    const porGrupo: Record<string, number[]> = {};
    for (const g of this.grupos()) {
      porGrupo[g.categoria] = g.items.map((c) => c.id_componente).filter((id) => elegidos.has(id));
    }
    return porGrupo;
  });

  /** Solo los elegidos que están a la vista (activos): los inactivos de un menú base no se cuentan ni se envían. */
  readonly elegidosVisibles = computed(() => {
    const activos = new Set(this.componentes().map((c) => c.id_componente));
    return this.seleccionados().filter((id) => activos.has(id));
  });

  /** Precio del menú base + recargo de cada componente agregado que no estaba en la base. */
  readonly precioSugerido = computed(() => {
    const base = this.precioBase();
    if (base === null) return null;
    const enBase = new Set(this.idsBase());
    const recargos = this.componentes()
      .filter((c) => this.elegidosVisibles().includes(c.id_componente) && !enBase.has(c.id_componente))
      .reduce((acc, c) => acc + Number(c.recargo || 0), 0);
    return base + recargos;
  });

  private idCotizacion: number | null = null;
  baseSeleccionada: number | null = null;
  nombre = '';
  idTipoMenu: number | null = null;
  precio: number | null = null;
  descripcion = '';
  cantidad: number | null = null; // vacío = cantidad automática (niños o adultos del evento)

  /** Si el usuario tocó el precio, deja de recalcularse solo. */
  private precioEditadoAMano = false;
  /** Últimos valores puestos automáticamente: solo se reemplazan si el usuario no los cambió. */
  private nombreAuto = '';
  private tipoAuto: number | null = null;

  constructor(private http: HttpClient) {}

  abrir(idCotizacion: number): void {
    this.idCotizacion = idCotizacion;
    this.baseSeleccionada = null;
    this.nombre = '';
    this.idTipoMenu = null;
    this.precio = null;
    this.descripcion = '';
    this.cantidad = null;
    this.precioEditadoAMano = false;
    this.nombreAuto = '';
    this.tipoAuto = null;
    this.seleccionados.set([]);
    this.idsBase.set([]);
    this.precioBase.set(null);
    this.error.set(null);

    this.http.get<Componente[]>(`${API_URL}/componentes-menu`).subscribe((data) => this.componentes.set(data.filter((c) => c.activo)));
    this.http.get<TipoMenu[]>(`${API_URL}/catalogos/tipos-menu`).subscribe((data) => this.tipos.set(data));
    this.http.get<MenuBase[]>(`${API_URL}/menus`).subscribe((data) => this.menusBase.set(data.filter((m) => m.activo)));
    this.visible.set(true);
  }

  alElegirBase(idMenu: number | null): void {
    this.error.set(null);

    if (!idMenu) {
      // "Empezar desde cero": se limpia solo lo que vino del menú base
      if (this.nombre === this.nombreAuto) this.nombre = '';
      if (this.idTipoMenu === this.tipoAuto) this.idTipoMenu = null;
      this.nombreAuto = '';
      this.tipoAuto = null;
      this.idsBase.set([]);
      this.precioBase.set(null);
      this.seleccionados.set([]);
      if (!this.precioEditadoAMano) this.precio = null;
      return;
    }

    const base = this.menusBase().find((m) => m.id_menu === idMenu);
    if (!base) return;

    // Nombre y tipo: solo si siguen vacíos o con el valor que puso la base anterior
    const nuevoNombre = `${base.nombre} (a medida)`;
    if (!this.nombre.trim() || this.nombre === this.nombreAuto) this.nombre = nuevoNombre;
    this.nombreAuto = nuevoNombre;
    if (this.idTipoMenu === null || this.idTipoMenu === this.tipoAuto) this.idTipoMenu = base.id_tipo_menu;
    this.tipoAuto = base.id_tipo_menu;
    this.precioBase.set(Number(base.precio_base));

    this.http.get<any>(`${API_URL}/menus/${idMenu}`).subscribe({
      next: (res) => {
        // Si mientras tanto eligieron otra base, esta respuesta ya no corresponde
        if (this.baseSeleccionada !== idMenu) return;
        const detalle = Array.isArray(res) ? res[0] : res;
        const activos = new Set(this.componentes().map((c) => c.id_componente));
        const ids: number[] = (detalle?.componentes_ids ?? []).filter((id: number) => activos.has(id));
        this.idsBase.set(ids);
        this.seleccionados.set(ids);
        this.aplicarPrecioSugerido();
      },
      error: () => {
        if (this.baseSeleccionada !== idMenu) return;
        this.error.set('No se pudieron cargar los componentes de ese menú. Elegilos a mano.');
      },
    });
  }

  alEditarPrecio(valor: number | null): void {
    this.precio = valor;
    this.precioEditadoAMano = true;
  }

  usarPrecioSugerido(): void {
    this.precioEditadoAMano = false;
    this.aplicarPrecioSugerido();
  }

  private aplicarPrecioSugerido(): void {
    const sugerido = this.precioSugerido();
    if (!this.precioEditadoAMano && sugerido !== null) this.precio = sugerido;
  }

  cambiarGrupo(items: Componente[], elegidos: number[]): void {
    const idsGrupo = new Set(items.map((c) => c.id_componente));
    const nuevos = elegidos ?? [];
    const actuales = this.seleccionados().filter((id) => idsGrupo.has(id));
    // Si el multiselect re-emite lo mismo, no tocar el signal (evita un ciclo de re-render)
    if (actuales.length === nuevos.length && actuales.every((id) => nuevos.includes(id))) return;
    this.seleccionados.update((lista) => [...lista.filter((id) => !idsGrupo.has(id)), ...nuevos]);
    this.aplicarPrecioSugerido();
  }

  guardar(): void {
    if (!this.idCotizacion) return;
    if (!this.nombre.trim() || !this.idTipoMenu || !this.precio || this.precio <= 0) {
      this.error.set('Completá nombre, tipo y precio.');
      return;
    }
    const componentes = this.elegidosVisibles();
    if (componentes.length === 0) {
      this.error.set('Elegí al menos un componente.');
      return;
    }

    this.guardando.set(true);
    this.error.set(null);
    this.http
      .post(`${API_URL}/cotizaciones/${this.idCotizacion}/menu-personalizado`, {
        nombre: this.nombre.trim(),
        id_tipo_menu: this.idTipoMenu,
        precio: this.precio,
        descripcion: this.descripcion || null,
        componentes,
        cantidad: this.cantidad,
      }, ERROR_EN_LINEA)
      .subscribe({
        next: () => {
          this.guardando.set(false);
          this.visible.set(false);
          this.guardado.emit();
        },
        error: (err) => {
          this.guardando.set(false);
          this.error.set(err.error?.error ?? 'No se pudo guardar el menú.');
        },
      });
  }

  cancelar(): void {
    this.visible.set(false);
  }
}