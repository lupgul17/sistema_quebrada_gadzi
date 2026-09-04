CREATE OR REPLACE FUNCTION fn_pagos_pendientes_verificacion()
RETURNS TABLE (
    id_pago         INTEGER,
    id_evento       INTEGER,
    cliente         TEXT,
    fecha_evento    DATE,
    fecha_pago      DATE,
    monto           DECIMAL,
    tipo_pago       VARCHAR,
    concepto        VARCHAR,
    origen          VARCHAR,
    fecha_registro  TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        p.id_pago, p.id_evento,
        pc.primer_nombre || ' ' || pc.primer_apellido AS cliente,
        e.fecha AS fecha_evento,
        p.fecha_pago, p.monto, tp.descripcion AS tipo_pago, p.concepto, p.origen, p.fecha_registro
    FROM pago p
    JOIN evento e ON e.id_evento = p.id_evento
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona pc ON pc.id_persona = c.id_persona
    JOIN tc_tipo_pago tp ON tp.id_tipo_pago = p.id_tipo_pago
    WHERE p.estado = 'pendiente'
    ORDER BY p.fecha_registro;
$$;DROP FUNCTION fn_pagos_pendientes_verificacion();

CREATE OR REPLACE FUNCTION fn_pagos_pendientes_verificacion()
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
        p.path_comprobante, p.fecha_registro
    FROM pago p
    JOIN evento e ON e.id_evento = p.id_evento
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona pc ON pc.id_persona = c.id_persona
    JOIN tc_tipo_pago tp ON tp.id_tipo_pago = p.id_tipo_pago
    WHERE p.estado = 'pendiente'
    ORDER BY p.fecha_registro;
$$;

