CREATE OR REPLACE PROCEDURE sp_editar_servicio(IN p_id_servicio integer, IN p_id_categoria_servicio integer, IN p_nombre character varying, IN p_precio_base numeric, IN p_unidad_medida character varying, IN p_activo boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM servicios WHERE id_servicio = p_id_servicio) THEN
        RAISE EXCEPTION 'No existe un servicio con id_servicio = %', p_id_servicio;
    END IF;

    UPDATE servicios
    SET id_categoria_servicio = p_id_categoria_servicio,
        nombre = p_nombre,
        precio_base = p_precio_base,
        unidad_medida = p_unidad_medida,
        activo = p_activo
    WHERE id_servicio = p_id_servicio;
END;
$$;
