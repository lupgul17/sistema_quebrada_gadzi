CREATE OR REPLACE FUNCTION fn_listar_pagos_cliente(p_id_cliente INTEGER)
RETURNS TABLE (
    id_pago       INTEGER,
    id_evento     INTEGER,
    fecha_evento  DATE,
    fecha_pago    DATE,
    monto         DECIMAL,
    tipo_pago     VARCHAR,
    concepto      VARCHAR,
    estado        VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        p.id_pago, p.id_evento, e.fecha AS fecha_evento, p.fecha_pago, p.monto, tp.descripcion AS tipo_pago, p.concepto, p.estado
    FROM pago p
    JOIN evento e ON e.id_evento = p.id_evento
    JOIN tc_tipo_pago tp ON tp.id_tipo_pago = p.id_tipo_pago
    WHERE e.id_cliente = p_id_cliente
    ORDER BY p.fecha_pago DESC;
$$;