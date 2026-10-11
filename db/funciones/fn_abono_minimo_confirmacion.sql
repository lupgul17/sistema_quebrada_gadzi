CREATE OR REPLACE FUNCTION fn_abono_minimo_confirmacion(p_id_evento INTEGER)
RETURNS NUMERIC
LANGUAGE sql STABLE
AS $$
    SELECT CASE
        WHEN c.total IS NOT NULL AND c.total > 0 THEN LEAST(10000, c.total)
        ELSE 10000
    END
    FROM (SELECT 1) x
    LEFT JOIN cotizacion c ON c.id_evento = p_id_evento AND c.activa = true;
$$;
