CREATE OR REPLACE PROCEDURE sp_registrar_acceso(p_id_usuario INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuario
    SET fecha_ultimo_acceso = now()
    WHERE id_usuario = p_id_usuario;
END;
$$;