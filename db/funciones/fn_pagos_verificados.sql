CREATE OR REPLACE FUNCTION fn_pagos_verificados() RETURNS TABLE(id_pago integer, id_evento integer, cliente text, fecha_evento date, fecha_pago date, monto numeric, tipo_pago character varying, concepto character varying, origen character varying, path_comprobante character varying, verifico text, fecha_registro timestamp with time zone)
    LANGUAGE sql STABLE
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
