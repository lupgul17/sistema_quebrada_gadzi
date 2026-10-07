CREATE OR REPLACE PROCEDURE sp_agregar_menu_cotizacion(IN p_id_cotizacion integer, IN p_id_menu integer, IN p_cantidad integer, OUT p_id_cotizacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_precio_base DECIMAL;
    v_tipo_menu   VARCHAR;
    v_id_evento   INTEGER;
    v_activa      BOOLEAN;
    v_cantidad    INTEGER := p_cantidad;
BEGIN
    SELECT id_evento, activa INTO v_id_evento, v_activa FROM cotizacion WHERE id_cotizacion = p_id_cotizacion;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la cotizacion con id = %', p_id_cotizacion;
    END IF;
    IF NOT v_activa THEN
        RAISE EXCEPTION 'Solo se puede editar la version activa de la cotizacion';
    END IF;

    SELECT m.precio_base, tm.descripcion INTO v_precio_base, v_tipo_menu
    FROM menu m JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    WHERE m.id_menu = p_id_menu;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el menu con id = %', p_id_menu;
    END IF;

    IF NOT fn_menu_disponible_evento(p_id_menu, v_id_evento) THEN
        RAISE EXCEPTION 'Este menu no se ofrece en los salones de este evento';
    END IF;

    IF v_cantidad IS NULL THEN
        SELECT CASE WHEN v_tipo_menu = 'individual_infantil' THEN total_menores ELSE total_adultos END
        INTO v_cantidad FROM evento WHERE id_evento = v_id_evento;
        IF v_cantidad IS NULL OR v_cantidad <= 0 THEN
            RAISE EXCEPTION 'La cantidad automatica es 0 (el evento no tiene % registrados). Indica la cantidad manualmente.',
                CASE WHEN v_tipo_menu = 'individual_infantil' THEN 'ninos' ELSE 'adultos' END;
        END IF;
    ELSIF v_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor a cero';
    END IF;

    INSERT INTO cotizacion_menu (id_cotizacion, id_menu, precio_unitario_congelado, cantidad, subtotal)
    VALUES (p_id_cotizacion, p_id_menu, v_precio_base, v_cantidad, v_precio_base * v_cantidad)
    RETURNING id_cotizacion_menu INTO p_id_cotizacion_menu;

    CALL sp_refrescar_totales_cotizacion(p_id_cotizacion);
END;
$$;
