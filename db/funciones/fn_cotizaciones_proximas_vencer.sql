CREATE OR REPLACE FUNCTION fn_cotizaciones_proximas_vencer(p_dias_anticipacion INTEGER DEFAULT 3)
RETURNS TABLE (
    id_cotizacion      INTEGER,
    id_evento          INTEGER,
    cliente            TEXT,
    fecha_vencimiento  DATE,
    dias_restantes     INTEGER,
    total              DECIMAL
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        c.id_cotizacion, c.id_evento,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        (c.fecha_cotizacion + c.vigencia_dias) AS fecha_vencimiento,
        (c.fecha_cotizacion + c.vigencia_dias) - CURRENT_DATE AS dias_restantes,
        c.total
    FROM cotizacion c
    JOIN evento e ON e.id_evento = c.id_evento
    JOIN cliente cl ON cl.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = cl.id_persona
    WHERE c.activa = true
      AND c.id_estado_cotizacion IN (SELECT id_estado_cotizacion FROM tc_estado_cotizacion WHERE descripcion IN ('estimada', 'enviada'))
      AND (c.fecha_cotizacion + c.vigencia_dias) BETWEEN CURRENT_DATE AND CURRENT_DATE + p_dias_anticipacion
    ORDER BY fecha_vencimiento;
$$;