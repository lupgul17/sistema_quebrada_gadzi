DROP FUNCTION fn_listar_pagos_evento(integer);

CREATE OR REPLACE FUNCTION fn_listar_pagos_evento(p_id_evento INTEGER)
RETURNS TABLE (
    id_pago           INTEGER,
    fecha_pago        DATE,
    monto             DECIMAL,
    tipo_pago         VARCHAR,
    concepto          VARCHAR,
    estado            VARCHAR,
    origen            VARCHAR,
    empleado          TEXT,
    path_comprobante  VARCHAR,
    motivo_rechazo    TEXT,
    notas             TEXT,
    fecha_registro    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        p.id_pago, p.fecha_pago, p.monto, tp.descripcion AS tipo_pago, p.concepto, p.estado, p.origen,
        pe.primer_nombre || ' ' || pe.primer_apellido AS empleado,
        p.path_comprobante, p.motivo_rechazo, p.notas, p.fecha_registro
    FROM pago p
    JOIN tc_tipo_pago tp ON tp.id_tipo_pago = p.id_tipo_pago
    LEFT JOIN empleado e ON e.id_empleado = p.id_empleado
    LEFT JOIN persona pe ON pe.id_persona = e.id_persona
    WHERE p.id_evento = p_id_evento
    ORDER BY p.fecha_pago DESC, p.fecha_registro DESC;
$$;