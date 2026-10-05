CREATE OR REPLACE FUNCTION fn_listar_degustaciones_evento(p_id_evento integer) RETURNS TABLE(id_degustacion integer, id_fecha_degustacion integer, fecha date, hora_inicio time without time zone, hora_fin time without time zone, hora_llegada time without time zone, estado character varying, resultado character varying, motivo_rechazo text, notas text, fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        d.id_degustacion, d.id_fecha_degustacion, fd.fecha, fd.hora_inicio, fd.hora_fin, d.hora_llegada,
        d.estado, d.resultado, d.motivo_rechazo, d.notas, d.fecha_creacion
    FROM degustacion d
    JOIN fechas_degustacion fd ON fd.id_fecha_degustacion = d.id_fecha_degustacion
    WHERE d.id_evento = p_id_evento
    ORDER BY fd.fecha DESC;
$$;
