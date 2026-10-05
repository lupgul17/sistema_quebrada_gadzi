CREATE OR REPLACE PROCEDURE sp_crear_prospecto(IN p_nombre character varying, IN p_telefono character varying, IN p_correo character varying, IN p_id_tipo_evento integer, IN p_id_salon integer, IN p_fecha_tentativa date, IN p_invitados integer, IN p_mensaje text, IN p_ip_origen character varying, OUT p_id_prospecto integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        RAISE EXCEPTION 'Falta el nombre';
    END IF;
    IF p_telefono IS NULL OR TRIM(p_telefono) = '' THEN
        RAISE EXCEPTION 'Falta el teléfono';
    END IF;
    IF p_fecha_tentativa IS NOT NULL AND p_fecha_tentativa < CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha tentativa no puede estar en el pasado';
    END IF;

    INSERT INTO prospecto (
        nombre, telefono, correo, id_tipo_evento, id_salon,
        fecha_tentativa, invitados, mensaje, ip_origen
    )
    VALUES (
        TRIM(p_nombre), TRIM(p_telefono), NULLIF(TRIM(p_correo), ''), p_id_tipo_evento, p_id_salon,
        p_fecha_tentativa, p_invitados, NULLIF(TRIM(p_mensaje), ''), p_ip_origen
    )
    RETURNING id_prospecto INTO p_id_prospecto;
END;
$$;
