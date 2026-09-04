CREATE OR REPLACE PROCEDURE sp_editar_evento(
    p_id_evento         INTEGER,
    p_id_tipo_evento    INTEGER,
    p_fecha             DATE,
    p_hora_inicio       TIME,
    p_hora_fin          TIME,
    p_total_adultos     INTEGER,
    p_total_menores     INTEGER,
    p_notas             TEXT,
    p_reserva_temporal  BOOLEAN,
    p_salones           INTEGER[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_salon INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM evento WHERE id_evento = p_id_evento) THEN
        RAISE EXCEPTION 'No existe un evento con id_evento = %', p_id_evento;
    END IF;

    -- Validar disponibilidad, excluyendo este mismo evento (para no chocar contra sí mismo)
    FOREACH v_id_salon IN ARRAY p_salones
    LOOP
        IF NOT fn_validar_disponibilidad_salon(v_id_salon, p_fecha, p_hora_inicio, p_hora_fin, p_id_evento) THEN
            RAISE EXCEPTION 'El salón % no está disponible en esa fecha y horario', v_id_salon;
        END IF;
    END LOOP;

    UPDATE evento
    SET
        id_tipo_evento = p_id_tipo_evento,
        fecha = p_fecha,
        hora_inicio = p_hora_inicio,
        hora_fin = p_hora_fin,
        total_adultos = p_total_adultos,
        total_menores = p_total_menores,
        notas = p_notas,
        reserva_temporal = p_reserva_temporal
    WHERE id_evento = p_id_evento;

    DELETE FROM evento_salon WHERE id_evento = p_id_evento;

    FOREACH v_id_salon IN ARRAY p_salones
    LOOP
        INSERT INTO evento_salon (id_evento, id_salon)
        VALUES (p_id_evento, v_id_salon);
    END LOOP;
END;
$$;