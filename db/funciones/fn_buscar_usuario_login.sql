CREATE OR REPLACE FUNCTION fn_buscar_usuario_login(p_username VARCHAR)
RETURNS TABLE (
    id_usuario      INTEGER,
    id_persona      INTEGER,
    username        VARCHAR,
    password_hash   VARCHAR,
    id_tipo_usuario INTEGER,
    tipo_usuario    VARCHAR,
    nombre_completo TEXT,
    confirmacion    BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        u.id_usuario,
        u.id_persona,
        u.username,
        u.password_hash,
        u.id_tipo_usuario,
        tu.descripcion AS tipo_usuario,
        p.primer_nombre || ' ' || p.primer_apellido AS nombre_completo,
        u.confirmacion
    FROM usuario u
    JOIN persona p ON p.id_persona = u.id_persona
    JOIN tc_tipo_usuario tu ON tu.id_tipo_usuario = u.id_tipo_usuario
    WHERE u.username = p_username;
$$;