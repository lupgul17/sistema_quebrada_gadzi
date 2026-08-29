CREATE OR REPLACE FUNCTION fn_buscar_cliente(p_texto VARCHAR)
RETURNS TABLE (
    id_cliente       INTEGER,
    id_persona       INTEGER,
    primer_nombre    VARCHAR,
    segundo_nombre   VARCHAR,
    primer_apellido  VARCHAR,
    segundo_apellido VARCHAR,
    cui              VARCHAR,
    nit              VARCHAR,
    telefono         VARCHAR,
    correo           VARCHAR,
    fecha_creacion   TIMESTAMPTZ
)
LANGUAGE sql
STABLE
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