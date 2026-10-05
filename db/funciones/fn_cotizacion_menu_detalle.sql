CREATE OR REPLACE FUNCTION fn_cotizacion_menu_detalle(p_id_cotizacion integer) RETURNS TABLE(id_cotizacion_menu integer, id_menu integer, menu character varying, tipo_menu character varying, cantidad integer, precio_unitario_congelado numeric, subtotal numeric, es_extra_degustacion boolean)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        cm.id_cotizacion_menu, cm.id_menu, m.nombre AS menu, tm.descripcion AS tipo_menu,
        cm.cantidad, cm.precio_unitario_congelado, cm.subtotal,
        EXISTS (SELECT 1 FROM degustacion_menu dm WHERE dm.id_cotizacion_menu = cm.id_cotizacion_menu) AS es_extra_degustacion
    FROM cotizacion_menu cm
    JOIN menu m ON m.id_menu = cm.id_menu
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    WHERE cm.id_cotizacion = p_id_cotizacion
    ORDER BY
        EXISTS (SELECT 1 FROM degustacion_menu dm WHERE dm.id_cotizacion_menu = cm.id_cotizacion_menu),
        m.nombre;
$$;
