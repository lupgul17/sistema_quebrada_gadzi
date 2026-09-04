CREATE OR REPLACE PROCEDURE sp_agregar_servicio_cotizacion(
    p_id_cotizacion               INTEGER,
    p_id_servicio                 INTEGER,
    p_cantidad                    INTEGER,
    OUT p_id_cotizacion_servicios INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_precio_base DECIMAL;
BEGIN
    SELECT precio_base INTO v_precio_base FROM servicios WHERE id_servicio = p_id_servicio;

    INSERT INTO cotizacion_servicios (id_cotizacion, id_servicio, cantidad, precio_unitario_congelado, subtotal)
    VALUES (p_id_cotizacion, p_id_servicio, p_cantidad, v_precio_base, v_precio_base * p_cantidad)
    RETURNING id_cotizacion_servicios INTO p_id_cotizacion_servicios;

    CALL sp_refrescar_totales_cotizacion(p_id_cotizacion);
END;
$$;