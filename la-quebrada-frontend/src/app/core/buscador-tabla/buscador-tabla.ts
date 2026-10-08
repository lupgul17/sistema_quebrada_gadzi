import { Component, Input } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Table } from 'primeng/table';
import { IconField } from 'primeng/iconfield';
import { InputIcon } from 'primeng/inputicon';
import { InputText } from 'primeng/inputtext';

/**
 * Buscador para cualquier p-table: filtra en las columnas que la tabla declara en
 * [globalFilterFields] (sin distinguir tildes ni mayúsculas, con la espera propia de la tabla).
 * Uso: <app-buscador-tabla [tabla]="dt" placeholder="Buscar cliente..." />
 *      <p-table #dt [globalFilterFields]="['cliente', 'estado']" ...>
 */
@Component({
  selector: 'app-buscador-tabla',
  standalone: true,
  imports: [FormsModule, IconField, InputIcon, InputText],
  template: `
    <p-iconfield class="buscador">
      <p-inputicon styleClass="pi pi-search" />
      <input
        pInputText
        type="search"
        [placeholder]="placeholder"
        [attr.aria-label]="placeholder"
        [(ngModel)]="texto"
        (ngModelChange)="buscar($event)"
        (keydown.escape)="limpiar()"
      />
      @if (texto) {
        <button type="button" class="limpiar" aria-label="Limpiar búsqueda" (click)="limpiar()">
          <i class="pi pi-times"></i>
        </button>
      }
    </p-iconfield>
  `,
  styles: `
    :host { display: block; min-width: 0; }
    .buscador { position: relative; display: block; width: 18rem; max-width: 100%; }
    input { width: 100%; padding-right: 2rem; }
    /* Sin la "x" nativa del input search: usamos la nuestra */
    input::-webkit-search-cancel-button { display: none; }
    .limpiar {
      position: absolute; right: 0.5rem; top: 50%; transform: translateY(-50%);
      border: 0; background: transparent; color: var(--p-text-muted-color);
      cursor: pointer; padding: 0.25rem; line-height: 1;
    }
    @media (max-width: 640px) { .buscador { width: 100%; } }
  `,
})
export class BuscadorTabla {
  @Input({ required: true }) tabla!: Table;
  @Input() placeholder = 'Buscar...';

  texto = '';

  buscar(valor: string): void {
    this.tabla.filterGlobal((valor ?? '').trim(), 'contains');
  }

  limpiar(): void {
    this.texto = '';
    this.buscar('');
  }
}
