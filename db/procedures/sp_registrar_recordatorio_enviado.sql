CREATE OR REPLACE PROCEDURE sp_registrar_recordatorio_enviado(IN p_id_evento integer, IN p_id_tipo_recordatorio integer, IN p_correo_destino character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO recordatorio_enviado (id_evento, id_tipo_recordatorio, correo_destino, fecha_envio)
    VALUES (p_id_evento, p_id_tipo_recordatorio, p_correo_destino, now());
END;
$$;
