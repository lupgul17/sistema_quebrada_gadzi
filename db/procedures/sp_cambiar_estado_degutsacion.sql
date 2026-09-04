CREATE OR REPLACE PROCEDURE sp_cambiar_estado_degustacion(
    p_id_degustacion  INTEGER,
    p_nuevo_estado    VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM degustacion WHERE id_degustacion = p_id_degustacion) THEN
        RAISE EXCEPTION 'No existe una degustacion con id = %', p_id_degustacion;
    END IF;

    IF p_nuevo_estado NOT IN ('agendada', 'realizada', 'cancelada') THEN
        RAISE EXCEPTION 'Estado invalido: %', p_nuevo_estado;
    END IF;

    UPDATE degustacion
    SET estado = p_nuevo_estado
    WHERE id_degustacion = p_id_degustacion;
END;
$$;