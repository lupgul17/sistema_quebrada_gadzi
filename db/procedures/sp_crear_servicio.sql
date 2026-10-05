CREATE OR REPLACE PROCEDURE sp_crear_servicio(IN p_id_categoria_servicio integer, IN p_nombre character varying, IN p_precio_base numeric, IN p_unidad_medida character varying, OUT p_id_servicio integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO servicios (id_categoria_servicio, nombre, precio_base, unidad_medida, activo)
    VALUES (p_id_categoria_servicio, p_nombre, p_precio_base, p_unidad_medida, true)
    RETURNING id_servicio INTO p_id_servicio;
END;
$$;
