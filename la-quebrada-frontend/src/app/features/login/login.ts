import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { InputText } from 'primeng/inputtext';
import { Password } from 'primeng/password';
import { Button } from 'primeng/button';
import { Message } from 'primeng/message';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, InputText, Password, Button, Message],
  templateUrl: './login.html',
  styleUrl: './login.scss',
})
export class Login {

  // Botón principal crema (CTA de mayor contraste, estilo pill)
  private readonly botonCrema = {
    root: {
      primary: {
        background: '#ece4d0',
        hoverBackground: '#ffffff',
        activeBackground: '#d9cfb6',
        borderColor: '#ece4d0',
        hoverBorderColor: '#ffffff',
        activeBorderColor: '#d9cfb6',
        color: '#0f0d0d',
        hoverColor: '#0f0d0d',
        activeColor: '#0f0d0d',
      },
    },
  };

  readonly loginButtonTokens = {
    colorScheme: { light: this.botonCrema, dark: this.botonCrema },
  };


  readonly cargando = signal(false);
  readonly error = signal<string | null>(null);
  readonly form;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.form = this.fb.group({
      username: ['', Validators.required],
      password: ['', Validators.required],
    });
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.cargando.set(true);
    this.error.set(null);

    const { username, password } = this.form.getRawValue();

    this.authService.login(username!, password!).subscribe({
      next: () => {
        this.cargando.set(false);
        this.router.navigate(['/']);
      },
      error: (err) => {
        this.cargando.set(false);
        this.error.set(err.error?.error ?? 'Error al iniciar sesión');
      },
    });
  }
}