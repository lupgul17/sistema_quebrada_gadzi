CREATE OR REPLACE PROCEDURE sp_editar_cantidad_menu_cotizacion(IN p_id_cotizacion_menu integer, IN p_cantidad integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_cotizacion INTEGER;
    v_activa        BOOLEAN;
BEGIN
    SELECT cm.id_cotizacion, c.activa INTO v_id_cotizacion, v_activa
    FROM cotizacion_menu cm
    JOIN cotizacion c ON c.id_cotizacion = cm.id_cotizacion
    WHERE cm.id_cotizacion_menu = p_id_cotizacion_menu;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe esa linea de menu';
    END IF;
    IF NOT v_activa THEN
        RAISE EXCEPTION 'Solo se puede editar la version activa de la cotizacion';
    END IF;
    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor a cero';
    END IF;
    IF EXISTS (SELECT 1 FROM degustacion_menu WHERE id_cotizacion_menu = p_id_cotizacion_menu) THEN
        RAISE EXCEPTION 'Esta linea es un platillo extra de degustacion: se cobra de a uno y no se edita. Quitala desde Degustacion.';
    END IF;

    UPDATE cotizacion_menu
    SET cantidad = p_cantidad,
        subtotal = precio_unitario_congelado * p_cantidad
    WHERE id_cotizacion_menu = p_id_cotizacion_menu;

    CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
END;
$$;
