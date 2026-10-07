CREATE OR REPLACE FUNCTION fn_listar_areas_menu() RETURNS TABLE(id_locacion integer, locacion character varying, id_salon integer, salon character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT l.id_locacion, l.nombre, s.id_salon, s.nombre
    FROM locacion l
    LEFT JOIN salon s ON s.id_locacion = l.id_locacion
    ORDER BY l.nombre, s.nombre;
$$;
