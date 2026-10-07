CREATE OR REPLACE FUNCTION fn_listar_menus(p_id_tipo_menu integer DEFAULT NULL::integer, p_id_evento integer DEFAULT NULL::integer, p_id_locacion integer DEFAULT NULL::integer, p_id_salon integer DEFAULT NULL::integer, p_sin_restriccion boolean DEFAULT false) RETURNS TABLE(id_menu integer, nombre character varying, precio_base numeric, unidad_medida character varying, descripcion text, activo boolean, id_tipo_menu integer, tipo_menu character varying, componentes text, disponibilidad json)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        m.id_menu, m.nombre, m.precio_base, m.unidad_medida, m.descripcion, m.activo,
        tm.id_tipo_menu, tm.descripcion AS tipo_menu,
        STRING_AGG(cm.nombre, ', ' ORDER BY cm.nombre) AS componentes,
        (
            SELECT COALESCE(json_agg(json_build_object(
                       'tipo', CASE WHEN md.id_salon IS NULL THEN 'locacion' ELSE 'salon' END,
                       'id', COALESCE(md.id_salon, md.id_locacion),
                       'nombre', COALESCE(sa.nombre, lo.nombre)
                   ) ORDER BY (md.id_salon IS NOT NULL), COALESCE(sa.nombre, lo.nombre)), '[]'::json)
            FROM menu_disponibilidad md
            LEFT JOIN salon sa ON sa.id_salon = md.id_salon
            LEFT JOIN locacion lo ON lo.id_locacion = md.id_locacion
            WHERE md.id_menu = m.id_menu
        ) AS disponibilidad
    FROM menu m
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    LEFT JOIN menu_componentes_menu mcm ON mcm.id_menu = m.id_menu
    LEFT JOIN componente_menu cm ON cm.id_componente = mcm.id_componente
    WHERE (p_id_tipo_menu IS NULL OR m.id_tipo_menu = p_id_tipo_menu)
      AND NOT m.es_personalizado
      AND (p_id_evento IS NULL OR (m.activo AND fn_menu_disponible_evento(m.id_menu, p_id_evento)))
      AND (NOT p_sin_restriccion OR NOT EXISTS (SELECT 1 FROM menu_disponibilidad x WHERE x.id_menu = m.id_menu))
      AND (p_id_locacion IS NULL
           OR NOT EXISTS (SELECT 1 FROM menu_disponibilidad x WHERE x.id_menu = m.id_menu)
           OR EXISTS (SELECT 1 FROM menu_disponibilidad x LEFT JOIN salon xs ON xs.id_salon = x.id_salon
                      WHERE x.id_menu = m.id_menu AND (x.id_locacion = p_id_locacion OR xs.id_locacion = p_id_locacion)))
      AND (p_id_salon IS NULL
           OR NOT EXISTS (SELECT 1 FROM menu_disponibilidad x WHERE x.id_menu = m.id_menu)
           OR EXISTS (SELECT 1 FROM menu_disponibilidad x
                      WHERE x.id_menu = m.id_menu
                        AND (x.id_salon = p_id_salon
                             OR x.id_locacion = (SELECT s2.id_locacion FROM salon s2 WHERE s2.id_salon = p_id_salon))))
    GROUP BY m.id_menu, tm.id_tipo_menu, tm.descripcion
    ORDER BY tm.descripcion, m.nombre, m.precio_base;
$$;
