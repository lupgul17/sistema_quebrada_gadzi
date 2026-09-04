DROP FUNCTION fn_buscar_usuario_login(character varying);

CREATE OR REPLACE FUNCTION fn_buscar_usuario_login(p_username character varying)
RETURNS TABLE(
    id_usuario integer, id_persona integer, username character varying, password_hash character varying,
    id_tipo_usuario integer, tipo_usuario character varying,
    id_rol_acceso integer, rol_acceso character varying,
    nombre_completo text, confirmacion boolean
)
LANGUAGE sql
STABLE
AS $function$
    SELECT
        u.id_usuario,
        u.id_persona,
        u.username,
        u.password_hash,
        u.id_tipo_usuario,
        tu.descripcion AS tipo_usuario,
        u.id_rol_acceso,
        tra.descripcion AS rol_acceso,
        p.primer_nombre || ' ' || p.primer_apellido AS nombre_completo,
        u.confirmacion
    FROM usuario u
    JOIN persona p ON p.id_persona = u.id_persona
    JOIN tc_tipo_usuario tu ON tu.id_tipo_usuario = u.id_tipo_usuario
    LEFT JOIN tc_rol_acceso tra ON tra.id_rol_acceso = u.id_rol_acceso
    WHERE u.username = p_username;
$function$;