REATE OR REPLACE PROCEDURE sp_resolver_descuento_servicio(
    p_id_descuento         INTEGER,
    p_nuevo_estado         VARCHAR,
    p_id_empleado_aprobo   INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_cotizacion_servicios INTEGER;
    v_id_cotizacion           INTEGER;
    v_estado_actual           VARCHAR;
BEGIN
    SELECT csd.id_cotizacion_servicios, csd.estado INTO v_id_cotizacion_servicios, v_estado_actual
    FROM cotizacion_servicios_descuento csd
    WHERE csd.id_descuento = p_id_descuento;

    IF v_id_cotizacion_servicios IS NULL THEN
        RAISE EXCEPTION 'No existe un descuento con id_descuento = %', p_id_descuento;
    END IF;

    IF v_estado_actual != 'pendiente' THEN
        RAISE EXCEPTION 'Este descuento ya fue % y no se puede modificar', v_estado_actual;
    END IF;

    IF p_nuevo_estado NOT IN ('aprobado', 'rechazado') THEN
        RAISE EXCEPTION 'Estado invalido: %', p_nuevo_estado;
    END IF;

    UPDATE cotizacion_servicios_descuento
    SET estado = p_nuevo_estado,
        id_empleado_aprobo = p_id_empleado_aprobo
    WHERE id_descuento = p_id_descuento;

    SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion_servicios WHERE id_cotizacion_servicios = v_id_cotizacion_servicios;

    CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
END;
$$;