CREATE OR REPLACE PROCEDURE sp_cambiar_estado_fecha_degustacion(
    p_id_fecha_degustacion  INTEGER,
    p_nuevo_estado          VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM fechas_degustacion WHERE id_fecha_degustacion = p_id_fecha_degustacion) THEN
        RAISE EXCEPTION 'No existe una fecha de degustacion con id = %', p_id_fecha_degustacion;
    END IF;

    IF p_nuevo_estado NOT IN ('disponible', 'llena', 'cancelada') THEN
        RAISE EXCEPTION 'Estado invalido: %', p_nuevo_estado;
    END IF;

    UPDATE fechas_degustacion
    SET estado = p_nuevo_estado
    WHERE id_fecha_degustacion = p_id_fecha_degustacion;
END;
$$;