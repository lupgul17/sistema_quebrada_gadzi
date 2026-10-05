CREATE OR REPLACE FUNCTION fn_usuario_auth(p_id_usuario integer) RETURNS TABLE(id_usuario integer, id_persona integer, username character varying, activo boolean, confirmacion boolean, id_rol_acceso integer, rol_acceso character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT u.id_usuario, u.id_persona, u.username, u.activo, u.confirmacion, u.id_rol_acceso, tra.descripcion
    FROM usuario u
    LEFT JOIN tc_rol_acceso tra ON tra.id_rol_acceso = u.id_rol_acceso
    WHERE u.id_usuario = p_id_usuario;
$$;
