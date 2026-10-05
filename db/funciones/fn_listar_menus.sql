CREATE OR REPLACE FUNCTION fn_listar_menus(p_id_tipo_menu integer DEFAULT NULL::integer) RETURNS TABLE(id_menu integer, nombre character varying, precio_base numeric, unidad_medida character varying, descripcion text, activo boolean, id_tipo_menu integer, tipo_menu character varying, componentes text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        m.id_menu, m.nombre, m.precio_base, m.unidad_medida, m.descripcion, m.activo,
        tm.id_tipo_menu, tm.descripcion AS tipo_menu,
        STRING_AGG(cm.nombre, ', ' ORDER BY cm.nombre) AS componentes
    FROM menu m
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    LEFT JOIN menu_componentes_menu mcm ON mcm.id_menu = m.id_menu
    LEFT JOIN componente_menu cm ON cm.id_componente = mcm.id_componente
    WHERE (p_id_tipo_menu IS NULL OR m.id_tipo_menu = p_id_tipo_menu)
      AND NOT m.es_personalizado
    GROUP BY m.id_menu, tm.id_tipo_menu, tm.descripcion
    ORDER BY tm.descripcion, m.nombre;
$$;
