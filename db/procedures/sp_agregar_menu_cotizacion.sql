CREATE OR REPLACE PROCEDURE sp_agregar_menu_cotizacion(
    p_id_cotizacion          INTEGER,
    p_id_menu                INTEGER,
    OUT p_id_cotizacion_menu INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_precio_base DECIMAL;
    v_tipo_menu   VARCHAR;
    v_id_evento   INTEGER;
    v_cantidad    INTEGER;
BEGIN
    SELECT m.precio_base, tm.descripcion INTO v_precio_base, v_tipo_menu
    FROM menu m JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    WHERE m.id_menu = p_id_menu;

    SELECT id_evento INTO v_id_evento FROM cotizacion WHERE id_cotizacion = p_id_cotizacion;

    SELECT CASE
        WHEN v_tipo_menu = 'individual_infantil' THEN total_menores
        ELSE total_adultos
    END INTO v_cantidad
    FROM evento WHERE id_evento = v_id_evento;

    INSERT INTO cotizacion_menu (id_cotizacion, id_menu, precio_unitario_congelado, subtotal)
    VALUES (p_id_cotizacion, p_id_menu, v_precio_base, v_precio_base * v_cantidad)
    RETURNING id_cotizacion_menu INTO p_id_cotizacion_menu;

    CALL sp_refrescar_totales_cotizacion(p_id_cotizacion);
END;
$$;