import { Pipe, PipeTransform } from '@angular/core';
import { mostrarTelefono } from './validaciones';

/** Muestra un teléfono como 5502-4196. Uso: {{ cliente.telefono | telefono }} */
@Pipe({ name: 'telefono', standalone: true })
export class TelefonoPipe implements PipeTransform {
  transform(valor: string | null | undefined): string {
    return mostrarTelefono(valor);
  }
}
