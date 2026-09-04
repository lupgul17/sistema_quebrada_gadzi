import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { Select } from 'primeng/select';
import { InputText } from 'primeng/inputtext';
import { InputNumber } from 'primeng/inputnumber';
import { Checkbox } from 'primeng/checkbox';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { Message } from 'primeng/message';
import { API_URL } from '../../../core/api-config';

interface ComponenteMenu {
  id_componente: number;
  nombre: string;
  recargo: number;
  activo: boolean;
  id_categoria_componente_menu: number;
  categoria: string;
}

interface CategoriaComponente {
  id_categoria_componente_menu: number;
  descripcion: string;
}

@Component({
  selector: 'app-componentes-menu-list',
  standalone: true,
  imports: [
    CommonModule, FormsModule, ReactiveFormsModule, TableModule, Select,
    InputText, InputNumber, Checkbox, Button, Dialog, Message,
  ],
  templateUrl: './componentes-menu-list.html',
  styleUrl: './componentes-menu-list.scss',
})
export class ComponentesMenuList implements OnInit {
  readonly componentes = signal<ComponenteMenu[]>([]);
  readonly categorias = signal<CategoriaComponente[]>([]);
  readonly dialogoVisible = signal(false);
  readonly guardando = signal(false);
  readonly error = signal<string | null>(null);
  readonly editandoId = signal<number | null>(null);

  categoriaFiltro: number | null = null;
  readonly form;

  constructor(
    private fb: FormBuilder,
    private http: HttpClient
  ) {
    this.form = this.fb.group({
      id_categoria_componente_menu: this.fb.control<number | null>(null, Validators.required),
      nombre: ['', Validators.required],
      recargo: this.fb.control<number>(0),
      activo: [true],
    });
  }

  ngOnInit(): void {
    this.http.get<CategoriaComponente[]>(`${API_URL}/catalogos/categorias-componente-menu`).subscribe((data) => this.categorias.set(data));
    this.cargarComponentes();
  }

  cargarComponentes(): void {
    const url = this.categoriaFiltro
      ? `${API_URL}/componentes-menu?id_categoria=${this.categoriaFiltro}`
      : `${API_URL}/componentes-menu`;
    this.http.get<ComponenteMenu[]>(url).subscribe((data) => this.componentes.set(data));
  }

  abrirNuevo(): void {
    this.editandoId.set(null);
    this.form.reset({ activo: true, recargo: 0 });
    this.error.set(null);
    this.dialogoVisible.set(true);
  }

  abrirEditar(componente: ComponenteMenu): void {
    this.editandoId.set(componente.id_componente);
    this.form.setValue({
      id_categoria_componente_menu: componente.id_categoria_componente_menu,
      nombre: componente.nombre,
      recargo: componente.recargo,
      activo: componente.activo,
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
    const body = this.form.getRawValue();
    const id = this.editandoId();

    const peticion = id
      ? this.http.put(`${API_URL}/componentes-menu/${id}`, body)
      : this.http.post(`${API_URL}/componentes-menu`, body);

    peticion.subscribe({
      next: () => {
        this.guardando.set(false);
        this.dialogoVisible.set(false);
        this.cargarComponentes();
      },
      error: (err) => {
        this.guardando.set(false);
        this.error.set(err.error?.error ?? 'Error al guardar el componente');
      },
    });
  }
}