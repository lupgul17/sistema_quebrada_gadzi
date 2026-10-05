import { Component, EventEmitter, Output, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { InputText } from 'primeng/inputtext';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { Message } from 'primeng/message';
import { API_URL } from '../../../core/api-config';

@Component({
  selector: 'app-cliente-form-dialog',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, InputText, Button, Dialog, Message],
  templateUrl: './cliente-form-dialog.html',
  styleUrl: './cliente-form-dialog.scss',
})
export class ClienteFormDialog {
  @Output() guardado = new EventEmitter<void>();
  /** Solo al crear: emite el id del cliente nuevo (lo usa la conversión de prospectos). */
  @Output() creado = new EventEmitter<number>();

  readonly visible = signal(false);
  readonly cargando = signal(false);
  readonly error = signal<string | null>(null);
  readonly esEdicion = signal(false);
  readonly form;

  private idCliente: number | null = null;

  constructor(
    private fb: FormBuilder,
    private http: HttpClient
  ) {
    this.form = this.fb.group({
      primer_nombre: ['', Validators.required],
      segundo_nombre: [''],
      primer_apellido: ['', Validators.required],
      segundo_apellido: [''],
      cui: [''],
      nit: [''],
      telefono: [''],
      correo: [''],
    });
  }

  abrirNuevo(datosIniciales?: Partial<{ primer_nombre: string; primer_apellido: string; telefono: string; correo: string }>): void {
    this.idCliente = null;
    this.esEdicion.set(false);
    this.form.reset(datosIniciales ?? {});
    this.error.set(null);
    this.visible.set(true);
  }

  abrirEditar(idCliente: number): void {
    this.idCliente = idCliente;
    this.esEdicion.set(true);
    this.error.set(null);
    this.http.get<any>(`${API_URL}/clientes/${idCliente}`).subscribe((cliente) => {
      this.form.patchValue(cliente);
    });
    this.visible.set(true);
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.cargando.set(true);
    this.error.set(null);

    const datos = this.form.getRawValue();
    const peticion = this.esEdicion()
      ? this.http.put(`${API_URL}/clientes/${this.idCliente}`, datos)
      : this.http.post(`${API_URL}/clientes`, datos);

    peticion.subscribe({
      next: (res: any) => {
        this.cargando.set(false);
        this.visible.set(false);
        this.guardado.emit();
        if (!this.esEdicion() && res?.id_cliente) this.creado.emit(res.id_cliente);
      },
      error: (err) => {
        this.cargando.set(false);
        this.error.set(err.error?.error ?? 'Error al guardar el cliente');
      },
    });
  }

  cancelar(): void {
    this.visible.set(false);
  }
}