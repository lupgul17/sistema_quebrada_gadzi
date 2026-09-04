CREATE OR REPLACE PROCEDURE sp_crear_fecha_degustacion(
    p_fecha                    DATE,
    p_hora                     TIME,
    OUT p_id_fecha_degustacion INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO fechas_degustacion (fecha, hora, estado)
    VALUES (p_fecha, p_hora, 'disponible')
    RETURNING id_fecha_degustacion INTO p_id_fecha_degustacion;
END;
$$;