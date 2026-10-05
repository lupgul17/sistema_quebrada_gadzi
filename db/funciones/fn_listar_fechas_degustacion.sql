CREATE OR REPLACE FUNCTION fn_listar_fechas_degustacion() RETURNS TABLE(id_fecha_degustacion integer, fecha date, hora_inicio time without time zone, hora_fin time without time zone, estado character varying, eventos_agendados bigint)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        fd.id_fecha_degustacion, fd.fecha, fd.hora_inicio, fd.hora_fin, fd.estado,
        COUNT(d.id_degustacion) FILTER (WHERE d.estado != 'cancelada') AS eventos_agendados
    FROM fechas_degustacion fd
    LEFT JOIN degustacion d ON d.id_fecha_degustacion = fd.id_fecha_degustacion
    GROUP BY fd.id_fecha_degustacion
    ORDER BY fd.fecha DESC, fd.hora_inicio;
$$;
