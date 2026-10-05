CREATE OR REPLACE PROCEDURE sp_crear_cotizacion(IN p_id_evento integer, IN p_vigencia_dias integer, IN p_deposito_garantia numeric, IN p_id_empleado integer, OUT p_id_cotizacion integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_nueva_version  INTEGER;
    v_id_anterior    INTEGER;
    v_id_nueva_linea INTEGER;
    r_menu           RECORD;
    r_serv           RECORD;
BEGIN
    -- Version activa actual (la que se va a copiar), antes de desactivarla
    SELECT id_cotizacion INTO v_id_anterior
    FROM cotizacion
    WHERE id_evento = p_id_evento AND activa = true
    ORDER BY version DESC
    LIMIT 1;

    -- Desactivar la version activa anterior, si existe
    UPDATE cotizacion
    SET activa = false,
        id_estado_cotizacion = (SELECT id_estado_cotizacion FROM tc_estado_cotizacion WHERE descripcion = 'reemplazada')
    WHERE id_evento = p_id_evento AND activa = true;

    SELECT COALESCE(MAX(version), 0) + 1 INTO v_nueva_version
    FROM cotizacion WHERE id_evento = p_id_evento;

    -- Encabezado: vigencia y deposito vienen de los parametros; los detalles del evento se heredan
    INSERT INTO cotizacion (
        id_evento, version, fecha_cotizacion, vigencia_dias, deposito_garantia, activa, id_estado_cotizacion, id_empleado,
        brindis, cantidad_mesa_principal, cantidad_mesas_reservadas, id_color_mantel, id_color_cubremanteles, observaciones, boquitas
    )
    SELECT
        p_id_evento, v_nueva_version, CURRENT_DATE, p_vigencia_dias, p_deposito_garantia, true,
        (SELECT id_estado_cotizacion FROM tc_estado_cotizacion WHERE descripcion = 'estimada'),
        p_id_empleado,
        COALESCE(a.brindis, false), a.cantidad_mesa_principal, a.cantidad_mesas_reservadas,
        a.id_color_mantel, a.id_color_cubremanteles, a.observaciones, a.boquitas
    FROM (SELECT 1) AS base
    LEFT JOIN cotizacion a ON a.id_cotizacion = v_id_anterior
    RETURNING id_cotizacion INTO p_id_cotizacion;

    IF v_id_anterior IS NOT NULL THEN
        -- Lineas de menu: mismo precio congelado y cantidad. Si una linea es un platillo extra de
        -- degustacion, el vinculo se mueve a la linea nueva (asi seguira cobrandose y se podra quitar).
        FOR r_menu IN
            SELECT * FROM cotizacion_menu WHERE id_cotizacion = v_id_anterior ORDER BY id_cotizacion_menu
        LOOP
            INSERT INTO cotizacion_menu (id_cotizacion, id_menu, precio_unitario_congelado, cantidad, subtotal)
            VALUES (p_id_cotizacion, r_menu.id_menu, r_menu.precio_unitario_congelado, r_menu.cantidad, r_menu.subtotal)
            RETURNING id_cotizacion_menu INTO v_id_nueva_linea;

            UPDATE degustacion_menu
            SET id_cotizacion_menu = v_id_nueva_linea
            WHERE id_cotizacion_menu = r_menu.id_cotizacion_menu;
        END LOOP;

        -- Lineas de servicio, con sus descuentos aprobados y pendientes (los rechazados no se arrastran)
        FOR r_serv IN
            SELECT * FROM cotizacion_servicios WHERE id_cotizacion = v_id_anterior ORDER BY id_cotizacion_servicios
        LOOP
            INSERT INTO cotizacion_servicios (id_cotizacion, id_servicio, cantidad, precio_unitario_congelado, subtotal)
            VALUES (p_id_cotizacion, r_serv.id_servicio, r_serv.cantidad, r_serv.precio_unitario_congelado, r_serv.subtotal)
            RETURNING id_cotizacion_servicios INTO v_id_nueva_linea;

            INSERT INTO cotizacion_servicios_descuento (
                id_cotizacion_servicios, id_tipo_descuento, porcentaje, monto_descontado, motivo, estado,
                id_empleado_solicito, id_empleado_aprobo, fecha_creacion
            )
            SELECT v_id_nueva_linea, id_tipo_descuento, porcentaje, monto_descontado, motivo, estado,
                   id_empleado_solicito, id_empleado_aprobo, fecha_creacion
            FROM cotizacion_servicios_descuento
            WHERE id_cotizacion_servicios = r_serv.id_cotizacion_servicios
              AND estado IN ('aprobado', 'pendiente');
        END LOOP;

        CALL sp_refrescar_totales_cotizacion(p_id_cotizacion);
    END IF;
END;
$$;
