import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { API_URL } from './api-config';
import { Capacidad, PERMISOS } from './permisos';
import { AreaMenu } from './menus';

export interface Usuario {
  id_usuario: number;
  username: string;
  nombre: string;
  tipo_usuario: string;
  rol_acceso: string | null;
  /** Logo de su locación (ej. 'logo-gadzi.png') si todas sus áreas son de una sola; null = La Quebrada */
  logo?: string | null;
  /** Áreas asignadas ([] = todas) */
  areas?: AreaMenu[];
}

interface LoginResponse {
  token: string;
  usuario: Usuario;
}

const TOKEN_KEY = 'lq_token';
const USUARIO_KEY = 'lq_usuario';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly usuarioSignal = signal<Usuario | null>(this.leerUsuarioGuardado());
  readonly usuario = this.usuarioSignal.asReadonly();
  readonly estaAutenticado = computed(() => this.usuarioSignal() !== null);
  readonly rol = computed(() => this.usuarioSignal()?.rol_acceso ?? null);

  constructor(
    private http: HttpClient,
    private router: Router
  ) {}

  login(username: string, password: string): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${API_URL}/auth/login`, { username, password }).pipe(
      tap((res) => {
        localStorage.setItem(TOKEN_KEY, res.token);
        localStorage.setItem(USUARIO_KEY, JSON.stringify(res.usuario));
        this.usuarioSignal.set(res.usuario);
      })
    );
  }

  logout(): void {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USUARIO_KEY);
    this.usuarioSignal.set(null);
    this.router.navigate(['/login']);
  }

  getToken(): string | null {
    return localStorage.getItem(TOKEN_KEY);
  }

  puede(capacidad: Capacidad): boolean {
    const rol = this.rol()?.toLowerCase();
    return !!rol && PERMISOS[capacidad].some((r) => r.toLowerCase() === rol);
  }

  // Pide el rol vigente a la base: si un Superusuario te lo cambió, se refleja al recargar.
  // Si la cuenta fue desactivada, esta petición devuelve 401 y el interceptor te saca al login.
  refrescarPerfil(): void {
    this.http.get<{ rol_acceso: string | null; logo: string | null; areas: AreaMenu[] }>(`${API_URL}/auth/me`).subscribe((perfil) => {
      const actual = this.usuarioSignal();
      if (!actual) return;
      const igual =
        actual.rol_acceso === perfil.rol_acceso &&
        (actual.logo ?? null) === perfil.logo &&
        JSON.stringify(actual.areas ?? []) === JSON.stringify(perfil.areas ?? []);
      if (igual) return;
      // Rol, logo y áreas vigentes (si un Superusuario los cambió, se reflejan al recargar)
      const actualizado = { ...actual, rol_acceso: perfil.rol_acceso, logo: perfil.logo, areas: perfil.areas };
      localStorage.setItem(USUARIO_KEY, JSON.stringify(actualizado));
      this.usuarioSignal.set(actualizado);
    });
  }

  private leerUsuarioGuardado(): Usuario | null {
    try {
      const raw = localStorage.getItem(USUARIO_KEY);
      const parsed = raw ? JSON.parse(raw) : null;
      // Sesión vieja sin rol guardado: obliga a iniciar sesión de nuevo
      return parsed?.rol_acceso ? parsed : null;
    } catch {
      return null;
    }
  }
}