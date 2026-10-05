CREATE OR REPLACE PROCEDURE sp_quitar_menu_cotizacion(IN p_id_cotizacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_cotizacion INTEGER;
BEGIN
    SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion_menu WHERE id_cotizacion_menu = p_id_cotizacion_menu;

    DELETE FROM cotizacion_menu WHERE id_cotizacion_menu = p_id_cotizacion_menu;

    CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
END;
$$;
