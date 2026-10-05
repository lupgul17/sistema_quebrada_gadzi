CREATE OR REPLACE PROCEDURE sp_editar_evento(IN p_id_evento integer, IN p_id_tipo_evento integer, IN p_fecha date, IN p_hora_inicio time without time zone, IN p_hora_fin time without time zone, IN p_total_adultos integer, IN p_total_menores integer, IN p_notas text, IN p_reserva_temporal boolean, IN p_salones integer[])
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
