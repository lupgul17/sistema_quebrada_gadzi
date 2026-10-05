import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { API_URL } from './api-config';

interface DegustacionEstado {
  estado: string;
  resultado?: string | null;
}

/** Dice si el evento tiene una degustación realizada y aprobada (habilita "Armar menú" en la cotización). */
@Injectable({ providedIn: 'root' })
export class DegustacionEventoService {
  // Guarda de qué evento es el dato, para no mostrar el de otro evento mientras llega la respuesta
  private readonly estado = signal<{ idEvento: number; aprobada: boolean } | null>(null);

  constructor(private http: HttpClient) {}

  /** En el diagrama, tras "degustación aprobada" sigue "modificar cotización". */
  static hayAprobada(lista: DegustacionEstado[]): boolean {
    return lista.some((d) => d.estado === 'realizada' && d.resultado === 'aprobada');
  }

  esAprobada(idEvento: number): boolean {
    const e = this.estado();
    return !!e && e.idEvento === idEvento && e.aprobada;
  }

  fijar(idEvento: number, aprobada: boolean): void {
    this.estado.set({ idEvento, aprobada });
  }

  actualizar(idEvento: number): void {
    this.http.get<DegustacionEstado[]>(`${API_URL}/eventos/${idEvento}/degustaciones`).subscribe((lista) => {
      this.fijar(idEvento, DegustacionEventoService.hayAprobada(lista));
    });
  }
}
