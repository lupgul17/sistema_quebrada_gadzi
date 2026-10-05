CREATE OR REPLACE FUNCTION fn_reporte_degustaciones_detallado(p_fecha_desde date, p_fecha_hasta date) RETURNS TABLE(id_degustacion integer, fecha_sesion date, hora_inicio time without time zone, cliente text, telefono character varying, tipo_evento character varying, fecha_evento date, menus json)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        d.id_degustacion,
        fd.fecha AS fecha_sesion,
        fd.hora_inicio,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        p.telefono,
        te.descripcion AS tipo_evento,
        e.fecha AS fecha_evento,
        COALESCE((
            SELECT json_agg(
                json_build_object(
                    'menu', m.nombre,
                    'es_adicional', dm.es_adicional,
                    'componentes', COALESCE((
                        SELECT json_agg(
                            json_build_object('categoria', cat.descripcion, 'nombre', cm.nombre)
                            ORDER BY cat.id_categoria_componente_menu, cm.nombre
                        )
                        FROM menu_componentes_menu mcm
                        JOIN componente_menu cm ON cm.id_componente = mcm.id_componente
                        JOIN tc_categoria_componente_menu cat ON cat.id_categoria_componente_menu = cm.id_categoria_componente_menu
                        WHERE mcm.id_menu = m.id_menu
                    ), '[]'::json)
                )
                ORDER BY dm.id_degustacion_menu
            )
            FROM degustacion_menu dm
            JOIN menu m ON m.id_menu = dm.id_menu
            WHERE dm.id_degustacion = d.id_degustacion
        ), '[]'::json) AS menus
    FROM degustacion d
    JOIN fechas_degustacion fd ON fd.id_fecha_degustacion = d.id_fecha_degustacion
    JOIN evento e ON e.id_evento = d.id_evento
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    WHERE d.estado != 'cancelada'
      AND fd.fecha BETWEEN p_fecha_desde AND p_fecha_hasta
    ORDER BY fd.fecha, fd.hora_inicio, p.primer_apellido;
$$;
