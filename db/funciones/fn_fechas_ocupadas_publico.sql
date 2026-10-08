-- Mismo criterio que fn_validar_disponibilidad_salon (confirmado, en curso, o reserva temporal
-- vigente). Devuelve SOLO fecha, salón y si es temporal: nunca datos del evento ni del cliente.
-- Si en el mismo día y salón hay una firme y una temporal, gana la firme.
CREATE OR REPLACE FUNCTION fn_fechas_ocupadas_publico(p_desde date, p_hasta date)
RETURNS TABLE(fecha date, id_salon integer, temporal boolean)
    LANGUAGE sql STABLE
    AS $$
    SELECT e.fecha, es.id_salon, NOT bool_or(e.estado IN ('confirmado', 'en_curso')) AS temporal
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
    GROUP BY e.fecha, es.id_salon
    ORDER BY e.fecha, es.id_salon;
$$;
