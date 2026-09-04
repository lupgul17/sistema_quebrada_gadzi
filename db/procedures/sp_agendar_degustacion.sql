CREATE OR REPLACE PROCEDURE sp_agendar_degustacion(
    p_id_evento             INTEGER,
    p_id_fecha_degustacion  INTEGER,
    p_notas                 TEXT,
    OUT p_id_degustacion    INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO degustacion (id_evento, id_fecha_degustacion, estado, notas)
    VALUES (p_id_evento, p_id_fecha_degustacion, 'agendada', p_notas)
    RETURNING id_degustacion INTO p_id_degustacion;
END;
$$;