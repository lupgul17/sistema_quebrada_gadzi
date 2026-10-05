import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { TableModule } from 'primeng/table';
import { Button } from 'primeng/button';
import { Dialog } from 'primeng/dialog';
import { Select } from 'primeng/select';
import { InputText } from 'primeng/inputtext';
import { Checkbox } from 'primeng/checkbox';
import { Message } from 'primeng/message';
import { AuthService } from '../../../core/auth.service';
import { API_URL } from '../../../core/api-config';
import { ERROR_EN_LINEA } from '../../../core/http-errores';

interface UsuarioFila {
  id_usuario: number;
  username: string;
  nombre_completo: string;
  correo: string | null;
  telefono: string | null;
  id_rol_acceso: number | null;
  rol: string | null;
  tipo_empleado: string | null;
  activo: boolean;
  fecha_ultimo_acceso: string | null;
}

interface RolOpcion {
  id_rol_acceso: number;
  descripcion: string;
}

interface TipoEmpleadoOpcion {
  id_tipo_empleado: number;
  descripcion: string;
}

const FORM_VACIO = {
  primer_nombre: '',
  segundo_nombre: '',
  primer_apellido: '',
  segundo_apellido: '',
  cui: '',
  telefono: '',
  correo: '',
  username: '',
  password: '',
  id_rol_acceso: null as number | null,
  id_tipo_empleado: null as number | null,
};

@Component({
  selector: 'app-usuarios-page',
  standalone: true,
  imports: [CommonModule, FormsModule, TableModule, Button, Dialog, Select, InputText, Checkbox, Message],
  templateUrl: './usuarios-page.html',
  styleUrl: './usuarios-page.scss',
})
export class UsuariosPage implements OnInit {
  readonly usuarios = signal<UsuarioFila[]>([]);
  readonly roles = signal<RolOpcion[]>([]);
  readonly tiposEmpleado = signal<TipoEmpleadoOpcion[]>([]);
  readonly cargando = signal(true);
  readonly guardando = signal(false);
  readonly error = signal<string | null>(null);

  readonly dialogoNuevoVisible = signal(false);
  readonly dialogoEditarVisible = signal(false);
  readonly dialogoPasswordVisible = signal(false);

  nuevo = { ...FORM_VACIO };
  editando: UsuarioFila | null = null;
  editRol: number | null = null;
  editActivo = true;
  passwordNueva = '';

  constructor(
    private http: HttpClient,
    public auth: AuthService
  ) {}

  ngOnInit(): void {
    this.http.get<RolOpcion[]>(`${API_URL}/usuarios/roles`).subscribe((data) => this.roles.set(data));
    this.http.get<TipoEmpleadoOpcion[]>(`${API_URL}/usuarios/tipos-empleado`).subscribe((data) => this.tiposEmpleado.set(data));
    this.cargarUsuarios();
  }

  cargarUsuarios(): void {
    this.http.get<UsuarioFila[]>(`${API_URL}/usuarios`).subscribe((data) => {
      this.usuarios.set(data);
      this.cargando.set(false);
    });
  }

  esYo(u: UsuarioFila): boolean {
    return u.id_usuario === this.auth.usuario()?.id_usuario;
  }

  // ---- Nuevo ----
  abrirNuevo(): void {
    this.nuevo = { ...FORM_VACIO };
    this.error.set(null);
    this.dialogoNuevoVisible.set(true);
  }

  crear(): void {
    const n = this.nuevo;
    if (!n.username.trim() || !n.id_rol_acceso || !n.id_tipo_empleado) {
      this.error.set('Completá usuario, rol y tipo de empleado.');
      return;
    }
    if (n.password.length < 8) {
      this.error.set('La contraseña debe tener al menos 8 caracteres.');
      return;
    }

    this.guardando.set(true);
    this.error.set(null);
    this.http.post(`${API_URL}/usuarios`, n, ERROR_EN_LINEA).subscribe({
      next: () => {
        this.guardando.set(false);
        this.dialogoNuevoVisible.set(false);
        this.cargarUsuarios();
      },
      error: (err) => {
        this.guardando.set(false);
        this.error.set(err.error?.error ?? 'No se pudo crear el usuario.');
      },
    });
  }

  // ---- Editar rol / estado ----
  abrirEditar(u: UsuarioFila): void {
    this.editando = u;
    this.editRol = u.id_rol_acceso;
    this.editActivo = u.activo;
    this.error.set(null);
    this.dialogoEditarVisible.set(true);
  }

  guardarEdicion(): void {
    if (!this.editando || !this.editRol) return;
    this.guardando.set(true);
    this.error.set(null);
    this.http.patch(`${API_URL}/usuarios/${this.editando.id_usuario}`, { id_rol_acceso: this.editRol, activo: this.editActivo }, ERROR_EN_LINEA).subscribe({
      next: () => {
        this.guardando.set(false);
        this.dialogoEditarVisible.set(false);
        this.cargarUsuarios();
      },
      error: (err) => {
        this.guardando.set(false);
        this.error.set(err.error?.error ?? 'No se pudo guardar el cambio.');
      },
    });
  }

  // ---- Resetear contraseña ----
  abrirPassword(u: UsuarioFila): void {
    this.editando = u;
    this.passwordNueva = '';
    this.error.set(null);
    this.dialogoPasswordVisible.set(true);
  }

  resetearPassword(): void {
    if (!this.editando) return;
    if (this.passwordNueva.length < 8) {
      this.error.set('La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    this.guardando.set(true);
    this.error.set(null);
    this.http.patch(`${API_URL}/usuarios/${this.editando.id_usuario}/password`, { password: this.passwordNueva }, ERROR_EN_LINEA).subscribe({
      next: () => {
        this.guardando.set(false);
        this.dialogoPasswordVisible.set(false);
      },
      error: (err) => {
        this.guardando.set(false);
        this.error.set(err.error?.error ?? 'No se pudo cambiar la contraseña.');
      },
    });
  }
}