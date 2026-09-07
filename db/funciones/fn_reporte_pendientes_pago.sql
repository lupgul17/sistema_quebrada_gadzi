CREATE OR REPLACE FUNCTION fn_reporte_pendientes_pago()
RETURNS TABLE (
    id_evento          INTEGER,
    fecha              DATE,
    dias_para_evento   INTEGER,
    cliente            TEXT,
    total_a_pagar      DECIMAL,
    total_pagado       DECIMAL,
    saldo_pendiente    DECIMAL,
    porcentaje_pagado  DECIMAL,
    checkpoint         VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        e.id_evento, e.fecha,
        (e.fecha - CURRENT_DATE) AS dias_para_evento,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        vs.total_a_pagar, vs.total_pagado, vs.saldo_pendiente, vs.porcentaje_pagado,
        CASE WHEN vs.porcentaje_pagado < 0.5 THEN '50%' ELSE '100%' END AS checkpoint
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    JOIN v_evento_saldo vs ON vs.id_evento = e.id_evento
    WHERE e.estado = 'confirmado' AND vs.porcentaje_pagado < 1
    ORDER BY e.fecha;
$$;