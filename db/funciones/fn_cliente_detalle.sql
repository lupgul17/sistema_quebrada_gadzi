CREATE OR REPLACE FUNCTION fn_cliente_detalle(p_id_cliente integer) RETURNS TABLE(id_cliente integer, id_persona integer, primer_nombre character varying, segundo_nombre character varying, primer_apellido character varying, segundo_apellido character varying, cui character varying, nit character varying, telefono character varying, correo character varying, fecha_creacion timestamp with time zone)
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
    WHERE c.id_cliente = p_id_cliente;
$$;
