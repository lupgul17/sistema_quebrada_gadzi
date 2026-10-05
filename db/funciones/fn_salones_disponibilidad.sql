CREATE OR REPLACE FUNCTION fn_salones_disponibilidad(p_fecha date, p_hora_inicio time without time zone, p_hora_fin time without time zone, p_id_evento_excluir integer DEFAULT NULL::integer) RETURNS TABLE(id_salon integer, nombre character varying, capacidad integer, locacion character varying, disponible boolean)
    LANGUAGE sql STABLE
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
