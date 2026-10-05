CREATE OR REPLACE FUNCTION fn_listar_usuarios() RETURNS TABLE(id_usuario integer, username character varying, nombre_completo text, correo character varying, telefono character varying, id_rol_acceso integer, rol character varying, tipo_empleado character varying, activo boolean, fecha_ultimo_acceso timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        u.id_usuario, u.username,
        p.primer_nombre || ' ' || p.primer_apellido AS nombre_completo,
        p.correo, p.telefono,
        u.id_rol_acceso, tra.descripcion AS rol,
        (SELECT te.descripcion
           FROM empleado e
           JOIN tc_tipo_empleado te ON te.id_tipo_empleado = e.id_tipo_empleado
          WHERE e.id_persona = u.id_persona
          ORDER BY e.id_empleado LIMIT 1) AS tipo_empleado,
        u.activo, u.fecha_ultimo_acceso
    FROM usuario u
    JOIN persona p ON p.id_persona = u.id_persona
    LEFT JOIN tc_rol_acceso tra ON tra.id_rol_acceso = u.id_rol_acceso
    ORDER BY u.username;
$$;
