CREATE OR REPLACE PROCEDURE sp_editar_datos_usuario(IN p_id_usuario integer, IN p_primer_nombre character varying, IN p_segundo_nombre character varying, IN p_primer_apellido character varying, IN p_segundo_apellido character varying, IN p_cui character varying, IN p_telefono character varying, IN p_correo character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_persona INTEGER;
BEGIN
    SELECT id_persona INTO v_id_persona FROM usuario WHERE id_usuario = p_id_usuario;

    IF v_id_persona IS NULL THEN
        RAISE EXCEPTION 'No existe el usuario con id = %', p_id_usuario;
    END IF;
    IF NULLIF(TRIM(p_primer_nombre), '') IS NULL OR NULLIF(TRIM(p_primer_apellido), '') IS NULL THEN
        RAISE EXCEPTION 'Primer nombre y primer apellido son obligatorios';
    END IF;

    -- El NIT no se toca: si la persona también es cliente, su NIT se queda como está
    UPDATE persona
    SET
        primer_nombre = TRIM(p_primer_nombre),
        segundo_nombre = NULLIF(TRIM(p_segundo_nombre), ''),
        primer_apellido = TRIM(p_primer_apellido),
        segundo_apellido = NULLIF(TRIM(p_segundo_apellido), ''),
        cui = NULLIF(TRIM(p_cui), ''),
        telefono = NULLIF(TRIM(p_telefono), ''),
        correo = NULLIF(TRIM(p_correo), '')
    WHERE id_persona = v_id_persona;
END;
$$;
