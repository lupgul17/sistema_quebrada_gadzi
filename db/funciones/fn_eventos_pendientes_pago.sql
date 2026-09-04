CREATE OR REPLACE FUNCTION fn_eventos_pendientes_pago()
RETURNS TABLE (
    id_evento          INTEGER,
    fecha              DATE,
    cliente            TEXT,
    saldo_pendiente    DECIMAL,
    total_a_pagar      DECIMAL,
    porcentaje_pagado  DECIMAL
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        e.id_evento, e.fecha,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        vs.saldo_pendiente, vs.total_a_pagar, vs.porcentaje_pagado
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    JOIN v_evento_saldo vs ON vs.id_evento = e.id_evento
    WHERE vs.saldo_pendiente > 0 AND e.estado != 'cancelado'
    ORDER BY e.fecha;
$$;