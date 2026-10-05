-- Fechas ocupadas por salón para el calendario de la landing pública.
-- Usa el mismo criterio que fn_validar_disponibilidad_salon (confirmado, en curso,
-- o reserva temporal vigente). Devuelve SOLO fecha y salón: nunca datos del evento
-- ni del cliente.
CREATE OR REPLACE FUNCTION fn_fechas_ocupadas_publico(
    p_desde DATE,
    p_hasta DATE
)
RETURNS TABLE (
    fecha     DATE,
    id_salon  INTEGER
)
LANGUAGE sql
STABLE
AS $$
    SELECT DISTINCT e.fecha, es.id_salon
    FROM evento e
    JOIN evento_salon es ON es.id_evento = e.id_evento
    LEFT JOIN cotizacion c ON c.id_evento = e.id_evento AND c.activa = true
    WHERE e.fecha BETWEEN p_desde AND p_hasta
      AND (
            e.estado IN ('confirmado', 'en_curso')
            OR (
                e.estado = 'cotizacion'
                AND e.reserva_temporal = true
                AND COALESCE(c.fecha_cotizacion + c.vigencia_dias, e.fecha_creacion::date + 8) >= CURRENT_DATE
            )
          )
    ORDER BY e.fecha, es.id_salon;
$$;
