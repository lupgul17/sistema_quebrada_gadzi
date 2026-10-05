CREATE OR REPLACE FUNCTION fn_listar_eventos(p_estado character varying DEFAULT NULL::character varying, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_id_cliente integer DEFAULT NULL::integer) RETURNS TABLE(id_evento integer, fecha date, hora_inicio time without time zone, hora_fin time without time zone, estado character varying, reserva_temporal boolean, tipo_evento character varying, total_adultos integer, total_menores integer, cliente text, salones text, locaciones text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        e.id_evento,
        e.fecha,
        e.hora_inicio,
        e.hora_fin,
        e.estado,
        e.reserva_temporal,
        te.descripcion AS tipo_evento,
        e.total_adultos,
        e.total_menores,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        STRING_AGG(DISTINCT s.nombre, ', ' ORDER BY s.nombre) AS salones,
        STRING_AGG(DISTINCT l.nombre, ', ' ORDER BY l.nombre) AS locaciones
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    LEFT JOIN evento_salon es ON es.id_evento = e.id_evento
    LEFT JOIN salon s ON s.id_salon = es.id_salon
    LEFT JOIN locacion l ON l.id_locacion = s.id_locacion
    WHERE
        (p_estado IS NULL OR e.estado = p_estado)
        AND (p_fecha_desde IS NULL OR e.fecha >= p_fecha_desde)
        AND (p_fecha_hasta IS NULL OR e.fecha <= p_fecha_hasta)
        AND (p_id_cliente IS NULL OR e.id_cliente = p_id_cliente)
    GROUP BY e.id_evento, e.fecha, e.hora_inicio, e.hora_fin, e.estado, e.reserva_temporal, te.descripcion, e.total_adultos, e.total_menores, p.primer_nombre, p.primer_apellido
    ORDER BY e.fecha DESC, e.hora_inicio;
$$;
