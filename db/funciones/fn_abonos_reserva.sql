CREATE OR REPLACE FUNCTION fn_abonos_reserva(p_id_evento INTEGER)
RETURNS NUMERIC
LANGUAGE sql STABLE
AS $$
    SELECT COALESCE(SUM(monto), 0) FROM pago
    WHERE id_evento = p_id_evento AND concepto = 'reserva' AND estado <> 'rechazado';
$$;
