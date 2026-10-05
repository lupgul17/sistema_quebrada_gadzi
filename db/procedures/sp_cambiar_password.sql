CREATE OR REPLACE PROCEDURE sp_cambiar_password(IN p_id_usuario integer, IN p_password_hash character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario) THEN
        RAISE EXCEPTION 'No existe el usuario con id = %', p_id_usuario;
    END IF;
    UPDATE usuario SET password_hash = p_password_hash WHERE id_usuario = p_id_usuario;
END;
$$;
