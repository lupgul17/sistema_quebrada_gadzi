CREATE OR REPLACE PROCEDURE sp_cambiar_estado_evento(
    p_id_evento     INTEGER,
    p_nuevo_estado  VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_actual VARCHAR;
BEGIN
    SELECT estado INTO v_estado_actual FROM evento WHERE id_evento = p_id_evento;

    IF v_estado_actual IS NULL THEN
        RAISE EXCEPTION 'No existe un evento con id_evento = %', p_id_evento;
    END IF;

    IF p_nuevo_estado NOT IN ('cotizacion', 'confirmado', 'en_curso', 'cerrado', 'cancelado') THEN
        RAISE EXCEPTION 'Estado inválido: %', p_nuevo_estado;
    END IF;

    -- Transiciones válidas: solo hacia adelante en el ciclo normal, o a cancelado desde cualquier estado activo
    IF NOT (
        (v_estado_actual = 'cotizacion' AND p_nuevo_estado IN ('confirmado', 'cancelado'))
        OR (v_estado_actual = 'confirmado' AND p_nuevo_estado IN ('en_curso', 'cancelado'))
        OR (v_estado_actual = 'en_curso' AND p_nuevo_estado = 'cerrado')
    ) THEN
        RAISE EXCEPTION 'No se puede pasar de % a %', v_estado_actual, p_nuevo_estado;
    END IF;

    UPDATE evento SET estado = p_nuevo_estado WHERE id_evento = p_id_evento;
END;
$$;