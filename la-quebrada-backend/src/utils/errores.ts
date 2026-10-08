import type { Response } from 'express';

/**
 * Mensaje claro para cada regla (CHECK) de la base. Si llega una que no está aquí, se usa el
 * genérico; el formulario igual debería haberla atajado antes de enviar.
 */
const MENSAJES_REGLA: Record<string, string> = {
  chk_evento_horario: 'La hora de fin debe ser después de la hora de inicio.',
  chk_evento_estado: 'El estado del evento no es válido.',
  chk_cotizacion_menu_cantidad: 'La cantidad del menú debe ser mayor a 0.',
  chk_cotizacion_servicios_cantidad: 'La cantidad del servicio debe ser mayor a 0.',
  chk_extras_menu_cantidad: 'La cantidad del menú extra debe ser mayor a 0.',
  chk_extras_servicios_cantidad: 'La cantidad del servicio extra debe ser mayor a 0.',
  chk_descuento_monto: 'El descuento debe ser mayor a Q0.',
  chk_pago_monto: 'El monto del pago debe ser mayor a Q0.',
  chk_pago_concepto: 'El concepto del pago no es válido.',
  chk_pago_empleado_si_verificado: 'Un pago verificado necesita el empleado que lo verificó.',
  chk_degustacion_motivo_rechazo: 'Para rechazar la degustación escribí el motivo.',
  prospecto_invitados_check: 'La cantidad de invitados debe ser mayor a 0.',
  paquete_grupo_tipo_check: 'El tipo de grupo del paquete no es válido.',
  chk_paquete_opcion_una: 'Cada opción del paquete debe ser un menú, un componente o un servicio.',
  chk_paquete_incluido_uno: 'Cada "incluye" del paquete debe ser un servicio o un texto.',
  chk_menu_disp_un_area: 'Cada área debe ser una locación o un salón.',
  chk_paquete_disp_un_area: 'Cada área debe ser una locación o un salón.',
};

/** Mensaje para cada dato que no se puede repetir. */
const MENSAJES_DUPLICADO: Record<string, string> = {
  persona_cui_key: 'Ya hay una persona registrada con ese CUI.',
  usuario_username_key: 'Ese nombre de usuario ya está en uso.',
  salon_id_locacion_nombre_key: 'Ya existe un salón con ese nombre en esa locación.',
  locacion_nombre_key: 'Ya existe una locación con ese nombre.',
  cotizacion_id_evento_version_key: 'Otra persona creó una versión de la cotización al mismo tiempo. Recargá e intentá de nuevo.',
  ux_cotizacion_activa: 'Otra persona creó una versión de la cotización al mismo tiempo. Recargá e intentá de nuevo.',
  extras_id_evento_key: 'Este evento ya tiene su registro de extras.',
  uq_menu_disp_locacion: 'Esa locación está repetida en las áreas del menú.',
  uq_menu_disp_salon: 'Ese salón está repetido en las áreas del menú.',
  paquete_extra_pkey: 'Un mismo servicio está dos veces en los extras del paquete.',
};

/** Columnas obligatorias más comunes → nombre que entiende el usuario. */
const NOMBRE_COLUMNA: Record<string, string> = {
  nombre: 'el nombre',
  fecha: 'la fecha',
  hora_inicio: 'la hora de inicio',
  hora_fin: 'la hora de fin',
  monto: 'el monto',
  id_cliente: 'el cliente',
  id_tipo_pago: 'la forma de pago',
  precio_base: 'el precio',
  unidad_medida: 'la unidad',
  username: 'el usuario',
  primer_nombre: 'el primer nombre',
  primer_apellido: 'el primer apellido',
};

/**
 * Respuesta de error uniforme para todas las rutas.
 * - P0001: RAISE EXCEPTION de nuestros SPs (regla de negocio) → 400 con el mensaje del SP.
 * - Datos con formato o rango inválido / falta un dato obligatorio → 400.
 * - Referencia a algo que no existe o que está en uso → 400.
 * - Duplicado → 409.
 * - Cualquier otra cosa es un error real del servidor → 500 genérico; el detalle va al log,
 *   no al navegador (puede traer nombres de tablas o columnas).
 */
export function responderError(res: Response, err: unknown): void {
  const e = err as { code?: string; message?: string; constraint?: string; column?: string };

  switch (e.code) {
    case 'P0001':
      res.status(400).json({ error: e.message });
      return;
    case '22P02': // texto que no se puede convertir (ej. "abc" o "2.7" a integer)
    case '22003': // número fuera de rango
    case '22007': // fecha/hora inválida
    case '22008':
      res.status(400).json({ error: 'Alguno de los datos enviados tiene un formato inválido' });
      return;
    case '22001': // texto más largo que la columna
      res.status(400).json({ error: 'Alguno de los textos es más largo de lo permitido. Acortalo e intentá de nuevo.' });
      return;
    case '23502': {
      const campo = e.column ? NOMBRE_COLUMNA[e.column] : undefined;
      res.status(400).json({ error: campo ? `Falta ${campo}.` : 'Falta un dato obligatorio' });
      return;
    }
    case '23503':
      res.status(400).json({ error: 'El registro relacionado no existe o está siendo usado por otro registro' });
      return;
    case '23505':
      res.status(409).json({ error: (e.constraint && MENSAJES_DUPLICADO[e.constraint]) || 'Ya existe un registro con esos datos' });
      return;
    case '23514':
      res.status(400).json({ error: (e.constraint && MENSAJES_REGLA[e.constraint]) || 'Alguno de los datos no cumple las reglas permitidas' });
      return;
  }

  console.error('Error no controlado:', err);
  res.status(500).json({ error: 'Ocurrió un error en el servidor. Intentá de nuevo en un momento.' });
}
