CREATE OR REPLACE PROCEDURE sp_agendar_degustacion(IN p_id_evento integer, IN p_id_fecha_degustacion integer, IN p_hora_llegada time without time zone, IN p_notas text, OUT p_id_degustacion integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO degustacion (id_evento, id_fecha_degustacion, hora_llegada, estado, notas)
    VALUES (p_id_evento, p_id_fecha_degustacion, p_hora_llegada, 'agendada', p_notas)
    RETURNING id_degustacion INTO p_id_degustacion;
END;
$$;
