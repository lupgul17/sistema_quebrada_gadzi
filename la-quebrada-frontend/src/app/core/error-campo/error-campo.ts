import { Component, DestroyRef, Input, OnInit, inject, signal } from '@angular/core';
import { AbstractControl } from '@angular/forms';
import { merge } from 'rxjs';
import { mensajeDeError } from '../validaciones';

/**
 * Mensaje de error debajo de un campo de formulario reactivo. Aparece cuando el campo ya se tocó
 * (o se intentó guardar: markAllAsTouched) y tiene un error.
 * Uso: <app-error-campo [control]="form.controls.telefono" />
 */
@Component({
  selector: 'app-error-campo',
  standalone: true,
  template: `
    @if (mensaje(); as m) {
      <small class="error-campo" role="alert"><i class="pi pi-exclamation-circle"></i> {{ m }}</small>
    }
  `,
  styles: `
    .error-campo {
      display: flex;
      align-items: center;
      gap: 0.3rem;
      color: var(--lq-danger-fg);
      font-size: 0.78rem;
      line-height: 1.3;
    }
    .pi { font-size: 0.75rem; }
  `,
})
export class ErrorCampo implements OnInit {
  @Input({ required: true }) control!: AbstractControl;

  readonly mensaje = signal<string | null>(null);
  private readonly destroyRef = inject(DestroyRef);

  ngOnInit(): void {
    const actualizar = () =>
      this.mensaje.set(this.control.invalid && (this.control.touched || this.control.dirty) ? mensajeDeError(this.control.errors) : null);
    // events incluye touched (markAllAsTouched) además de valor y estado
    const sub = merge(this.control.events, this.control.statusChanges).subscribe(actualizar);
    this.destroyRef.onDestroy(() => sub.unsubscribe());
    actualizar();
  }
}
