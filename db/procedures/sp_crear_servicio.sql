CREATE OR REPLACE PROCEDURE sp_crear_servicio(
    p_id_categoria_servicio  INTEGER,
    p_nombre                 VARCHAR,
    p_precio_base            DECIMAL,
    p_unidad_medida          VARCHAR,
    OUT p_id_servicio        INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO servicios (id_categoria_servicio, nombre, precio_base, unidad_medida, activo)
    VALUES (p_id_categoria_servicio, p_nombre, p_precio_base, p_unidad_medida, true)
    RETURNING id_servicio INTO p_id_servicio;
END;
$$;