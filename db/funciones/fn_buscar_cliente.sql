CREATE OR REPLACE FUNCTION fn_buscar_cliente(p_texto character varying) RETURNS TABLE(id_cliente integer, id_persona integer, primer_nombre character varying, segundo_nombre character varying, primer_apellido character varying, segundo_apellido character varying, cui character varying, nit character varying, telefono character varying, correo character varying, fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        c.id_cliente,
        p.id_persona,
        p.primer_nombre,
        p.segundo_nombre,
        p.primer_apellido,
        p.segundo_apellido,
        p.cui,
        p.nit,
        p.telefono,
        p.correo,
        c.fecha_creacion
    FROM cliente c
    JOIN persona p ON p.id_persona = c.id_persona
    WHERE
        unaccent(p.primer_nombre) ILIKE unaccent('%' || p_texto || '%')
        OR unaccent(p.segundo_nombre) ILIKE unaccent('%' || p_texto || '%')
        OR unaccent(p.primer_apellido) ILIKE unaccent('%' || p_texto || '%')
        OR unaccent(p.segundo_apellido) ILIKE unaccent('%' || p_texto || '%')
        OR p.telefono ILIKE '%' || p_texto || '%'
        OR p.cui ILIKE '%' || p_texto || '%'
    ORDER BY p.primer_apellido, p.primer_nombre;
$$;
