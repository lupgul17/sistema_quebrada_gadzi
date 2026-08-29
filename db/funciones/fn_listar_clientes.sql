CREATE OR REPLACE FUNCTION fn_listar_clientes()
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
    ORDER BY p.primer_apellido, p.primer_nombre;
$$;