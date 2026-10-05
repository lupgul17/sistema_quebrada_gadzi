CREATE OR REPLACE PROCEDURE sp_editar_usuario(IN p_id_usuario integer, IN p_id_rol_acceso integer, IN p_activo boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rol_actual            VARCHAR;
    v_activo_actual         BOOLEAN;
    v_rol_nuevo             VARCHAR;
    v_otros_superusuarios   INTEGER;
BEGIN
    IF p_activo IS NULL THEN
        RAISE EXCEPTION 'Falta indicar si el usuario queda activo';
    END IF;

    SELECT tra.descripcion, u.activo INTO v_rol_actual, v_activo_actual
    FROM usuario u
    LEFT JOIN tc_rol_acceso tra ON tra.id_rol_acceso = u.id_rol_acceso
    WHERE u.id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el usuario con id = %', p_id_usuario;
    END IF;

    SELECT descripcion INTO v_rol_nuevo FROM tc_rol_acceso WHERE id_rol_acceso = p_id_rol_acceso;
    IF v_rol_nuevo IS NULL THEN
        RAISE EXCEPTION 'Rol invalido';
    END IF;

    IF v_rol_actual = 'Superusuario' AND v_activo_actual AND (v_rol_nuevo <> 'Superusuario' OR NOT p_activo) THEN
        SELECT COUNT(*) INTO v_otros_superusuarios
        FROM usuario u
        JOIN tc_rol_acceso tra ON tra.id_rol_acceso = u.id_rol_acceso
        WHERE tra.descripcion = 'Superusuario' AND u.activo AND u.id_usuario <> p_id_usuario;

        IF v_otros_superusuarios = 0 THEN
            RAISE EXCEPTION 'No se puede dejar el sistema sin un Superusuario activo';
        END IF;
    END IF;

    UPDATE usuario SET id_rol_acceso = p_id_rol_acceso, activo = p_activo WHERE id_usuario = p_id_usuario;
END;
$$;
