import { Component, OnInit, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { Select } from 'primeng/select';
import { InputText } from 'primeng/inputtext';
import { InputNumber } from 'primeng/inputnumber';
import { Textarea } from 'primeng/textarea';
import { Checkbox } from 'primeng/checkbox';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { Message } from 'primeng/message';
import { MultiSelect } from 'primeng/multiselect';
import { SelectButton } from 'primeng/selectbutton';
import { Tooltip } from 'primeng/tooltip';
import { API_URL } from '../../../core/api-config';
import { AuthService } from '../../../core/auth.service';
import { ERROR_EN_LINEA } from '../../../core/http-errores';
import { AreaMenu, FilaArea, conEtiqueta, opcionesDeAreas, separarAreas, textoDisponibilidad, unirAreas } from '../../../core/menus';
import { CalculoExtra, GrupoPaquete, Paquete, TipoGrupo } from '../../../core/paquetes';

/** Menú del catálogo (GET /api/menus): las opciones de los grupos de menús. */
interface MenuCatalogo {
  id_menu: number;
  nombre: string;
  precio_base: number | string;
  activo: boolean;
  tipo_menu: string;
  disponibilidad: AreaMenu[];
}

interface Componente {
  id_componente: number;
  nombre: string;
  activo: boolean;
  categoria: string;
}

interface Servicio {
  id_servicio: number;
  nombre: string;
  precio_base: number | string;
  unidad_medida: string;
  activo: boolean;
  categoria: string;
}

interface TipoMenu {
  id_tipo_menu: number;
  descripcion: string;
}

interface OpcionAgrupada {
  label: string;
  items: { label: string; value: number }[];
}

/** Grupo en edición: opciones como ids para los multiselect. */
interface GrupoForm {
  tipo: TipoGrupo;
  nombre: string;
  cantidad_a_elegir: number;
  opciones: number[];
}

/** "Incluye": un servicio a Q0 (fijo o "1 por cada N personas") o solo un texto. */
interface IncluidoForm {
  modo: 'servicio' | 'texto';
  id_servicio: number | null;
  texto: string;
  cantidad: number;
  por_cada_personas: number | null;
}

interface ExtraForm {
  id_servicio: number | null;
  precio: number | null;
  calculo: CalculoExtra;
}

type ModoDisponibilidad = 'todos' | 'restringido';

interface PaqueteForm {
  nombre: string;
  descripcion: string;
  precio_por_persona: number | null;
  minimo_personas: number | null;
  horas_incluidas: number | null;
  id_tipo_menu: number | null;
  activo: boolean;
  grupos: GrupoForm[];
  incluidos: IncluidoForm[];
  extras: ExtraForm[];
  modo: ModoDisponibilidad;
  areas: string[];
}

const NOMBRE_GRUPO: Record<TipoGrupo, string> = { menu: '', componente: '', cortesia: 'Cortesía' };

@Component({
  selector: 'app-paquetes-list',
  standalone: true,
  imports: [
    CommonModule, FormsModule, TableModule, Select, InputText, InputNumber, Textarea, Checkbox,
    Button, Dialog, Message, MultiSelect, SelectButton, Tooltip,
  ],
  templateUrl: './paquetes-list.html',
  styleUrl: './paquetes-list.scss',
})
export class PaquetesList implements OnInit {
  readonly paquetes = signal<Paquete[]>([]);
  readonly menus = signal<MenuCatalogo[]>([]);
  readonly componentes = signal<Componente[]>([]);
  readonly servicios = signal<Servicio[]>([]);
  readonly tiposMenu = signal<TipoMenu[]>([]);
  readonly areas = signal<FilaArea[]>([]);

  readonly dialogoVisible = signal(false);
  readonly editandoId = signal<number | null>(null);
  readonly guardando = signal(false);
  readonly error = signal<string | null>(null);

  readonly dialogoDuplicarVisible = signal(false);
  readonly paqueteADuplicar = signal<Paquete | null>(null);
  readonly duplicando = signal(false);
  readonly errorDuplicar = signal<string | null>(null);

  readonly textoDisponibilidad = textoDisponibilidad;
  readonly opcionesAreas = computed(() => opcionesDeAreas(this.areas()));
  readonly modosDisponibilidad: { label: string; value: ModoDisponibilidad }[] = [
    { label: 'Todos lados', value: 'todos' },
    { label: 'Solo en…', value: 'restringido' },
  ];
  readonly modosIncluido = [
    { label: 'Servicio', value: 'servicio' },
    { label: 'Texto', value: 'texto' },
  ];
  readonly calculos: { label: string; value: CalculoExtra }[] = [
    { label: 'A mano', value: 'fijo' },
    { label: 'Por persona', value: 'por_persona' },
    { label: 'Horas extra', value: 'hora_extra' },
  ];

  /**
   * Menús activos agrupados por tipo. La etiqueta lleva precio y área para distinguir las
   * copias del mismo menú (ej. la de La Quebrada y la de GADZI).
   */
  readonly opcionesMenus = computed<OpcionAgrupada[]>(() =>
    this.agrupar(conEtiqueta(this.menus().filter((m) => m.activo)), (m) => m.tipo_menu, (m) => m.etiqueta, (m) => m.id_menu)
  );
  /** Componentes activos por categoría (ej. bebida fría: naranjada, jamaica, gaseosa). */
  readonly opcionesComponentes = computed<OpcionAgrupada[]>(() =>
    this.agrupar(this.componentes().filter((c) => c.activo), (c) => c.categoria, (c) => c.nombre, (c) => c.id_componente)
  );
  /** Servicios activos por categoría (cortesías). */
  readonly opcionesServicios = computed<OpcionAgrupada[]>(() =>
    this.agrupar(this.servicios().filter((s) => s.activo), (s) => s.categoria, (s) => s.nombre, (s) => s.id_servicio)
  );
  readonly serviciosPlanos = computed(() => this.servicios().filter((s) => s.activo));

  form: PaqueteForm = this.formVacio();
  duplicarForm = { nombre: '', precio_por_persona: null as number | null, modo: 'restringido' as ModoDisponibilidad, areas: [] as string[] };

  constructor(
    private http: HttpClient,
    public auth: AuthService
  ) {}

  ngOnInit(): void {
    this.http.get<MenuCatalogo[]>(`${API_URL}/menus`).subscribe((d) => this.menus.set(d));
    this.http.get<Componente[]>(`${API_URL}/componentes-menu`).subscribe((d) => this.componentes.set(d));
    this.http.get<Servicio[]>(`${API_URL}/servicios`).subscribe((d) => this.servicios.set(d));
    this.http.get<TipoMenu[]>(`${API_URL}/catalogos/tipos-menu`).subscribe((d) => this.tiposMenu.set(d));
    this.http.get<FilaArea[]>(`${API_URL}/salones/areas`).subscribe((d) => this.areas.set(d));
    this.cargar();
  }

  cargar(): void {
    this.http.get<Paquete[]>(`${API_URL}/paquetes`).subscribe((d) => this.paquetes.set(d));
  }

  private agrupar<T>(items: T[], grupo: (x: T) => string, label: (x: T) => string, value: (x: T) => number): OpcionAgrupada[] {
    const mapa = new Map<string, { label: string; value: number }[]>();
    for (const it of items) {
      const g = grupo(it);
      if (!mapa.has(g)) mapa.set(g, []);
      mapa.get(g)!.push({ label: label(it), value: value(it) });
    }
    return Array.from(mapa.entries()).map(([label, items]) => ({ label, items }));
  }

  private formVacio(): PaqueteForm {
    return {
      nombre: '', descripcion: '', precio_por_persona: null, minimo_personas: null, horas_incluidas: null,
      id_tipo_menu: null, activo: true, grupos: [], incluidos: [], extras: [], modo: 'todos', areas: [],
    };
  }

  /** Opciones del multiselect según el tipo de grupo (referencias estables: son computed). */
  opcionesDe(tipo: TipoGrupo): OpcionAgrupada[] {
    return tipo === 'menu' ? this.opcionesMenus() : tipo === 'componente' ? this.opcionesComponentes() : this.opcionesServicios();
  }

  nombresOpciones(g: GrupoPaquete): string {
    return g.opciones.map((o) => o.nombre).join(', ');
  }

  gruposDe(...tipos: TipoGrupo[]): GrupoForm[] {
    return this.form.grupos.filter((g) => tipos.includes(g.tipo));
  }

  abrirNuevo(): void {
    this.editandoId.set(null);
    this.form = this.formVacio();
    // Un tipo de menú por defecto (adultos): el precio por persona es por adulto
    this.form.id_tipo_menu = this.tiposMenu().find((t) => !/infantil/i.test(t.descripcion))?.id_tipo_menu ?? null;
    this.form.grupos.push({ tipo: 'menu', nombre: 'Plato fuerte', cantidad_a_elegir: 1, opciones: [] });
    this.error.set(null);
    this.dialogoVisible.set(true);
  }

  abrirEditar(p: Paquete): void {
    this.editandoId.set(p.id_paquete);
    const locaciones = p.disponibilidad.filter((a) => a.tipo === 'locacion').map((a) => a.id);
    const salones = p.disponibilidad.filter((a) => a.tipo === 'salon').map((a) => a.id);
    this.form = {
      nombre: p.nombre,
      descripcion: p.descripcion ?? '',
      precio_por_persona: Number(p.precio_por_persona),
      minimo_personas: p.minimo_personas,
      horas_incluidas: p.horas_incluidas,
      id_tipo_menu: p.id_tipo_menu,
      activo: p.activo,
      grupos: p.grupos.map((g) => ({ tipo: g.tipo, nombre: g.nombre, cantidad_a_elegir: g.cantidad_a_elegir, opciones: g.opciones.map((o) => o.id) })),
      incluidos: p.incluidos.map((i) => ({
        modo: i.id_servicio ? 'servicio' : 'texto',
        id_servicio: i.id_servicio,
        texto: i.texto ?? '',
        cantidad: i.cantidad,
        por_cada_personas: i.por_cada_personas,
      })),
      extras: p.extras.map((e) => ({ id_servicio: e.id_servicio, precio: Number(e.precio), calculo: e.calculo })),
      modo: p.disponibilidad.length ? 'restringido' : 'todos',
      areas: unirAreas(locaciones, salones),
    };
    this.error.set(null);
    this.dialogoVisible.set(true);
  }

  agregarGrupo(tipo: TipoGrupo): void {
    this.form.grupos.push({ tipo, nombre: NOMBRE_GRUPO[tipo], cantidad_a_elegir: 1, opciones: [] });
  }

  quitarGrupo(g: GrupoForm): void {
    this.form.grupos = this.form.grupos.filter((x) => x !== g);
  }

  agregarIncluido(modo: 'servicio' | 'texto'): void {
    this.form.incluidos.push({ modo, id_servicio: null, texto: '', cantidad: 1, por_cada_personas: null });
  }

  quitarIncluido(i: IncluidoForm): void {
    this.form.incluidos = this.form.incluidos.filter((x) => x !== i);
  }

  agregarExtra(): void {
    this.form.extras.push({ id_servicio: null, precio: null, calculo: 'fijo' });
  }

  quitarExtra(e: ExtraForm): void {
    this.form.extras = this.form.extras.filter((x) => x !== e);
  }

  /** Al elegir el servicio de un extra, el precio arranca en el del catálogo (después se baja). */
  alElegirServicioExtra(e: ExtraForm): void {
    const s = this.servicios().find((x) => x.id_servicio === e.id_servicio);
    if (s && e.precio === null) e.precio = Number(s.precio_base);
    if (s && /hora/i.test(s.nombre) && e.calculo === 'fijo') e.calculo = 'hora_extra';
  }

  precioCatalogo(idServicio: number | null): number | null {
    const s = this.servicios().find((x) => x.id_servicio === idServicio);
    return s ? Number(s.precio_base) : null;
  }

  guardar(): void {
    const f = this.form;
    const grupoVacio = f.grupos.find((g) => !g.opciones.length);
    const idsExtras = f.extras.map((e) => e.id_servicio);
    const problema =
      !f.nombre.trim() ? 'El nombre es obligatorio.' :
      !f.precio_por_persona || f.precio_por_persona <= 0 ? 'El precio por persona debe ser mayor a 0.' :
      !f.minimo_personas || f.minimo_personas < 1 ? 'El mínimo de personas debe ser al menos 1.' :
      !f.id_tipo_menu ? 'Elegí el tipo de menú.' :
      !this.gruposDe('menu').length ? 'Agregá al menos un grupo de menús (ej. plato fuerte).' :
      f.grupos.some((g) => !g.nombre.trim()) ? 'Cada grupo necesita un nombre.' :
      grupoVacio ? `El grupo "${grupoVacio.nombre || 'sin nombre'}" no tiene opciones.` :
      f.grupos.some((g) => g.cantidad_a_elegir > g.opciones.length) ? 'Algún grupo pide elegir más opciones de las que tiene.' :
      f.incluidos.some((i) => (i.modo === 'servicio' ? !i.id_servicio : !i.texto.trim())) ? 'Completá o quitá las filas vacías de "Incluye".' :
      f.extras.some((e) => !e.id_servicio || e.precio === null || e.precio < 0) ? 'Cada extra necesita servicio y precio.' :
      new Set(idsExtras).size !== idsExtras.length ? 'Hay un servicio repetido en los extras.' :
      f.modo === 'restringido' && !f.areas.length ? 'Elegí al menos un área, o marcá "Todos lados".' :
      null;
    if (problema) {
      this.error.set(problema);
      return;
    }

    const disponibilidad = f.modo === 'restringido' ? separarAreas(f.areas) : { locaciones: [], salones: [] };
    const body = {
      nombre: f.nombre.trim(),
      descripcion: f.descripcion,
      precio_por_persona: f.precio_por_persona,
      minimo_personas: f.minimo_personas,
      horas_incluidas: f.horas_incluidas || null,
      id_tipo_menu: f.id_tipo_menu,
      activo: f.activo,
      grupos: f.grupos,
      incluidos: f.incluidos.map((i) =>
        i.modo === 'servicio'
          ? { id_servicio: i.id_servicio, cantidad: i.cantidad || 1, por_cada_personas: i.por_cada_personas || null }
          : { texto: i.texto.trim() }
      ),
      extras: f.extras,
      ...disponibilidad,
    };

    this.guardando.set(true);
    this.error.set(null);
    const id = this.editandoId();
    const peticion = id
      ? this.http.put(`${API_URL}/paquetes/${id}`, body, ERROR_EN_LINEA)
      : this.http.post(`${API_URL}/paquetes`, body, ERROR_EN_LINEA);
    peticion.subscribe({
      next: () => {
        this.guardando.set(false);
        this.dialogoVisible.set(false);
        this.cargar();
      },
      error: (err) => {
        this.guardando.set(false);
        this.error.set(err.error?.error ?? 'No se pudo guardar el paquete');
      },
    });
  }

  abrirDuplicar(p: Paquete): void {
    this.paqueteADuplicar.set(p);
    this.duplicarForm = { nombre: p.nombre, precio_por_persona: Number(p.precio_por_persona), modo: 'restringido', areas: [] };
    this.errorDuplicar.set(null);
    this.dialogoDuplicarVisible.set(true);
  }

  confirmarDuplicar(): void {
    const p = this.paqueteADuplicar();
    const f = this.duplicarForm;
    if (!p) return;
    if (!f.nombre.trim() || !f.precio_por_persona || f.precio_por_persona <= 0) {
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
      .post(`${API_URL}/paquetes/${p.id_paquete}/duplicar`, { nombre: f.nombre.trim(), precio_por_persona: f.precio_por_persona, ...disponibilidad }, ERROR_EN_LINEA)
      .subscribe({
        next: () => {
          this.duplicando.set(false);
          this.dialogoDuplicarVisible.set(false);
          this.cargar();
        },
        error: (err) => {
          this.duplicando.set(false);
          this.errorDuplicar.set(err.error?.error ?? 'No se pudo duplicar el paquete');
        },
      });
  }
}
