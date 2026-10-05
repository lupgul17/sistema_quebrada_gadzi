CREATE OR REPLACE FUNCTION fn_listar_cotizaciones_evento(p_id_evento integer) RETURNS TABLE(id_cotizacion integer, version integer, fecha_cotizacion date, vigencia_dias integer, activa boolean, estado character varying, total numeric, vendedor text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        c.id_cotizacion, c.version, c.fecha_cotizacion, c.vigencia_dias, c.activa,
        ec.descripcion AS estado,
        vc.total,
        p.primer_nombre || ' ' || p.primer_apellido AS vendedor
    FROM cotizacion c
    JOIN tc_estado_cotizacion ec ON ec.id_estado_cotizacion = c.id_estado_cotizacion
    JOIN v_cotizacion_calculada vc ON vc.id_cotizacion = c.id_cotizacion
    LEFT JOIN empleado e ON e.id_empleado = c.id_empleado
    LEFT JOIN persona p ON p.id_persona = e.id_persona
    WHERE c.id_evento = p_id_evento
    ORDER BY c.version DESC;
$$;
