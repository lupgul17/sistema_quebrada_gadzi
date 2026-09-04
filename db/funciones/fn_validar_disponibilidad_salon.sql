CREATE OR REPLACE FUNCTION fn_validar_disponibilidad_salon(
    p_id_salon INTEGER,
    p_fecha DATE,
    p_hora_inicio TIME,
    p_hora_fin TIME,
    p_id_evento_excluir INTEGER DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT NOT EXISTS (
        SELECT 1
        FROM evento_salon es
        JOIN evento e ON e.id_evento = es.id_evento
        LEFT JOIN cotizacion c ON c.id_evento = e.id_evento AND c.activa = true
        WHERE es.id_salon = p_id_salon
          AND e.fecha = p_fecha
          AND (p_id_evento_excluir IS NULL OR e.id_evento != p_id_evento_excluir)
          AND (e.hora_inicio, e.hora_fin) OVERLAPS (p_hora_inicio, p_hora_fin)
          AND (
                e.estado IN ('confirmado', 'en_curso')
                OR (
                    e.estado = 'cotizacion'
                    AND e.reserva_temporal = true
                    AND COALESCE(c.fecha_cotizacion + c.vigencia_dias, e.fecha_creacion::date + 8) >= CURRENT_DATE
                )
              )
    );
$$;