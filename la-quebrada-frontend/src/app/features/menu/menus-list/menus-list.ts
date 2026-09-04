import { Component, OnInit, signal } from '@angular/core';
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
import { API_URL } from '../../../core/api-config';
import {MultiSelect} from "primeng/multiselect";

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

@Component({
  selector: 'app-menus-list',
  standalone: true,
  imports: [
    CommonModule, FormsModule, ReactiveFormsModule, TableModule, Select,
    InputText, InputNumber, Textarea, Checkbox, Button, Dialog, Message,MultiSelect,
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

  tipoFiltro: number | null = null;
  readonly form;

  constructor(
    private fb: FormBuilder,
    private http: HttpClient
  ) {
    this.form = this.fb.group({
      nombre: ['', Validators.required],
      id_tipo_menu: this.fb.control<number | null>(null, Validators.required),
      precio_base: this.fb.control<number | null>(null, Validators.required),
      unidad_medida: ['por_persona', Validators.required],
      descripcion: [''],
      activo: [true],
      componentes: this.fb.control<number[]>([]),
    });
    this.componentesFormGroup = new FormGroup({});
  }

  ngOnInit(): void {
    this.http.get<TipoMenuOpcion[]>(`${API_URL}/catalogos/tipos-menu`).subscribe((data) => this.tiposMenu.set(data));
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
    const url = this.tipoFiltro ? `${API_URL}/menus?id_tipo_menu=${this.tipoFiltro}` : `${API_URL}/menus`;
    this.http.get<Menu[]>(url).subscribe((data) => this.menus.set(data));
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

  toggleComponente(id: number): void {
    const actuales = this.form.controls.componentes.value ?? [];
    const yaEsta = actuales.includes(id);
    this.form.controls.componentes.setValue(yaEsta ? actuales.filter((c) => c !== id) : [...actuales, id]);
  }

  componenteSeleccionado(id: number): boolean {
    return (this.form.controls.componentes.value ?? []).includes(id);
  }

  abrirNuevo(): void {
  this.editandoId.set(null);
  this.form.reset({ activo: true, unidad_medida: 'por_persona' });
  for (const g of this.grupos()) {
    this.componentesFormGroup.get(g.categoria)?.setValue([]);
  }
  this.error.set(null);
  this.dialogoVisible.set(true);
}

  abrirEditar(menu: Menu): void {
  this.editandoId.set(menu.id_menu);
  this.http.get<any>(`${API_URL}/menus/${menu.id_menu}`).subscribe((detalle) => {
    this.form.patchValue({
      nombre: detalle.nombre,
      id_tipo_menu: detalle.id_tipo_menu,
      precio_base: detalle.precio_base,
      unidad_medida: detalle.unidad_medida,
      descripcion: detalle.descripcion,
      activo: detalle.activo,
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

  this.guardando.set(true);
  this.error.set(null);

  const componentes = Object.values(this.componentesFormGroup.value).flat() as number[];
  const body = { ...this.form.getRawValue(), componentes };
  const id = this.editandoId();

  const peticion = id
    ? this.http.put(`${API_URL}/menus/${id}`, body)
    : this.http.post(`${API_URL}/menus`, body);

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
}