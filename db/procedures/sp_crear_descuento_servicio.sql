CREATE OR REPLACE PROCEDURE sp_crear_descuento_servicio(
    p_id_cotizacion_servicios  INTEGER,
    p_id_tipo_descuento        INTEGER,
    p_porcentaje               DECIMAL,
    p_monto_descontado         DECIMAL,
    p_motivo                   TEXT,
    p_id_empleado_solicito     INTEGER,
    OUT p_id_descuento         INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_subtotal_linea DECIMAL;
    v_monto_final    DECIMAL;
BEGIN
    SELECT subtotal INTO v_subtotal_linea FROM cotizacion_servicios WHERE id_cotizacion_servicios = p_id_cotizacion_servicios;

    IF v_subtotal_linea IS NULL THEN
        RAISE EXCEPTION 'No existe una linea de servicio con id_cotizacion_servicios = %', p_id_cotizacion_servicios;
    END IF;

    IF p_porcentaje IS NOT NULL THEN
        v_monto_final := ROUND(v_subtotal_linea * p_porcentaje / 100, 2);
    ELSE
        v_monto_final := p_monto_descontado;
    END IF;

    IF v_monto_final IS NULL OR v_monto_final <= 0 THEN
        RAISE EXCEPTION 'El descuento debe ser un monto o porcentaje mayor a cero';
    END IF;

    INSERT INTO cotizacion_servicios_descuento (
        id_cotizacion_servicios, id_tipo_descuento, porcentaje, monto_descontado, motivo, estado, id_empleado_solicito
    )
    VALUES (
        p_id_cotizacion_servicios, p_id_tipo_descuento, p_porcentaje, v_monto_final, p_motivo, 'pendiente', p_id_empleado_solicito
    )
    RETURNING id_descuento INTO p_id_descuento;
END;
$$;
