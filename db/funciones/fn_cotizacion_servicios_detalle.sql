CREATE OR REPLACE FUNCTION fn_cotizacion_servicios_detalle(p_id_cotizacion integer) RETURNS TABLE(id_cotizacion_servicios integer, id_servicio integer, servicio character varying, categoria character varying, cantidad integer, precio_unitario_congelado numeric, subtotal numeric, tiene_descuento_pendiente boolean)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        cs.id_cotizacion_servicios, cs.id_servicio, s.nombre AS servicio, csc.descripcion AS categoria,
        cs.cantidad, cs.precio_unitario_congelado, cs.subtotal,
        EXISTS (
            SELECT 1 FROM cotizacion_servicios_descuento csd
            WHERE csd.id_cotizacion_servicios = cs.id_cotizacion_servicios AND csd.estado = 'pendiente'
        ) AS tiene_descuento_pendiente
    FROM cotizacion_servicios cs
    JOIN servicios s ON s.id_servicio = cs.id_servicio
    JOIN tc_categoria_servicio csc ON csc.id_categoria_servicio = s.id_categoria_servicio
    WHERE cs.id_cotizacion = p_id_cotizacion
    ORDER BY s.nombre;
$$;
