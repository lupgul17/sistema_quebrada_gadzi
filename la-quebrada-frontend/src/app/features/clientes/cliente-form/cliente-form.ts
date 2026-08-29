import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { InputText } from 'primeng/inputtext';
import { Button } from 'primeng/button';
import { Message } from 'primeng/message';
import { API_URL } from '../../../core/api-config';

@Component({
  selector: 'app-cliente-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, InputText, Button, Message],
  templateUrl: './cliente-form.html',
  styleUrl: './cliente-form.scss',
})
export class ClienteForm implements OnInit {
  readonly cargando = signal(false);
  readonly error = signal<string | null>(null);
  readonly esEdicion = signal(false);
  readonly form;

  private idCliente: string | null = null;

  constructor(
    private fb: FormBuilder,
    private http: HttpClient,
    private route: ActivatedRoute,
    private router: Router
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

  ngOnInit(): void {
    this.idCliente = this.route.snapshot.paramMap.get('id');

    if (this.idCliente && this.idCliente !== 'nuevo') {
      this.esEdicion.set(true);
      this.http.get<any>(`${API_URL}/clientes/${this.idCliente}`).subscribe((cliente) => {
        this.form.patchValue(cliente);
      });
    }
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
      next: () => {
        this.cargando.set(false);
        this.router.navigate(['/clientes']);
      },
      error: (err) => {
        this.cargando.set(false);
        this.error.set(err.error?.error ?? 'Error al guardar el cliente');
      },
    });
  }

  cancelar(): void {
    this.router.navigate(['/clientes']);
  }
}