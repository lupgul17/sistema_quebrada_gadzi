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

  //color boton
readonly loginButtonTokens = {
  colorScheme: {
    light: {
      root: {
        primary: {
          background: '#093509',
          hoverBackground: '#0e500e',
          activeBackground: '#072a07',
          borderColor: '#093509',
          color: '#ffffff'
        },
      },
    },
  },
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