import { AreaMenu } from './menus';

export type TipoGrupo = 'menu' | 'componente' | 'cortesia';
export type CalculoExtra = 'fijo' | 'por_persona' | 'hora_extra';

/** Opción de un grupo: un menú del catálogo, un componente o un servicio (cortesía), según el grupo. */
export interface OpcionPaquete {
  id: number;
  nombre: string;
  /** Menú: su tipo. Componente: su categoría. Cortesía: la categoría del servicio. */
  categoria: string | null;
  /** Menú: sus componentes separados por coma. */
  detalle: string | null;
}

export interface GrupoPaquete {
  id: number;
  tipo: TipoGrupo;
  nombre: string;
  cantidad_a_elegir: number;
  opciones: OpcionPaquete[];
}

/** Lo que incluye el paquete: un servicio a Q0 (fijo o "1 por cada N personas") o solo un texto. */
export interface IncluidoPaquete {
  id_servicio: number | null;
  texto: string | null;
  nombre: string;
  cantidad: number;
  por_cada_personas: number | null;
}

/** Extra opcional con el precio especial del paquete. */
export interface ExtraPaquete {
  id_servicio: number;
  nombre: string;
  unidad_medida: string;
  precio: number | string;
  precio_catalogo: number | string;
  calculo: CalculoExtra;
}

/** Fila de GET /api/paquetes (fn_listar_paquetes). */
export interface Paquete {
  id_paquete: number;
  nombre: string;
  descripcion: string | null;
  precio_por_persona: number | string;
  minimo_personas: number;
  horas_incluidas: number | null;
  id_tipo_menu: number;
  tipo_menu: string;
  activo: boolean;
  grupos: GrupoPaquete[];
  incluidos: IncluidoPaquete[];
  extras: ExtraPaquete[];
  disponibilidad: AreaMenu[];
}

/** Paquete aplicado en una cotización (GET /api/cotizaciones/:id → paquetes). */
export interface PaqueteAplicado {
  id_cotizacion_menu: number;
  paquete: string;
  elecciones: string | null;
  incluye: string[];
  horas_incluidas: number | null;
}
