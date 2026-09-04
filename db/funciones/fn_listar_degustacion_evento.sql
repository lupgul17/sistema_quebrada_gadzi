CREATE OR REPLACE FUNCTION fn_listar_degustaciones_evento(p_id_evento INTEGER)
RETURNS TABLE (
    id_degustacion        INTEGER,
    id_fecha_degustacion  INTEGER,
    fecha                 DATE,
    hora                  TIME,
    estado                VARCHAR,
    notas                 TEXT,
    fecha_creacion        TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        d.id_degustacion, d.id_fecha_degustacion, fd.fecha, fd.hora, d.estado, d.notas, d.fecha_creacion
    FROM degustacion d
    JOIN fechas_degustacion fd ON fd.id_fecha_degustacion = d.id_fecha_degustacion
    WHERE d.id_evento = p_id_evento
    ORDER BY fd.fecha DESC;
$$;