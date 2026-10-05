CREATE OR REPLACE FUNCTION fn_evento_detalle(p_id_evento integer) RETURNS TABLE(id_evento integer, fecha date, hora_inicio time without time zone, hora_fin time without time zone, estado character varying, reserva_temporal boolean, total_adultos integer, total_menores integer, notas text, id_cliente integer, cliente text, telefono_cliente character varying, id_tipo_evento integer, tipo_evento character varying, salones text, salones_ids integer[], fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        e.id_evento,
        e.fecha,
        e.hora_inicio,
        e.hora_fin,
        e.estado,
        e.reserva_temporal,
        e.total_adultos,
        e.total_menores,
        e.notas,
        c.id_cliente,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        p.telefono AS telefono_cliente,
        te.id_tipo_evento,
        te.descripcion AS tipo_evento,
        STRING_AGG(s.nombre, ', ' ORDER BY s.nombre) AS salones,
        ARRAY_AGG(s.id_salon ORDER BY s.nombre) AS salones_ids,
        e.fecha_creacion
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    LEFT JOIN evento_salon es ON es.id_evento = e.id_evento
    LEFT JOIN salon s ON s.id_salon = es.id_salon
    WHERE e.id_evento = p_id_evento
    GROUP BY e.id_evento, c.id_cliente, p.primer_nombre, p.primer_apellido, p.telefono, te.id_tipo_evento, te.descripcion;
$$;
