/**
 * Validaciones de datos que llegan del navegador (los mismos formatos que valida el frontend en
 * core/validaciones.ts). El frontend ataja casi todo; esto es la segunda barrera.
 */

/** Texto recortado; vacío → null (un "" no debe guardarse como dato, ej. un CUI vacío). */
export function textoONull(v: unknown): string | null {
  if (v === null || v === undefined) return null;
  const t = String(v).trim();
  return t === '' ? null : t;
}

const soloDigitos = (v: string) => v.replace(/[\s-]/g, '');

export const formato = {
  /** 8 dígitos de Guatemala (con o sin +502) o internacional con + (8 a 15 dígitos). */
  telefono(v: string): boolean {
    const d = soloDigitos(v);
    if (/^\+502/.test(d)) return /^\+502\d{8}$/.test(d);
    if (d.startsWith('+')) return /^\+\d{8,15}$/.test(d);
    return /^\d{8}$/.test(d);
  },
  cui: (v: string) => /^\d{13}$/.test(soloDigitos(v)),
  nit: (v: string) => v.toUpperCase() === 'CF' || /^\d{1,12}-?[\dK]$/i.test(v),
  correo: (v: string) => /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(v),
  nombrePersona: (v: string) => /^\p{L}[\p{L}\s'.-]*$/u.test(v),
};

export interface DatosPersona {
  primer_nombre: string;
  segundo_nombre: string | null;
  primer_apellido: string;
  segundo_apellido: string | null;
  cui: string | null;
  nit: string | null;
  telefono: string | null;
  correo: string | null;
}

/** Limpia y valida los datos de una persona/cliente. Devuelve el error a mostrar o los datos limpios. */
export function leerPersona(body: any): { error: string } | { datos: DatosPersona } {
  const d: DatosPersona = {
    primer_nombre: textoONull(body?.primer_nombre) ?? '',
    segundo_nombre: textoONull(body?.segundo_nombre),
    primer_apellido: textoONull(body?.primer_apellido) ?? '',
    segundo_apellido: textoONull(body?.segundo_apellido),
    cui: textoONull(body?.cui)?.replace(/\s/g, '') ?? null,
    nit: textoONull(body?.nit)?.toUpperCase() ?? null,
    telefono: textoONull(body?.telefono)?.replace(/[\s-]/g, '') ?? null,
    correo: textoONull(body?.correo)?.toLowerCase() ?? null,
  };
  if (!d.primer_nombre || !d.primer_apellido) return { error: 'El primer nombre y el primer apellido son obligatorios.' };
  for (const [campo, valor] of [
    ['primer nombre', d.primer_nombre], ['segundo nombre', d.segundo_nombre],
    ['primer apellido', d.primer_apellido], ['segundo apellido', d.segundo_apellido],
  ] as const) {
    if (valor && (valor.length > 80 || !formato.nombrePersona(valor))) return { error: `El ${campo} solo puede tener letras (máximo 80).` };
  }
  if (d.cui && !formato.cui(d.cui)) return { error: 'El CUI debe tener 13 dígitos.' };
  if (d.nit && (d.nit.length > 20 || !formato.nit(d.nit))) return { error: 'El NIT no es válido (ej. 1234567-8 o CF).' };
  if (d.telefono && (d.telefono.length > 20 || !formato.telefono(d.telefono))) return { error: 'El teléfono debe tener 8 dígitos.' };
  if (d.correo && (d.correo.length > 150 || !formato.correo(d.correo))) return { error: 'El correo no es válido.' };
  return { datos: d };
}
