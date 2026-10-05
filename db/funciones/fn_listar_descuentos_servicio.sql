CREATE OR REPLACE FUNCTION fn_listar_descuentos_servicio(p_id_cotizacion_servicios integer) RETURNS TABLE(id_descuento integer, id_tipo_descuento integer, tipo_descuento character varying, porcentaje numeric, monto_descontado numeric, motivo text, estado character varying, solicito text, aprobo text, fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        csd.id_descuento, csd.id_tipo_descuento, td.descripcion AS tipo_descuento,
        csd.porcentaje, csd.monto_descontado, csd.motivo, csd.estado,
        ps.primer_nombre || ' ' || ps.primer_apellido AS solicito,
        pa.primer_nombre || ' ' || pa.primer_apellido AS aprobo,
        csd.fecha_creacion
    FROM cotizacion_servicios_descuento csd
    JOIN tc_tipo_descuento td ON td.id_tipo_descuento = csd.id_tipo_descuento
    LEFT JOIN empleado es ON es.id_empleado = csd.id_empleado_solicito
    LEFT JOIN persona ps ON ps.id_persona = es.id_persona
    LEFT JOIN empleado ea ON ea.id_empleado = csd.id_empleado_aprobo
    LEFT JOIN persona pa ON pa.id_persona = ea.id_persona
    WHERE csd.id_cotizacion_servicios = p_id_cotizacion_servicios
    ORDER BY csd.fecha_creacion DESC;
$$;
