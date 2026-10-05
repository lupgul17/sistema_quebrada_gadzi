CREATE OR REPLACE PROCEDURE sp_crear_prospecto(
    p_nombre           VARCHAR,
    p_telefono         VARCHAR,
    p_correo           VARCHAR,
    p_id_tipo_evento   INTEGER,
    p_id_salon         INTEGER,
    p_fecha_tentativa  DATE,
    p_invitados        INTEGER,
    p_mensaje          TEXT,
    p_ip_origen        VARCHAR,
    OUT p_id_prospecto INTEGER
)
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
