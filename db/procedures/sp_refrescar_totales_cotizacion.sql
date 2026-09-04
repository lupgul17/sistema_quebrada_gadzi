CREATE OR REPLACE PROCEDURE sp_refrescar_totales_cotizacion(p_id_cotizacion INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE cotizacion c
    SET subtotal_menus = vc.subtotal_menus,
        subtotal_servicios = vc.subtotal_servicios,
        total_descuento = vc.total_descuento,
        total = vc.total
    FROM v_cotizacion_calculada vc
    WHERE vc.id_cotizacion = c.id_cotizacion AND c.id_cotizacion = p_id_cotizacion;
END;
$$;