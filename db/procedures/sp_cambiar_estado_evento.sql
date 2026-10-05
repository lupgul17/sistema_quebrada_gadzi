CREATE OR REPLACE PROCEDURE sp_cambiar_estado_evento(IN p_id_evento integer, IN p_nuevo_estado character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_actual VARCHAR;
    v_fecha         DATE;
    v_hora_inicio   TIME;
    v_hora_fin      TIME;
    r_salon         RECORD;
BEGIN
    SELECT estado, fecha, hora_inicio, hora_fin
    INTO v_estado_actual, v_fecha, v_hora_inicio, v_hora_fin
    FROM evento WHERE id_evento = p_id_evento;

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

    -- Al confirmar, la disponibilidad se revalida: desde que se cotizó, otro evento pudo quedar
    -- confirmado en el mismo salon y horario, o tomar la fecha tras vencer una reserva temporal.
    IF p_nuevo_estado = 'confirmado' THEN
        FOR r_salon IN
            SELECT s.id_salon, s.nombre
            FROM evento_salon es
            JOIN salon s ON s.id_salon = es.id_salon
            WHERE es.id_evento = p_id_evento
            ORDER BY s.id_salon
        LOOP
            -- Un candado por salon y fecha: si dos personas confirman a la vez, la segunda espera
            -- a que termine la primera y recien ahi valida (si no, las dos podrian pasar).
            -- Se toman en orden de salon para que nunca se bloqueen entre si.
            PERFORM pg_advisory_xact_lock(r_salon.id_salon, (v_fecha - DATE '2000-01-01'));

            IF NOT fn_validar_disponibilidad_salon(r_salon.id_salon, v_fecha, v_hora_inicio, v_hora_fin, p_id_evento) THEN
                RAISE EXCEPTION 'No se puede confirmar: el salón "%" ya está ocupado el % de % a % (otro evento confirmado o una reserva temporal vigente). Revisá el calendario.',
                    r_salon.nombre, to_char(v_fecha, 'DD/MM/YYYY'), to_char(v_hora_inicio, 'HH24:MI'), to_char(v_hora_fin, 'HH24:MI');
            END IF;
        END LOOP;
    END IF;

    UPDATE evento SET estado = p_nuevo_estado WHERE id_evento = p_id_evento;
END;
$$;
