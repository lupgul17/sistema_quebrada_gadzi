CREATE OR REPLACE PROCEDURE sp_quitar_menu_degustacion(IN p_id_degustacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_cotizacion_menu  INTEGER;
    v_id_cotizacion       INTEGER;
BEGIN
    SELECT id_cotizacion_menu INTO v_id_cotizacion_menu
    FROM degustacion_menu WHERE id_degustacion_menu = p_id_degustacion_menu;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe esa línea de degustación';
    END IF;

    -- Borrar primero la fila hija (degustacion_menu), antes de tocar la madre (cotizacion_menu)
    DELETE FROM degustacion_menu WHERE id_degustacion_menu = p_id_degustacion_menu;

    IF v_id_cotizacion_menu IS NOT NULL THEN
        SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion_menu WHERE id_cotizacion_menu = v_id_cotizacion_menu;
        DELETE FROM cotizacion_menu WHERE id_cotizacion_menu = v_id_cotizacion_menu;
        CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
    END IF;
END;
$$;
