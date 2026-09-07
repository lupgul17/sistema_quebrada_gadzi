CREATE OR REPLACE PROCEDURE sp_registrar_recordatorio_enviado(
    p_id_evento             INTEGER,
    p_id_tipo_recordatorio  INTEGER,
    p_correo_destino        VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO recordatorio_enviado (id_evento, id_tipo_recordatorio, correo_destino, fecha_envio)
    VALUES (p_id_evento, p_id_tipo_recordatorio, p_correo_destino, now());
END;
$$;