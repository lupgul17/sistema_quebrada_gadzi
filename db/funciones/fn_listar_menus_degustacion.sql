CREATE OR REPLACE FUNCTION fn_listar_menus_degustacion(p_id_degustacion integer) RETURNS TABLE(id_degustacion_menu integer, id_menu integer, menu character varying, tipo_menu character varying, resultado character varying, es_adicional boolean, notas text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        dm.id_degustacion_menu, dm.id_menu, m.nombre AS menu, tm.descripcion AS tipo_menu, dm.resultado, dm.es_adicional, dm.notas
    FROM degustacion_menu dm
    JOIN menu m ON m.id_menu = dm.id_menu
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    WHERE dm.id_degustacion = p_id_degustacion
    ORDER BY dm.id_degustacion_menu;
$$;
