CREATE OR REPLACE PROCEDURE sp_crear_evento(IN p_id_cliente integer, IN p_id_tipo_evento integer, IN p_fecha date, IN p_hora_inicio time without time zone, IN p_hora_fin time without time zone, IN p_total_adultos integer, IN p_total_menores integer, IN p_notas text, IN p_reserva_temporal boolean, IN p_salones integer[], OUT p_id_evento integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_salon INTEGER;
BEGIN
    -- Validar disponibilidad de todos los salones ANTES de insertar nada
    FOREACH v_id_salon IN ARRAY p_salones
    LOOP
        IF NOT fn_validar_disponibilidad_salon(v_id_salon, p_fecha, p_hora_inicio, p_hora_fin) THEN
            RAISE EXCEPTION 'El salón % no está disponible en esa fecha y horario', v_id_salon;
        END IF;
    END LOOP;

    INSERT INTO evento (
        id_cliente, id_tipo_evento, fecha, hora_inicio, hora_fin,
        total_adultos, total_menores, notas, reserva_temporal, estado
    )
    VALUES (
        p_id_cliente, p_id_tipo_evento, p_fecha, p_hora_inicio, p_hora_fin,
        p_total_adultos, p_total_menores, p_notas, p_reserva_temporal, 'cotizacion'
    )
    RETURNING id_evento INTO p_id_evento;

    FOREACH v_id_salon IN ARRAY p_salones
    LOOP
        INSERT INTO evento_salon (id_evento, id_salon)
        VALUES (p_id_evento, v_id_salon);
    END LOOP;
END;
$$;
