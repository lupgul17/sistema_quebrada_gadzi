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

interface Servicio {
  id_servicio: number;
  nombre: string;
  precio_base: number;
  unidad_medida: string;
  activo: boolean;
  id_categoria_servicio: number;
  categoria: string;
}

interface CategoriaServicio {
  id_categoria_servicio: number;
  descripcion: string;
}

@Component({
  selector: 'app-servicios-list',
  standalone: true,
  imports: [
    CommonModule, FormsModule, ReactiveFormsModule, TableModule, Select,
    InputText, InputNumber, Checkbox, Button, Dialog, Message,
  ],
  templateUrl: './servicios-list.html',
  styleUrl: './servicios-list.scss',
})
export class ServiciosList implements OnInit {
  readonly servicios = signal<Servicio[]>([]);
  readonly categorias = signal<CategoriaServicio[]>([]);
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
      id_categoria_servicio: this.fb.control<number | null>(null, Validators.required),
      nombre: ['', Validators.required],
      precio_base: this.fb.control<number | null>(null, Validators.required),
      unidad_medida: ['', Validators.required],
      activo: [true],
    });
  }

  ngOnInit(): void {
    this.http.get<CategoriaServicio[]>(`${API_URL}/catalogos/categorias-servicio`).subscribe((data) => this.categorias.set(data));
    this.cargarServicios();
  }

  cargarServicios(): void {
    const url = this.categoriaFiltro
      ? `${API_URL}/servicios?id_categoria_servicio=${this.categoriaFiltro}`
      : `${API_URL}/servicios`;
    this.http.get<Servicio[]>(url).subscribe((data) => this.servicios.set(data));
  }

  abrirNuevo(): void {
    this.editandoId.set(null);
    this.form.reset({ activo: true });
    this.error.set(null);
    this.dialogoVisible.set(true);
  }

  abrirEditar(servicio: Servicio): void {
    this.editandoId.set(servicio.id_servicio);
    this.form.setValue({
      id_categoria_servicio: servicio.id_categoria_servicio,
      nombre: servicio.nombre,
      precio_base: servicio.precio_base,
      unidad_medida: servicio.unidad_medida,
      activo: servicio.activo,
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
      ? this.http.put(`${API_URL}/servicios/${id}`, body)
      : this.http.post(`${API_URL}/servicios`, body);

    peticion.subscribe({
      next: () => {
        this.guardando.set(false);
        this.dialogoVisible.set(false);
        this.cargarServicios();
      },
      error: (err) => {
        this.guardando.set(false);
        this.error.set(err.error?.error ?? 'Error al guardar el servicio');
      },
    });
  }
}