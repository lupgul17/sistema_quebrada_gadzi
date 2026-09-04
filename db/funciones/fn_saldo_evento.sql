CREATE OR REPLACE FUNCTION fn_saldo_evento(p_id_evento INTEGER)
RETURNS TABLE (
    id_evento          INTEGER,
    total_a_pagar       DECIMAL,
    total_pagado         DECIMAL,
    saldo_pendiente       DECIMAL,
    porcentaje_pagado     DECIMAL
)
LANGUAGE sql
STABLE
AS $$
    SELECT id_evento, total_a_pagar, total_pagado, saldo_pendiente, porcentaje_pagado
    FROM v_evento_saldo
    WHERE id_evento = p_id_evento;
$$;