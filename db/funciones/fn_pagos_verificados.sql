

DROP FUNCTION fn_pagos_verificados();

CREATE OR REPLACE FUNCTION fn_pagos_verificados()
RETURNS TABLE (
    id_pago           INTEGER,
    id_evento         INTEGER,
    cliente           TEXT,
    fecha_evento      DATE,
    fecha_pago        DATE,
    monto             DECIMAL,
    tipo_pago         VARCHAR,
    concepto          VARCHAR,
    origen            VARCHAR,
    path_comprobante  VARCHAR,
    verifico          TEXT,
    fecha_registro    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        p.id_pago, p.id_evento,
        pc.primer_nombre || ' ' || pc.primer_apellido AS cliente,
        e.fecha AS fecha_evento,
        p.fecha_pago, p.monto, tp.descripcion AS tipo_pago, p.concepto, p.origen,
        p.path_comprobante,
        pv.primer_nombre || ' ' || pv.primer_apellido AS verifico,
        p.fecha_registro
    FROM pago p
    JOIN evento e ON e.id_evento = p.id_evento
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona pc ON pc.id_persona = c.id_persona
    JOIN tc_tipo_pago tp ON tp.id_tipo_pago = p.id_tipo_pago
    LEFT JOIN empleado ev ON ev.id_empleado = p.id_empleado
    LEFT JOIN persona pv ON pv.id_persona = ev.id_persona
    WHERE p.estado = 'verificado'
    ORDER BY p.fecha_pago DESC;
$$;