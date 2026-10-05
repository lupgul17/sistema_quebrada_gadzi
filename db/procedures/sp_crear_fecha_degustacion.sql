CREATE OR REPLACE PROCEDURE sp_crear_fecha_degustacion(IN p_fecha date, IN p_hora_inicio time without time zone, IN p_hora_fin time without time zone, OUT p_id_fecha_degustacion integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO fechas_degustacion (fecha, hora_inicio, hora_fin, estado)
    VALUES (p_fecha, p_hora_inicio, p_hora_fin, 'disponible')
    RETURNING id_fecha_degustacion INTO p_id_fecha_degustacion;
END;
$$;
