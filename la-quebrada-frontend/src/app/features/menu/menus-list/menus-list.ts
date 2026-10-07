import { Component, OnInit, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, FormControl, Validators } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { Select } from 'primeng/select';
import { InputText } from 'primeng/inputtext';
import { InputNumber } from 'primeng/inputnumber';
import { Textarea } from 'primeng/textarea';
import { Checkbox } from 'primeng/checkbox';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { Message } from 'primeng/message';
import { SelectButton } from 'primeng/selectbutton';
import { Tooltip } from 'primeng/tooltip';
import { API_URL } from '../../../core/api-config';
import { AuthService } from '../../../core/auth.service';
import { MultiSelect } from 'primeng/multiselect';
import { ERROR_EN_LINEA } from '../../../core/http-errores';
import { AreaMenu, FilaArea, opcionesDeAreas, separarAreas, textoDisponibilidad, unirAreas } from '../../../core/menus';

interface Menu {
  id_menu: number;
  nombre: string;
  precio_base: number;
  unidad_medida: string;
  descripcion: string | null;
  activo: boolean;
  id_tipo_menu: number;
  tipo_menu: string;
  componentes: string;
  disponibilidad: AreaMenu[];
}

interface TipoMenuOpcion {
  id_tipo_menu: number;
  descripcion: string;
}

interface ComponenteMenuOpcion {
  id_componente: number;
  nombre: string;
  recargo: number;
  categoria: string;
}

type ModoDisponibilidad = 'todos' | 'restringido';

@Component({
  selector: 'app-menus-list',
  standalone: true,
  imports: [
    CommonModule, FormsModule, ReactiveFormsModule, TableModule, Select,
    InputText, InputNumber, Textarea, Checkbox, Button, Dialog, Message, MultiSelect, SelectButton, Tooltip,
  ],
  templateUrl: './menus-list.html',
  styleUrl: './menus-list.scss',
})
export class MenusList implements OnInit {
  readonly menus = signal<Menu[]>([]);
  readonly tiposMenu = signal<TipoMenuOpcion[]>([]);
  readonly componentesDisponibles = signal<ComponenteMenuOpcion[]>([]);
  readonly dialogoVisible = signal(false);
  readonly guardando = signal(false);
  readonly error = signal<string | null>(null);
  readonly editandoId = signal<number | null>(null);
  readonly grupos = signal<{ categoria: string; componentes: ComponenteMenuOpcion[] }[]>([]);
  readonly componentesFormGroup: FormGroup;

  /** Locaciones con sus salones, para elegir y filtrar dónde se ofrece cada menú. */
  readonly areas = signal<FilaArea[]>([]);
  readonly opcionesAreas = computed(() => opcionesDeAreas(this.areas()));
  /** Filtro del catálogo: además de las áreas, la opción de ver solo los de "todos lados". */
  readonly opcionesFiltroArea = computed(() => [
    { label: 'Disponibilidad', items: [{ label: 'Solo "todos lados"', value: 'todos' }] },
    ...this.opcionesAreas(),
  ]);
  readonly modosDisponibilidad: { label: string; value: ModoDisponibilidad }[] = [
    { label: 'Todos lados', value: 'todos' },
    { label: 'Solo en…', value: 'restringido' },
  ];
  readonly textoDisponibilidad = textoDisponibilidad;

  // Duplicar: misma receta, otro precio y/o área (ej. la copia de GADZI con precio menor)
  readonly dialogoDuplicarVisible = signal(false);
  readonly menuADuplicar = signal<Menu | null>(null);
  readonly duplicando = signal(false);
  readonly errorDuplicar = signal<string | null>(null);
  duplicarForm = { nombre: '', precio_base: null as number | null, modo: 'restringido' as ModoDisponibilidad, areas: [] as string[] };

  tipoFiltro: number | null = null;
  areaFiltro: string | null = null;
  readonly form;

  constructor(
    private fb: FormBuilder,
    private http: HttpClient,
    public auth: AuthService
  ) {
    this.form = this.fb.group({
      nombre: ['', Validators.required],
      id_tipo_menu: this.fb.control<number | null>(null, Validators.required),
      precio_base: this.fb.control<number | null>(null, Validators.required),
      unidad_medida: ['por_persona', Validators.required],
      descripcion: [''],
      activo: [true],
      componentes: this.fb.control<number[]>([]),
      modo_disponibilidad: this.fb.control<ModoDisponibilidad>('todos'),
      areas: this.fb.control<string[]>([]),
    });
    this.componentesFormGroup = new FormGroup({});
  }

  ngOnInit(): void {
    this.http.get<TipoMenuOpcion[]>(`${API_URL}/catalogos/tipos-menu`).subscribe((data) => this.tiposMenu.set(data));
    this.http.get<FilaArea[]>(`${API_URL}/salones/areas`).subscribe((data) => this.areas.set(data));
    this.http.get<ComponenteMenuOpcion[]>(`${API_URL}/componentes-menu`).subscribe((data) => {
      this.componentesDisponibles.set(data);
      const agrupados = this.agruparPorCategoria(data);
      this.grupos.set(agrupados);
      for (const g of agrupados) {
        this.componentesFormGroup.addControl(g.categoria, this.fb.control<number[]>([]));
      }
    });
    this.cargarMenus();
  }

  cargarMenus(): void {
    const params = new URLSearchParams();
    if (this.tipoFiltro) params.set('id_tipo_menu', String(this.tipoFiltro));
    if (this.areaFiltro === 'todos') params.set('sin_restriccion', 'true');
    else if (this.areaFiltro?.startsWith('L:')) params.set('id_locacion', this.areaFiltro.slice(2));
    else if (this.areaFiltro?.startsWith('S:')) params.set('id_salon', this.areaFiltro.slice(2));
    const consulta = params.toString();
    this.http.get<Menu[]>(`${API_URL}/menus${consulta ? '?' + consulta : ''}`).subscribe((data) => this.menus.set(data));
  }

  private agruparPorCategoria(data: ComponenteMenuOpcion[]): { categoria: string; componentes: ComponenteMenuOpcion[] }[] {
    const mapa = new Map<string, ComponenteMenuOpcion[]>();
    for (const c of data) {
      if (!mapa.has(c.categoria)) mapa.set(c.categoria, []);
      mapa.get(c.categoria)!.push(c);
    }
    return Array.from(mapa.entries()).map(([categoria, componentes]) => ({ categoria, componentes }));
  }

  getControl(categoria: string): FormControl<number[]> {
    return this.componentesFormGroup.get(categoria) as FormControl<number[]>;
  }

  abrirNuevo(): void {
    this.editandoId.set(null);
    this.form.reset({ activo: true, unidad_medida: 'por_persona', modo_disponibilidad: 'todos', areas: [] });
    for (const g of this.grupos()) {
      this.componentesFormGroup.get(g.categoria)?.setValue([]);
    }
    this.error.set(null);
    this.dialogoVisible.set(true);
  }

  abrirEditar(menu: Menu): void {
    this.editandoId.set(menu.id_menu);
    this.http.get<any>(`${API_URL}/menus/${menu.id_menu}`).subscribe((detalle) => {
      const areas = unirAreas(detalle.locaciones_ids, detalle.salones_ids);
      this.form.patchValue({
        nombre: detalle.nombre,
        id_tipo_menu: detalle.id_tipo_menu,
        precio_base: detalle.precio_base,
        unidad_medida: detalle.unidad_medida,
        descripcion: detalle.descripcion,
        activo: detalle.activo,
        modo_disponibilidad: areas.length ? 'restringido' : 'todos',
        areas,
      });
      const seleccionados: number[] = detalle.componentes_ids ?? [];
      for (const g of this.grupos()) {
        const idsDeCategoria = g.componentes.map((c) => c.id_componente);
        this.componentesFormGroup.get(g.categoria)?.setValue(seleccionados.filter((id) => idsDeCategoria.includes(id)));
      }
    });
    this.error.set(null);
    this.dialogoVisible.set(true);
  }

  cerrarDialogo(): void {
    this.dialogoVisible.set(false);
  }

  guardar(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { modo_disponibilidad, areas, ...datos } = this.form.getRawValue();
    if (modo_disponibilidad === 'restringido' && !(areas ?? []).length) {
      this.error.set('Elegí al menos un área, o marcá "Todos lados".');
      return;
    }

    this.guardando.set(true);
    this.error.set(null);

    const componentes = Object.values(this.componentesFormGroup.value).flat() as number[];
    // "Todos lados" = sin áreas; la base de datos lo interpreta así
    const disponibilidad = modo_disponibilidad === 'restringido' ? separarAreas(areas ?? []) : { locaciones: [], salones: [] };
    const body = { ...datos, componentes, ...disponibilidad };
    const id = this.editandoId();

    const peticion = id
      ? this.http.put(`${API_URL}/menus/${id}`, body, ERROR_EN_LINEA)
      : this.http.post(`${API_URL}/menus`, body, ERROR_EN_LINEA);

    peticion.subscribe({
      next: () => {
        this.guardando.set(false);
        this.dialogoVisible.set(false);
        this.cargarMenus();
      },
      error: (err) => {
        this.guardando.set(false);
        this.error.set(err.error?.error ?? 'Error al guardar el menú');
      },
    });
  }

  abrirDuplicar(menu: Menu): void {
    this.menuADuplicar.set(menu);
    // Mismo nombre y precio de partida; el área se elige de nuevo (lo normal es otra área)
    this.duplicarForm = { nombre: menu.nombre, precio_base: Number(menu.precio_base), modo: 'restringido', areas: [] };
    this.errorDuplicar.set(null);
    this.dialogoDuplicarVisible.set(true);
  }

  confirmarDuplicar(): void {
    const menu = this.menuADuplicar();
    const f = this.duplicarForm;
    if (!menu) return;
    if (!f.nombre.trim() || !f.precio_base || f.precio_base <= 0) {
      this.errorDuplicar.set('Completá el nombre y un precio mayor a 0.');
      return;
    }
    if (f.modo === 'restringido' && !f.areas.length) {
      this.errorDuplicar.set('Elegí al menos un área, o marcá "Todos lados".');
      return;
    }

    this.duplicando.set(true);
    this.errorDuplicar.set(null);
    const disponibilidad = f.modo === 'restringido' ? separarAreas(f.areas) : { locaciones: [], salones: [] };
    this.http
      .post(`${API_URL}/menus/${menu.id_menu}/duplicar`, { nombre: f.nombre.trim(), precio_base: f.precio_base, ...disponibilidad }, ERROR_EN_LINEA)
      .subscribe({
        next: () => {
          this.duplicando.set(false);
          this.dialogoDuplicarVisible.set(false);
          this.cargarMenus();
        },
        error: (err) => {
          this.duplicando.set(false);
          this.errorDuplicar.set(err.error?.error ?? 'No se pudo duplicar el menú');
        },
      });
  }
}
