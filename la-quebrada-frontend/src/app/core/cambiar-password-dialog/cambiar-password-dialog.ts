import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { InputText } from 'primeng/inputtext';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { Message } from 'primeng/message';
import { API_URL } from '../api-config';
import { ERROR_EN_LINEA } from '../http-errores';

@Component({
  selector: 'app-cambiar-password-dialog',
  standalone: true,
  imports: [CommonModule, FormsModule, InputText, Button, Dialog, Message],
  templateUrl: './cambiar-password-dialog.html',
  styleUrl: './cambiar-password-dialog.scss',
})
export class CambiarPasswordDialog {
  readonly visible = signal(false);
  readonly cargando = signal(false);
  readonly error = signal<string | null>(null);
  readonly exito = signal(false);

  actual = '';
  nueva = '';
  confirmar = '';

  constructor(private http: HttpClient) {}

  abrir(): void {
    this.actual = '';
    this.nueva = '';
    this.confirmar = '';
    this.error.set(null);
    this.exito.set(false);
    this.visible.set(true);
  }

  guardar(): void {
    if (this.nueva.length < 8) {
      this.error.set('La contraseña nueva debe tener al menos 8 caracteres.');
      return;
    }
    if (this.nueva !== this.confirmar) {
      this.error.set('Las contraseñas nuevas no coinciden.');
      return;
    }

    this.cargando.set(true);
    this.error.set(null);
    this.http.post(`${API_URL}/auth/cambiar-password`, { password_actual: this.actual, password_nueva: this.nueva }, ERROR_EN_LINEA).subscribe({
      next: () => {
        this.cargando.set(false);
        this.exito.set(true);
      },
      error: (err) => {
        this.cargando.set(false);
        this.error.set(err.error?.error ?? 'No se pudo cambiar la contraseña.');
      },
    });
  }

  cerrar(): void {
    this.visible.set(false);
  }
}