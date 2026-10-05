CREATE OR REPLACE FUNCTION fn_listar_extras_evento(p_id_evento integer) RETURNS TABLE(id_extra integer, id_evento integer, total numeric, id_empleado integer, servicios json, menus json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id_extra,
        e.id_evento,
        e.total,
        e.id_empleado,
        COALESCE((
            SELECT json_agg(x.*)
            FROM (
                SELECT
                    es.id_extras_servicios,
                    es.id_servicio,
                    s.nombre AS servicio,
                    es.id_tipo_cargo_extra,
                    tce.descripcion AS tipo_cargo_extra,
                    es.descripcion,
                    es.cantidad,
                    es.precio_unitario,
                    es.subtotal,
                    es.estado
                FROM extras_servicios es
                LEFT JOIN servicios s ON s.id_servicio = es.id_servicio
                LEFT JOIN tc_tipo_cargo_extra tce ON tce.id_tipo_cargo_extra = es.id_tipo_cargo_extra
                WHERE es.id_extra = e.id_extra
                ORDER BY es.id_extras_servicios
            ) x
        ), '[]'::json) AS servicios,
        COALESCE((
            SELECT json_agg(y.*)
            FROM (
                SELECT
                    em.id_extras_menu,
                    em.id_menu,
                    m.nombre AS menu,
                    em.descripcion,
                    em.cantidad,
                    em.precio_base,
                    em.subtotal,
                    em.estado
                FROM extras_menu em
                LEFT JOIN menu m ON m.id_menu = em.id_menu
                WHERE em.id_extra = e.id_extra
                ORDER BY em.id_extras_menu
            ) y
        ), '[]'::json) AS menus
    FROM extras e
    WHERE e.id_evento = p_id_evento;
END;
$$;
