CREATE OR REPLACE FUNCTION fn_obtener_usuario(p_id_usuario INTEGER)
RETURNS TABLE(id_usuario integer, username character varying, primer_nombre character varying, segundo_nombre character varying,
              primer_apellido character varying, segundo_apellido character varying, cui character varying,
              telefono character varying, correo character varying, tipo_empleado character varying)
LANGUAGE sql STABLE
AS $$
    SELECT
        u.id_usuario, u.username,
        p.primer_nombre, p.segundo_nombre, p.primer_apellido, p.segundo_apellido,
        p.cui, p.telefono, p.correo,
        (SELECT te.descripcion
           FROM empleado e
           JOIN tc_tipo_empleado te ON te.id_tipo_empleado = e.id_tipo_empleado
          WHERE e.id_persona = u.id_persona
          ORDER BY e.id_empleado LIMIT 1) AS tipo_empleado
    FROM usuario u
    JOIN persona p ON p.id_persona = u.id_persona
    WHERE u.id_usuario = p_id_usuario;
$$;
