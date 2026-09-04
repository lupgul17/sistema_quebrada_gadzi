CREATE OR REPLACE PROCEDURE sp_quitar_servicio_cotizacion(p_id_cotizacion_servicios INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_cotizacion INTEGER;
BEGIN
    SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion_servicios WHERE id_cotizacion_servicios = p_id_cotizacion_servicios;

    DELETE FROM cotizacion_servicios WHERE id_cotizacion_servicios = p_id_cotizacion_servicios;

    CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
END;
$$;