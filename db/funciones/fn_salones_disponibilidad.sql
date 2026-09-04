CREATE OR REPLACE FUNCTION fn_salones_disponibilidad(
    p_fecha DATE,
    p_hora_inicio TIME,
    p_hora_fin TIME,
    p_id_evento_excluir INTEGER DEFAULT NULL
)
RETURNS TABLE (
    id_salon    INTEGER,
    nombre      VARCHAR,
    capacidad   INTEGER,
    locacion    VARCHAR,
    disponible  BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        s.id_salon,
        s.nombre,
        s.capacidad,
        l.nombre AS locacion,
        fn_validar_disponibilidad_salon(s.id_salon, p_fecha, p_hora_inicio, p_hora_fin, p_id_evento_excluir) AS disponible
    FROM salon s
    JOIN locacion l ON l.id_locacion = s.id_locacion
    ORDER BY l.nombre, s.nombre;
$$;