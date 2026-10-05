CREATE OR REPLACE FUNCTION fn_saldo_evento(p_id_evento integer) RETURNS TABLE(id_evento integer, total_a_pagar numeric, total_pagado numeric, saldo_pendiente numeric, porcentaje_pagado numeric)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_evento, total_a_pagar, total_pagado, saldo_pendiente, porcentaje_pagado
    FROM v_evento_saldo
    WHERE id_evento = p_id_evento;
$$;
