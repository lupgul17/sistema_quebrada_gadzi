CREATE OR REPLACE FUNCTION fn_degustacion_detalle(p_id_degustacion INTEGER)
RETURNS TABLE (
    id_degustacion        INTEGER,
    id_evento             INTEGER,
    id_fecha_degustacion  INTEGER,
    fecha                 DATE,
    hora                  TIME,
    estado                VARCHAR,
    notas                 TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT d.id_degustacion, d.id_evento, d.id_fecha_degustacion, fd.fecha, fd.hora, d.estado, d.notas
    FROM degustacion d
    JOIN fechas_degustacion fd ON fd.id_fecha_degustacion = d.id_fecha_degustacion
    WHERE d.id_degustacion = p_id_degustacion;
$$;