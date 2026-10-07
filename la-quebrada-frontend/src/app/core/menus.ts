/** Un área donde se ofrece un menú: una locación completa o un salón. */
export interface AreaMenu {
  tipo: 'locacion' | 'salon';
  id: number;
  nombre: string;
}

/** Fila de GET /api/salones/areas (cada locación con sus salones). */
export interface FilaArea {
  id_locacion: number;
  locacion: string;
  id_salon: number | null;
  salon: string | null;
}

/** "Todos lados" si el menú no tiene restricción; si no, las áreas separadas por coma. */
export function textoDisponibilidad(areas: AreaMenu[] | null | undefined): string {
  return areas?.length ? areas.map((a) => a.nombre).join(', ') : 'Todos lados';
}

/**
 * Agrega `etiqueta` para los selectores de menú del evento: nombre · precio, y el área solo
 * si el menú está restringido. Así dos copias con el mismo nombre (ej. la de La Quebrada y la
 * de GADZI) se distinguen sin meter el área en el nombre del plato.
 */
export function conEtiqueta<T extends { nombre: string; precio_base: number | string; disponibilidad?: AreaMenu[] }>(
  menus: T[]
): (T & { etiqueta: string })[] {
  return menus.map((m) => {
    const area = m.disponibilidad?.length ? ` · ${textoDisponibilidad(m.disponibilidad)}` : '';
    return { ...m, etiqueta: `${m.nombre} · Q${Number(m.precio_base).toFixed(2)}${area}` };
  });
}

/** Opciones agrupadas por locación para un p-multiselect / p-select con [group]="true". */
export interface GrupoAreas {
  label: string;
  items: { label: string; value: string }[];
}

/** Valores codificados: 'L:<id_locacion>' = toda la locación, 'S:<id_salon>' = un salón. */
export function opcionesDeAreas(filas: FilaArea[]): GrupoAreas[] {
  const grupos = new Map<number, GrupoAreas>();
  for (const f of filas) {
    if (!grupos.has(f.id_locacion)) {
      grupos.set(f.id_locacion, {
        label: f.locacion,
        items: [{ label: `Toda ${f.locacion}`, value: `L:${f.id_locacion}` }],
      });
    }
    if (f.id_salon !== null && f.salon) {
      grupos.get(f.id_locacion)!.items.push({ label: f.salon, value: `S:${f.id_salon}` });
    }
  }
  return Array.from(grupos.values());
}

/** De los valores codificados a lo que espera la API: { locaciones: [...], salones: [...] }. */
export function separarAreas(valores: string[]): { locaciones: number[]; salones: number[] } {
  const locaciones: number[] = [];
  const salones: number[] = [];
  for (const v of valores ?? []) {
    const [tipo, id] = v.split(':');
    if (tipo === 'L') locaciones.push(Number(id));
    else if (tipo === 'S') salones.push(Number(id));
  }
  return { locaciones, salones };
}

/** De lo que devuelve fn_menu_detalle a los valores codificados del multiselect. */
export function unirAreas(locaciones: number[] | null, salones: number[] | null): string[] {
  return [...(locaciones ?? []).map((id) => `L:${id}`), ...(salones ?? []).map((id) => `S:${id}`)];
}
