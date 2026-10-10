import { AbstractControl, FormControl, ValidationErrors, ValidatorFn } from '@angular/forms';

/**
 * Validadores de los formularios. Cada uno devuelve una clave de error con datos para que
 * mensajeDeError() arme un texto claro (ej. { telefono: true } → "Escribí un teléfono de 8 dígitos").
 * Los vacíos no se validan aquí: para eso está Validators.required.
 */

const vacio = (v: unknown) => v === null || v === undefined || (typeof v === 'string' && v.trim() === '');
const soloDigitos = (v: string) => v.replace(/[\s-]/g, '');

export const Validadores = {
  /**
   * Teléfono: 8 dígitos de Guatemala (acepta espacios, guiones y +502 al inicio) o un número
   * del extranjero que empiece con + (8 a 15 dígitos).
   */
  telefono: ((c: AbstractControl): ValidationErrors | null => {
    if (vacio(c.value)) return null;
    const d = soloDigitos(String(c.value));
    if (/^\+502/.test(d)) return /^\+502\d{8}$/.test(d) ? null : { telefono: true };
    if (d.startsWith('+')) return /^\+\d{8,15}$/.test(d) ? null : { telefono: true };
    return /^\d{8}$/.test(d) ? null : { telefono: true };
  }) as ValidatorFn,

  /** Nombre o apellido: letras (con tildes), espacios, apóstrofo, punto o guion. */
  nombrePersona: ((c: AbstractControl): ValidationErrors | null => {
    if (vacio(c.value)) return null;
    return /^\p{L}[\p{L}\s'.-]*$/u.test(String(c.value).trim()) ? null : { nombrePersona: true };
  }) as ValidatorFn,

  /** Para un grupo: al menos uno de los campos con valor (ej. teléfono o correo). */
  alMenosUno(...campos: string[]): ValidatorFn {
    return (g: AbstractControl): ValidationErrors | null =>
      campos.some((k) => !vacio(g.get(k)?.value)) ? null : { alMenosUno: { campos } };
  },

  /** CUI (DPI): 13 dígitos (acepta espacios). */
  cui: ((c: AbstractControl): ValidationErrors | null => {
    if (vacio(c.value)) return null;
    return /^\d{13}$/.test(soloDigitos(String(c.value))) ? null : { cui: true };
  }) as ValidatorFn,

  /** NIT: dígitos con verificador opcional (ej. 1234567-8 o 12345678K), o "CF". */
  nit: ((c: AbstractControl): ValidationErrors | null => {
    if (vacio(c.value)) return null;
    const v = String(c.value).trim().toUpperCase();
    return v === 'CF' || /^\d{1,12}-?[\dK]$/.test(v) ? null : { nit: true };
  }) as ValidatorFn,

  /** Correo con forma nombre@dominio.ext (más estricto que Validators.email). */
  correo: ((c: AbstractControl): ValidationErrors | null => {
    if (vacio(c.value)) return null;
    return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(String(c.value).trim()) ? null : { correo: true };
  }) as ValidatorFn,

  /** Usuario de login: minúsculas, números, punto, guion o guion bajo; de 3 a 30. */
  usuario: ((c: AbstractControl): ValidationErrors | null => {
    if (vacio(c.value)) return null;
    return /^[a-z0-9._-]{3,30}$/.test(String(c.value).trim()) ? null : { usuario: true };
  }) as ValidatorFn,

  /** Número mayor a 0 (montos, precios por persona, cantidades). */
  positivo: ((c: AbstractControl): ValidationErrors | null => {
    if (vacio(c.value)) return null;
    return Number(c.value) > 0 ? null : { positivo: true };
  }) as ValidatorFn,

  /** Fecha de hoy en adelante (para eventos y degustaciones nuevas). */
  fechaNoPasada: ((c: AbstractControl): ValidationErrors | null => {
    if (!(c.value instanceof Date)) return null;
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);
    const f = new Date(c.value);
    f.setHours(0, 0, 0, 0);
    return f < hoy ? { fechaPasada: true } : null;
  }) as ValidatorFn,

  /** Fecha de hoy hacia atrás (para fechas de pago). */
  fechaNoFutura: ((c: AbstractControl): ValidationErrors | null => {
    if (!(c.value instanceof Date)) return null;
    const hoy = new Date();
    hoy.setHours(23, 59, 59, 999);
    return c.value > hoy ? { fechaFutura: true } : null;
  }) as ValidatorFn,

  /**
   * Para la hora de fin: debe ser después de la hora del control hermano `campoInicio` y durar al
   * menos `minHoras`. Hay que revalidarla cuando cambia el inicio (ver revalidarAlCambiar).
   */
  horaDespuesDe(campoInicio: string, minHoras = 1): ValidatorFn {
    return (c: AbstractControl): ValidationErrors | null => {
      const inicio = c.parent?.get(campoInicio)?.value;
      if (!(inicio instanceof Date) || !(c.value instanceof Date)) return null;
      const minutos = (d: Date) => d.getHours() * 60 + d.getMinutes();
      const dur = minutos(c.value) - minutos(inicio);
      if (dur <= 0) return { horaFinAntes: true };
      if (dur < minHoras * 60) return { duracionMinima: { horas: minHoras } };
      return null;
    };
  },
};

/** CUI mientras se escribe o se pega: solo dígitos, 13 como máximo ("1234 56789 0101" → "1234567890101"). */
export const formatearCui = (valor: string) => valor.replace(/\D/g, '').slice(0, 13);

/**
 * Teléfono mientras se escribe: 8 dígitos como máximo, con guion después del cuarto ("55024196" → "5502-4196").
 * Si viene con el código de Guatemala ("+502 5502 4196", ej. de un prospecto o pegado) se le quita.
 */
export const formatearTelefono = (valor: string) => {
  let d = valor.replace(/\D/g, '');
  if (d.length === 11 && d.startsWith('502')) d = d.slice(3);
  d = d.slice(0, 8);
  return d.length > 4 ? `${d.slice(0, 4)}-${d.slice(4)}` : d;
};

/**
 * Teléfono para mostrar: "55024196" → "5502-4196" y "+50255024196" → "+502 5502-4196".
 * Lo que no tenga ese formato (ej. un número del extranjero) se muestra tal cual.
 */
export function mostrarTelefono(valor: string | null | undefined): string {
  const t = (valor ?? '').trim();
  const d = t.replace(/[\s()-]/g, '');
  if (/^\d{8}$/.test(d)) return formatearTelefono(d);
  if (/^\+502\d{8}$/.test(d)) return `+502 ${formatearTelefono(d.slice(4))}`;
  return t;
}

/** Cuando cambia `origen`, vuelve a validar `destino` (ej. hora de fin al cambiar el inicio). */
export function revalidarAlCambiar(origen: AbstractControl, destino: AbstractControl): void {
  origen.valueChanges.subscribe(() => destino.updateValueAndValidity({ emitEvent: false }));
}

/**
 * Para formularios con ngModel (sin FormGroup): el mensaje de error de un valor suelto con los
 * mismos validadores. Ej.: errorDe(nuevo.telefono, Validadores.telefono)
 */
export function errorDe(valor: unknown, ...validadores: ValidatorFn[]): string | null {
  return mensajeDeError(new FormControl(valor, validadores).errors);
}

/** Contraseña: al menos 8 caracteres, con letras y números. */
export function errorPassword(p: string | null | undefined): string | null {
  const v = p ?? '';
  if (!v) return 'Escribí una contraseña.';
  if (v.length < 8) return 'Debe tener al menos 8 caracteres.';
  if (!/[A-Za-zÁÉÍÓÚáéíóúÑñ]/.test(v) || !/\d/.test(v)) return 'Debe tener letras y números.';
  return null;
}

/** Texto del primer error de un control, para mostrar debajo del campo. */
export function mensajeDeError(errores: ValidationErrors | null | undefined): string | null {
  if (!errores) return null;
  if (errores['required']) return 'Este campo es obligatorio.';
  if (errores['telefono']) return 'Escribí un teléfono de 8 dígitos (ej. 5502-4196).';
  if (errores['cui']) return 'El CUI debe tener 13 dígitos.';
  if (errores['nombrePersona']) return 'Solo letras, espacios y guiones.';
  if (errores['nit']) return 'Escribí un NIT válido (ej. 1234567-8) o CF.';
  if (errores['correo'] || errores['email']) return 'Escribí un correo válido (ej. nombre@correo.com).';
  if (errores['usuario']) return 'Solo minúsculas, números, punto o guiones; de 3 a 30 caracteres.';
  if (errores['positivo']) return 'Debe ser mayor a 0.';
  if (errores['fechaPasada']) return 'La fecha ya pasó: elegí hoy o una fecha futura.';
  if (errores['fechaFutura']) return 'La fecha no puede ser futura.';
  if (errores['horaFinAntes']) return 'Debe ser después de la hora de inicio.';
  if (errores['duracionMinima']) return `Debe durar al menos ${errores['duracionMinima'].horas} hora(s).`;
  if (errores['min']) return `Debe ser ${errores['min'].min} o más.`;
  if (errores['max']) return `Debe ser ${errores['max'].max} o menos.`;
  if (errores['minlength']) return `Debe tener al menos ${errores['minlength'].requiredLength} caracteres.`;
  if (errores['maxlength']) return `Máximo ${errores['maxlength'].requiredLength} caracteres.`;
  if (errores['servidor']) return errores['servidor'];
  return 'El dato no es válido.';
}
