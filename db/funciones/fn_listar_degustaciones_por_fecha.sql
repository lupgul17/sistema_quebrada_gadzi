CREATE OR REPLACE FUNCTION fn_listar_degustaciones_por_fecha(p_id_fecha_degustacion integer) RETURNS TABLE(id_degustacion integer, id_evento integer, cliente text, telefono character varying, tipo_evento character varying, fecha_evento date, hora_llegada time without time zone, estado character varying, notas text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        d.id_degustacion, d.id_evento,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        p.telefono,
        te.descripcion AS tipo_evento,
        e.fecha AS fecha_evento,
        d.hora_llegada,
        d.estado, d.notas
    FROM degustacion d
    JOIN evento e ON e.id_evento = d.id_evento
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    WHERE d.id_fecha_degustacion = p_id_fecha_degustacion AND d.estado != 'cancelada'
    ORDER BY d.hora_llegada NULLS LAST, p.primer_apellido;
$$;
