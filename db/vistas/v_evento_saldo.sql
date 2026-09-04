CREATE OR REPLACE VIEW v_evento_saldo AS
SELECT
    e.id_evento,
    COALESCE(c.total, 0) AS total_a_pagar,
    COALESCE(pg.total_pagado, 0) AS total_pagado,
    COALESCE(c.total, 0) - COALESCE(pg.total_pagado, 0) AS saldo_pendiente,
    CASE WHEN COALESCE(c.total, 0) > 0
        THEN ROUND(COALESCE(pg.total_pagado, 0) / c.total * 100, 2)
        ELSE 0
    END AS porcentaje_pagado
FROM evento e
LEFT JOIN cotizacion c ON c.id_evento = e.id_evento AND c.activa = true
LEFT JOIN (
    SELECT id_evento, SUM(monto) AS total_pagado
    FROM pago
    WHERE estado = 'verificado'
    GROUP BY id_evento
) pg ON pg.id_evento = e.id_evento;