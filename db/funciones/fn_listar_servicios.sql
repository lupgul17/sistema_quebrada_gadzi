CREATE OR REPLACE FUNCTION fn_listar_servicios(p_id_categoria_servicio INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_servicio             INTEGER,
    nombre                  VARCHAR,
    precio_base             DECIMAL,
    unidad_medida           VARCHAR,
    activo                  BOOLEAN,
    id_categoria_servicio   INTEGER,
    categoria               VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        s.id_servicio,
        s.nombre,
        s.precio_base,
        s.unidad_medida,
        s.activo,
        cs.id_categoria_servicio,
        cs.descripcion AS categoria
    FROM servicios s
    JOIN tc_categoria_servicio cs ON cs.id_categoria_servicio = s.id_categoria_servicio
    WHERE p_id_categoria_servicio IS NULL OR s.id_categoria_servicio = p_id_categoria_servicio
    ORDER BY cs.descripcion, s.nombre;
$$;