CREATE OR REPLACE FUNCTION fn_cotizaciones_proximas_vencer(p_dias_anticipacion integer DEFAULT 3) RETURNS TABLE(id_cotizacion integer, id_evento integer, cliente text, fecha_vencimiento date, dias_restantes integer, total numeric)
    LANGUAGE sql STABLE
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
      AND e.estado = 'cotizacion'
      AND e.reserva_temporal = true
      AND (c.fecha_cotizacion + c.vigencia_dias) BETWEEN CURRENT_DATE AND CURRENT_DATE + p_dias_anticipacion
    ORDER BY fecha_vencimiento;
$$;
