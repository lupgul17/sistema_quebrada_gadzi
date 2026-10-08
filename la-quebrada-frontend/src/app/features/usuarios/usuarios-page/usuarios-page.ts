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
import { Validadores, errorDe, errorPassword } from '../../../core/validaciones';
import { Validators } from '@angular/forms';

import { BuscadorTabla } from '../../../core/buscador-tabla/buscador-tabla';
import { MultiSelect } from 'primeng/multiselect';
import { SelectButton } from 'primeng/selectbutton';
import { AreaMenu, FilaArea, opcionesDeAreas, separarAreas, unirAreas } from '../../../core/menus';
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
  /** Áreas asignadas ([] = ve todas) */
  areas: AreaMenu[];
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
  imports: [BuscadorTabla, CommonModule, FormsModule, TableModule, Button, Dialog, Select, InputText, Checkbox, Message, MultiSelect, SelectButton],
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
  /** Se intentó crear: muestra los errores de cada campo. */
  readonly intentoCrear = signal(false);
  readonly intentoPassword = signal(false);
  editando: UsuarioFila | null = null;
  editRol: number | null = null;
  editActivo = true;
  /** Áreas: 'todas' o 'restringido' + las elegidas (valores 'L:id' / 'S:id', como en los menús) */
  editModoAreas: 'todas' | 'restringido' = 'todas';
  editAreas: string[] = [];
  readonly opcionesAreas = signal<ReturnType<typeof opcionesDeAreas>>([]);
  readonly modosAreas = [
    { label: 'Todas las áreas', value: 'todas' },
    { label: 'Solo en…', value: 'restringido' },
  ];
  passwordNueva = '';

  constructor(
    private http: HttpClient,
    public auth: AuthService
  ) {}

  ngOnInit(): void {
    this.http.get<RolOpcion[]>(`${API_URL}/usuarios/roles`).subscribe((data) => this.roles.set(data));
    this.http.get<TipoEmpleadoOpcion[]>(`${API_URL}/usuarios/tipos-empleado`).subscribe((data) => this.tiposEmpleado.set(data));
    this.http.get<FilaArea[]>(`${API_URL}/salones/areas`).subscribe((data) => this.opcionesAreas.set(opcionesDeAreas(data)));
    this.cargarUsuarios();
  }

  cargarUsuarios(): void {
    this.http.get<UsuarioFila[]>(`${API_URL}/usuarios`).subscribe((data) => {
      this.usuarios.set(data);
      this.cargando.set(false);
    });
  }

  /** Texto de las áreas para la tabla. */
  textoAreas(u: UsuarioFila): string {
    return u.rol === 'Superusuario' || !(u.areas ?? []).length ? 'Todas' : u.areas.map((a) => a.nombre).join(', ');
  }

  esYo(u: UsuarioFila): boolean {
    return u.id_usuario === this.auth.usuario()?.id_usuario;
  }

  // ---- Nuevo ----
  abrirNuevo(): void {
    this.nuevo = { ...FORM_VACIO };
    this.error.set(null);
    this.intentoCrear.set(false);
    this.dialogoNuevoVisible.set(true);
  }

  /** Errores de cada campo del usuario nuevo (vacío = se puede crear). */
  erroresNuevo(): Record<string, string> {
    const n = this.nuevo;
    const nombre = [Validators.maxLength(80), Validadores.nombrePersona];
    const e: Record<string, string | null> = {
      username: errorDe(n.username, Validators.required, Validadores.usuario),
      password: errorPassword(n.password),
      primer_nombre: errorDe(n.primer_nombre, ...nombre),
      segundo_nombre: errorDe(n.segundo_nombre, ...nombre),
      primer_apellido: errorDe(n.primer_apellido, ...nombre),
      segundo_apellido: errorDe(n.segundo_apellido, ...nombre),
      cui: errorDe(n.cui, Validadores.cui),
      telefono: errorDe(n.telefono, Validadores.telefono),
      correo: errorDe(n.correo, Validadores.correo),
      id_rol_acceso: n.id_rol_acceso ? null : 'Elegí el rol.',
      id_tipo_empleado: n.id_tipo_empleado ? null : 'Elegí el tipo de empleado.',
    };
    return Object.fromEntries(Object.entries(e).filter(([, v]) => v)) as Record<string, string>;
  }

  /** El usuario siempre en minúsculas (el login también lo convierte). */
  usuarioEnMinusculas(valor: string): void {
    this.nuevo.username = (valor ?? '').toLowerCase().replace(/\s/g, '');
  }

  crear(): void {
    const n = this.nuevo;
    this.intentoCrear.set(true);
    if (Object.keys(this.erroresNuevo()).length) {
      this.error.set('Revisá los campos marcados.');
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
    const areas = u.areas ?? [];
    this.editModoAreas = areas.length ? 'restringido' : 'todas';
    this.editAreas = unirAreas(
      areas.filter((a) => a.tipo === 'locacion').map((a) => a.id),
      areas.filter((a) => a.tipo === 'salon').map((a) => a.id)
    );
    this.error.set(null);
    this.dialogoEditarVisible.set(true);
  }

  /** El rol elegido es Superusuario: ve todo, las áreas no aplican. */
  esSuperusuario(): boolean {
    return this.roles().find((r) => r.id_rol_acceso === this.editRol)?.descripcion === 'Superusuario';
  }

  guardarEdicion(): void {
    if (!this.editando || !this.editRol) return;
    if (!this.esSuperusuario() && this.editModoAreas === 'restringido' && !this.editAreas.length) {
      this.error.set('Elegí al menos un área, o marcá "Todas las áreas".');
      return;
    }
    this.guardando.set(true);
    this.error.set(null);
    const id = this.editando.id_usuario;
    const areas = this.esSuperusuario() || this.editModoAreas === 'todas' ? { locaciones: [], salones: [] } : separarAreas(this.editAreas);
    this.http.patch(`${API_URL}/usuarios/${id}`, { id_rol_acceso: this.editRol, activo: this.editActivo }, ERROR_EN_LINEA).subscribe({
      next: () => {
        this.http.put(`${API_URL}/usuarios/${id}/areas`, areas, ERROR_EN_LINEA).subscribe({
          next: () => {
            this.guardando.set(false);
            this.dialogoEditarVisible.set(false);
            this.cargarUsuarios();
          },
          error: (err) => {
            this.guardando.set(false);
            this.error.set(err.error?.error ?? 'Se guardó el rol, pero no las áreas.');
          },
        });
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
    this.intentoPassword.set(false);
    this.dialogoPasswordVisible.set(true);
  }

  resetearPassword(): void {
    if (!this.editando) return;
    this.intentoPassword.set(true);
    const problema = errorPassword(this.passwordNueva);
    if (problema) {
      this.error.set(problema);
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