CREATE OR REPLACE FUNCTION fn_menu_detalle(p_id_menu integer) RETURNS TABLE(id_menu integer, nombre character varying, precio_base numeric, unidad_medida character varying, descripcion text, activo boolean, id_tipo_menu integer, tipo_menu character varying, componentes_ids integer[])
    LANGUAGE sql STABLE
    AS $$
    SELECT
        m.id_menu, m.nombre, m.precio_base, m.unidad_medida, m.descripcion, m.activo,
        tm.id_tipo_menu, tm.descripcion AS tipo_menu,
        ARRAY_AGG(cm.id_componente ORDER BY cm.nombre) FILTER (WHERE cm.id_componente IS NOT NULL) AS componentes_ids
    FROM menu m
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    LEFT JOIN menu_componentes_menu mcm ON mcm.id_menu = m.id_menu
    LEFT JOIN componente_menu cm ON cm.id_componente = mcm.id_componente
    WHERE m.id_menu = p_id_menu
    GROUP BY m.id_menu, tm.id_tipo_menu, tm.descripcion;
$$;
