CREATE OR REPLACE FUNCTION fn_listar_salones()
RETURNS TABLE (
    id_salon    INTEGER,
    nombre      VARCHAR,
    capacidad   INTEGER,
    descripcion TEXT,
    locacion    VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        s.id_salon,
        s.nombre,
        s.capacidad,
        s.descripcion,
        l.nombre AS locacion
    FROM salon s
    JOIN locacion l ON l.id_locacion = s.id_locacion
    ORDER BY l.nombre, s.nombre;
$$;