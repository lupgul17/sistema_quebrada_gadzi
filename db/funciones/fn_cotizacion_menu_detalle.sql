CREATE OR REPLACE FUNCTION fn_cotizacion_menu_detalle(p_id_cotizacion INTEGER)
RETURNS TABLE (
    id_cotizacion_menu         INTEGER,
    id_menu                    INTEGER,
    menu                       VARCHAR,
    tipo_menu                  VARCHAR,
    precio_unitario_congelado  DECIMAL,
    subtotal                   DECIMAL
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        cm.id_cotizacion_menu, cm.id_menu, m.nombre AS menu, tm.descripcion AS tipo_menu,
        cm.precio_unitario_congelado, cm.subtotal
    FROM cotizacion_menu cm
    JOIN menu m ON m.id_menu = cm.id_menu
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    WHERE cm.id_cotizacion = p_id_cotizacion
    ORDER BY m.nombre;
$$;