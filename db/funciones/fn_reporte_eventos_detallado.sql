CREATE OR REPLACE FUNCTION fn_reporte_eventos_detallado(p_fecha_desde date, p_fecha_hasta date) RETURNS TABLE(id_evento integer, fecha date, cliente text, tipo_evento character varying, salones text, estado character varying, total_adultos integer, total_menores integer, total_a_pagar numeric, total_pagado numeric, saldo_pendiente numeric, porcentaje_pagado numeric, tiene_degustacion boolean, total_extras numeric)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        e.id_evento, e.fecha,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        te.descripcion AS tipo_evento,
        STRING_AGG(DISTINCT s.nombre, ', ' ORDER BY s.nombre) AS salones,
        e.estado, e.total_adultos, e.total_menores,
        COALESCE(vs.total_a_pagar, 0) AS total_a_pagar,
        COALESCE(vs.total_pagado, 0) AS total_pagado,
        COALESCE(vs.saldo_pendiente, 0) AS saldo_pendiente,
        COALESCE(vs.porcentaje_pagado, 0) AS porcentaje_pagado,
        EXISTS(SELECT 1 FROM degustacion d WHERE d.id_evento = e.id_evento AND d.estado != 'cancelada') AS tiene_degustacion,
        COALESCE(ex.total, 0) AS total_extras
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    LEFT JOIN evento_salon es ON es.id_evento = e.id_evento
    LEFT JOIN salon s ON s.id_salon = es.id_salon
    LEFT JOIN v_evento_saldo vs ON vs.id_evento = e.id_evento
    LEFT JOIN extras ex ON ex.id_evento = e.id_evento
    WHERE e.fecha BETWEEN p_fecha_desde AND p_fecha_hasta
    GROUP BY e.id_evento, p.primer_nombre, p.primer_apellido, te.descripcion, e.estado, e.total_adultos, e.total_menores,
             vs.total_a_pagar, vs.total_pagado, vs.saldo_pendiente, vs.porcentaje_pagado, ex.total
    ORDER BY e.fecha;
$$;
