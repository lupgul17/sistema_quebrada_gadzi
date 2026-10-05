CREATE OR REPLACE PROCEDURE sp_crear_usuario(IN p_primer_nombre character varying, IN p_segundo_nombre character varying, IN p_primer_apellido character varying, IN p_segundo_apellido character varying, IN p_cui character varying, IN p_telefono character varying, IN p_correo character varying, IN p_username character varying, IN p_password_hash character varying, IN p_id_rol_acceso integer, IN p_id_tipo_empleado integer, OUT p_id_usuario integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_cui             VARCHAR := NULLIF(TRIM(p_cui), '');
    v_correo          VARCHAR := NULLIF(TRIM(p_correo), '');
    v_telefono        VARCHAR := NULLIF(TRIM(p_telefono), '');
    v_username        VARCHAR := TRIM(p_username);
    v_id_persona      INTEGER;
    v_count_correo    INTEGER;
    v_id_empleado     INTEGER;
    v_id_tipo_usuario INTEGER;
BEGIN
    IF v_username IS NULL OR v_username = '' THEN
        RAISE EXCEPTION 'El nombre de usuario es obligatorio';
    END IF;
    IF EXISTS (SELECT 1 FROM usuario WHERE LOWER(username) = LOWER(v_username)) THEN
        RAISE EXCEPTION 'El usuario "%" ya existe', v_username;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tc_rol_acceso WHERE id_rol_acceso = p_id_rol_acceso) THEN
        RAISE EXCEPTION 'Rol invalido';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tc_tipo_empleado WHERE id_tipo_empleado = p_id_tipo_empleado) THEN
        RAISE EXCEPTION 'Tipo de empleado invalido';
    END IF;

    SELECT id_tipo_usuario INTO v_id_tipo_usuario FROM tc_tipo_usuario WHERE descripcion = 'staff';

    -- Buscar persona existente: CUI primero, correo como respaldo
    IF v_cui IS NOT NULL THEN
        SELECT id_persona INTO v_id_persona FROM persona WHERE cui = v_cui;
    END IF;
    IF v_id_persona IS NULL AND v_correo IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count_correo FROM persona WHERE correo = v_correo;
        IF v_count_correo > 1 THEN
            RAISE EXCEPTION 'Hay mas de una persona con el correo %, no se puede determinar cual usar. Revisar manualmente.', v_correo;
        ELSIF v_count_correo = 1 THEN
            SELECT id_persona INTO v_id_persona FROM persona WHERE correo = v_correo;
        END IF;
    END IF;

    IF v_id_persona IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM usuario WHERE id_persona = v_id_persona) THEN
            RAISE EXCEPTION 'Esta persona ya tiene un usuario';
        END IF;
    ELSE
        IF NULLIF(TRIM(p_primer_nombre), '') IS NULL OR NULLIF(TRIM(p_primer_apellido), '') IS NULL THEN
            RAISE EXCEPTION 'Primer nombre y primer apellido son obligatorios';
        END IF;
        INSERT INTO persona (primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cui, telefono, correo)
        VALUES (TRIM(p_primer_nombre), NULLIF(TRIM(p_segundo_nombre), ''), TRIM(p_primer_apellido), NULLIF(TRIM(p_segundo_apellido), ''), v_cui, v_telefono, v_correo)
        RETURNING id_persona INTO v_id_persona;
    END IF;

    -- Empleado: reutilizar si ya existe, crear si no
    SELECT id_empleado INTO v_id_empleado FROM empleado WHERE id_persona = v_id_persona ORDER BY id_empleado LIMIT 1;
    IF v_id_empleado IS NULL THEN
        INSERT INTO empleado (id_persona, id_tipo_empleado, activo, fecha_creacion)
        VALUES (v_id_persona, p_id_tipo_empleado, true, now());
    ELSE
        UPDATE empleado SET activo = true WHERE id_empleado = v_id_empleado;
    END IF;

    INSERT INTO usuario (id_persona, id_tipo_usuario, username, password_hash, confirmacion, id_rol_acceso, fecha_creacion)
    VALUES (v_id_persona, v_id_tipo_usuario, v_username, p_password_hash, true, p_id_rol_acceso, now())
    RETURNING id_usuario INTO p_id_usuario;
END;
$$;
