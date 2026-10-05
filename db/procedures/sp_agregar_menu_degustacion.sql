CREATE OR REPLACE PROCEDURE sp_agregar_menu_degustacion(IN p_id_degustacion integer, IN p_id_menu integer, OUT p_id_degustacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_cantidad_actual        INTEGER;
    v_es_adicional           BOOLEAN;
    v_id_evento              INTEGER;
    v_id_cotizacion          INTEGER;
    v_precio_menu            DECIMAL;
    v_id_cotizacion_menu     INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_cantidad_actual FROM degustacion_menu WHERE id_degustacion = p_id_degustacion;

    IF v_cantidad_actual >= 4 THEN
        RAISE EXCEPTION 'Ya se alcanzó el máximo de 4 platillos de degustación para este evento';
    END IF;

    v_es_adicional := v_cantidad_actual >= 2;

    INSERT INTO degustacion_menu (id_degustacion, id_menu, resultado, es_adicional)
    VALUES (p_id_degustacion, p_id_menu, 'pendiente', v_es_adicional)
    RETURNING id_degustacion_menu INTO p_id_degustacion_menu;

    IF v_es_adicional THEN
        SELECT id_evento INTO v_id_evento FROM degustacion WHERE id_degustacion = p_id_degustacion;

        SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion WHERE id_evento = v_id_evento AND activa = true;

        IF v_id_cotizacion IS NULL THEN
            RAISE EXCEPTION 'Este evento no tiene ninguna cotización activa todavía — no se puede cobrar el platillo extra hasta que exista una';
        END IF;

        SELECT precio_base INTO v_precio_menu FROM menu WHERE id_menu = p_id_menu;

        INSERT INTO cotizacion_menu (id_cotizacion, id_menu, precio_unitario_congelado, cantidad, subtotal)
        VALUES (v_id_cotizacion, p_id_menu, v_precio_menu, 1, v_precio_menu)
        RETURNING id_cotizacion_menu INTO v_id_cotizacion_menu;

        UPDATE degustacion_menu
        SET id_cotizacion_menu = v_id_cotizacion_menu
        WHERE id_degustacion_menu = p_id_degustacion_menu;

        CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
    END IF;
END;
$$;
