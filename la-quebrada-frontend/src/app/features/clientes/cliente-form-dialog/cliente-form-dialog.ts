import { Component, EventEmitter, Output, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { InputText } from 'primeng/inputtext';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { Message } from 'primeng/message';
import { API_URL } from '../../../core/api-config';
import { ERROR_EN_LINEA } from '../../../core/http-errores';
import { Validadores } from '../../../core/validaciones';
import { ErrorCampo } from '../../../core/error-campo/error-campo';

@Component({
  selector: 'app-cliente-form-dialog',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, InputText, Button, Dialog, Message, ErrorCampo],
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
    const nombre = [Validators.maxLength(80), Validadores.nombrePersona];
    this.form = this.fb.group(
      {
        primer_nombre: ['', [Validators.required, ...nombre]],
        segundo_nombre: ['', nombre],
        primer_apellido: ['', [Validators.required, ...nombre]],
        segundo_apellido: ['', nombre],
        cui: ['', Validadores.cui],
        nit: ['', [Validators.maxLength(20), Validadores.nit]],
        telefono: ['', [Validators.maxLength(20), Validadores.telefono]],
        correo: ['', [Validators.maxLength(150), Validadores.correo]],
      },
      // Sin teléfono ni correo no hay forma de contactarlo (ni de mandarle recordatorios)
      { validators: Validadores.alMenosUno('telefono', 'correo') }
    );
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
      this.error.set(
        this.form.hasError('alMenosUno') && Object.values(this.form.controls).every((c) => c.valid)
          ? 'Escribí al menos un teléfono o un correo para poder contactarlo.'
          : 'Revisá los campos marcados en rojo.'
      );
      return;
    }

    this.cargando.set(true);
    this.error.set(null);

    // Se guarda limpio: el CUI solo con dígitos (así la regla de "CUI repetido" no se salta con
    // espacios), el teléfono sin espacios ni guiones y los textos sin espacios a los lados
    const v = this.form.getRawValue();
    const limpio = (t: string | null) => (t ?? '').trim();
    const datos = {
      ...v,
      primer_nombre: limpio(v.primer_nombre),
      segundo_nombre: limpio(v.segundo_nombre),
      primer_apellido: limpio(v.primer_apellido),
      segundo_apellido: limpio(v.segundo_apellido),
      cui: limpio(v.cui).replace(/\s/g, ''),
      nit: limpio(v.nit).toUpperCase(),
      telefono: limpio(v.telefono).replace(/[\s-]/g, ''),
      correo: limpio(v.correo).toLowerCase(),
    };
    const peticion = this.esEdicion()
      ? this.http.put(`${API_URL}/clientes/${this.idCliente}`, datos, ERROR_EN_LINEA)
      : this.http.post(`${API_URL}/clientes`, datos, ERROR_EN_LINEA);

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