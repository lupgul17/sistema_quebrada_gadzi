import { Component, EventEmitter, Output, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Dialog } from 'primeng/dialog';
import { Button } from 'primeng/button';
import { Select } from 'primeng/select';
import { InputText } from 'primeng/inputtext';
import { InputNumber } from 'primeng/inputnumber';
import { Password } from 'primeng/password';
import { Checkbox } from 'primeng/checkbox';
import { Message } from 'primeng/message';
import { API_URL } from '../../../core/api-config';
import { AuthService } from '../../../core/auth.service';
import { ERROR_EN_LINEA } from '../../../core/http-errores';
import { ExtraPaquete, GrupoPaquete, IncluidoPaquete, Paquete } from '../../../core/paquetes';

interface EventoHorario {
  hora_inicio: string;
  hora_fin: string;
  total_menores: number | null;
}

/** Fila de extras en el diálogo: el cliente marca los que quiere y ajusta la cantidad. */
interface FilaExtra {
  extra: ExtraPaquete;
  marcado: boolean;
  cantidad: number | null;
}

@Component({
  selector: 'app-aplicar-paquete-dialog',
  standalone: true,
  imports: [CommonModule, FormsModule, Dialog, Button, Select, InputText, InputNumber, Password, Checkbox, Message],
  templateUrl: './aplicar-paquete-dialog.html',
  styleUrl: './aplicar-paquete-dialog.scss',
})
export class AplicarPaqueteDialog {
  @Output() aplicado = new EventEmitter<number>();

  readonly visible = signal(false);
  readonly cargando = signal(false);
  readonly guardando = signal(false);
  readonly error = signal<string | null>(null);
  readonly paquetes = signal<Paquete[]>([]);
  readonly idPaquete = signal<number | null>(null);
  readonly cantidad = signal<number | null>(null);
  /** Elegidos por grupo (id del grupo → ids de menú, componente o servicio). */
  readonly elecciones = signal<Record<number, number[]>>({});
  /** Si el evento ya tiene cotización, aplicar crea una versión nueva que la reemplaza. */
  readonly reemplaza = signal(false);
  private readonly evento = signal<EventoHorario | null>(null);

  private idEvento = 0;
  aplicaDeposito = true;
  autorizacion = { username: '', password: '' };
  filasExtras: FilaExtra[] = [];

  readonly paquete = computed(() => this.paquetes().find((p) => p.id_paquete === this.idPaquete()) ?? null);
  readonly totalPaquete = computed(() => {
    const p = this.paquete();
    const n = this.cantidad();
    return p && n ? Number(p.precio_por_persona) * n : 0;
  });
  readonly bajoMinimo = computed(() => {
    const p = this.paquete();
    const n = this.cantidad();
    return !!p && !!n && n < p.minimo_personas;
  });
  /** Un administrador autoriza con su propia sesión; los demás roles piden sus credenciales. */
  readonly puedeAutorizar = computed(() => this.auth.puede('autorizarMinimo'));

  /** Invitados para "1 por cada N personas" y "por persona": adultos del paquete + niños del evento. */
  readonly personas = computed(() => (this.cantidad() ?? 0) + (this.evento()?.total_menores ?? 0));

  /** Duración del evento en horas (si termina pasada la medianoche, cuenta hasta el otro día). */
  readonly horasEvento = computed(() => {
    const e = this.evento();
    if (!e) return null;
    const minutos = (h: string) => Number(h.slice(0, 2)) * 60 + Number(h.slice(3, 5));
    let dur = minutos(e.hora_fin) - minutos(e.hora_inicio);
    if (dur <= 0) dur += 24 * 60;
    return dur / 60;
  });
  readonly horasExtra = computed(() => {
    const incluidas = this.paquete()?.horas_incluidas;
    const horas = this.horasEvento();
    return incluidas && horas ? Math.max(0, Math.ceil(horas - incluidas)) : 0;
  });

  readonly faltantes = computed(() => {
    const p = this.paquete();
    if (!p) return [];
    const e = this.elecciones();
    return p.grupos.filter((g) => (e[g.id]?.length ?? 0) !== g.cantidad_a_elegir).map((g) => g.nombre);
  });

  constructor(
    private http: HttpClient,
    private auth: AuthService
  ) {}

  abrir(idEvento: number, adultos: number | null, aplicaDeposito: boolean, reemplaza: boolean): void {
    this.idEvento = idEvento;
    this.aplicaDeposito = aplicaDeposito;
    this.reemplaza.set(reemplaza);
    this.cantidad.set(adultos || null);
    this.idPaquete.set(null);
    this.elecciones.set({});
    this.filasExtras = [];
    this.autorizacion = { username: '', password: '' };
    this.error.set(null);
    this.visible.set(true);
    this.cargando.set(true);
    this.http.get<EventoHorario>(`${API_URL}/eventos/${idEvento}`).subscribe((e) => this.evento.set(e));
    // Solo los paquetes activos que se pueden usar en los salones de este evento
    this.http.get<Paquete[]>(`${API_URL}/paquetes?id_evento=${idEvento}`).subscribe({
      next: (lista) => {
        this.paquetes.set(lista);
        this.cargando.set(false);
      },
      error: () => this.cargando.set(false),
    });
  }

  elegirPaquete(id: number | null): void {
    this.idPaquete.set(id);
    const p = this.paquete();
    // Los grupos con una sola opción (o que piden todas) quedan elegidos de una vez
    const inicial: Record<number, number[]> = {};
    for (const g of p?.grupos ?? []) {
      inicial[g.id] = g.opciones.length === g.cantidad_a_elegir ? g.opciones.map((o) => o.id) : [];
    }
    this.elecciones.set(inicial);
    // Extras con la cantidad sugerida; la hora extra ya marcada si el evento dura más de lo incluido
    this.filasExtras = (p?.extras ?? []).map((extra) => {
      if (extra.calculo === 'hora_extra') {
        return { extra, marcado: this.horasExtra() > 0, cantidad: this.horasExtra() || 1 };
      }
      return { extra, marcado: false, cantidad: extra.calculo === 'por_persona' ? this.personas() || null : 1 };
    });
    this.error.set(null);
  }

  /** Al cambiar la cantidad de personas, los extras "por persona" la siguen. */
  cambiarCantidad(n: number | null): void {
    this.cantidad.set(n);
    for (const f of this.filasExtras) {
      if (f.extra.calculo === 'por_persona') f.cantidad = this.personas() || null;
    }
  }

  estaElegida(g: GrupoPaquete, idOpcion: number): boolean {
    return this.elecciones()[g.id]?.includes(idOpcion) ?? false;
  }

  alternar(g: GrupoPaquete, idOpcion: number): void {
    const actuales = this.elecciones()[g.id] ?? [];
    let nuevas: number[];
    if (actuales.includes(idOpcion)) {
      nuevas = actuales.filter((id) => id !== idOpcion);
    } else if (g.cantidad_a_elegir === 1) {
      nuevas = [idOpcion]; // elegir una sola: la nueva reemplaza a la anterior
    } else if (actuales.length < g.cantidad_a_elegir) {
      nuevas = [...actuales, idOpcion];
    } else {
      return; // ya completó el grupo; tiene que quitar una antes
    }
    this.elecciones.set({ ...this.elecciones(), [g.id]: nuevas });
  }

  /** Texto de un "incluye": los servicios muestran la cantidad que va a quedar (ej. "Mesero ×4"). */
  textoIncluido(i: IncluidoPaquete): string {
    if (!i.id_servicio) return i.nombre;
    const cantidad = i.por_cada_personas ? i.cantidad * Math.ceil(this.personas() / i.por_cada_personas) : i.cantidad;
    const regla = i.por_cada_personas ? ` (${i.cantidad} por cada ${i.por_cada_personas} pers.)` : '';
    return `${i.nombre} ×${cantidad}${regla}`;
  }

  totalExtras(): number {
    return this.filasExtras
      .filter((f) => f.marcado && f.cantidad)
      .reduce((acc, f) => acc + Number(f.extra.precio) * (f.cantidad ?? 0), 0);
  }

  aplicar(): void {
    const p = this.paquete();
    const n = this.cantidad();
    if (!p) return this.error.set('Elegí un paquete.');
    if (!n || n < 1) return this.error.set('Indicá la cantidad de personas.');
    if (this.faltantes().length) return this.error.set(`Completá la elección de: ${this.faltantes().join(', ')}.`);
    const extrasMarcados = this.filasExtras.filter((f) => f.marcado);
    if (extrasMarcados.some((f) => !f.cantidad || f.cantidad < 1)) {
      return this.error.set('Cada extra marcado necesita una cantidad.');
    }
    const pideCredenciales = this.bajoMinimo() && !this.puedeAutorizar();
    if (pideCredenciales && (!this.autorizacion.username.trim() || !this.autorizacion.password)) {
      return this.error.set('Ingresá el usuario y la contraseña del administrador que autoriza.');
    }

    const e = this.elecciones();
    const elegidos = (tipo: GrupoPaquete['tipo']) => p.grupos.filter((g) => g.tipo === tipo).flatMap((g) => e[g.id] ?? []);
    const body = {
      id_evento: this.idEvento,
      id_paquete: p.id_paquete,
      menus: elegidos('menu'),
      componentes: elegidos('componente'),
      cortesias: elegidos('cortesia'),
      extras: extrasMarcados.map((f) => ({ id_servicio: f.extra.id_servicio, cantidad: f.cantidad })),
      cantidad: n,
      deposito_garantia: this.aplicaDeposito ? 1000 : 0,
      autorizacion: pideCredenciales ? { username: this.autorizacion.username.trim().toLowerCase(), password: this.autorizacion.password } : undefined,
    };

    this.guardando.set(true);
    this.error.set(null);
    this.http.post<{ id_cotizacion: number }>(`${API_URL}/cotizaciones/paquete`, body, ERROR_EN_LINEA).subscribe({
      next: (res) => {
        this.guardando.set(false);
        this.visible.set(false);
        this.aplicado.emit(res.id_cotizacion);
      },
      error: (err) => {
        this.guardando.set(false);
        this.autorizacion.password = '';
        this.error.set(err.error?.error ?? 'No se pudo aplicar el paquete');
      },
    });
  }
}
