CREATE OR REPLACE FUNCTION fn_reporte_degustaciones_detallado(p_fecha_desde DATE, p_fecha_hasta DATE)
RETURNS TABLE (
    fecha_sesion  DATE,
    hora_inicio   TIME,
    cliente       TEXT,
    telefono      VARCHAR,
    tipo_evento   VARCHAR,
    menus         TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        fd.fecha AS fecha_sesion,
        fd.hora_inicio,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        p.telefono,
        te.descripcion AS tipo_evento,
        COALESCE(STRING_AGG(m.nombre, ', ' ORDER BY m.nombre), 'Sin menús seleccionados') AS menus
    FROM degustacion d
    JOIN fechas_degustacion fd ON fd.id_fecha_degustacion = d.id_fecha_degustacion
    JOIN evento e ON e.id_evento = d.id_evento
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    LEFT JOIN degustacion_menu dm ON dm.id_degustacion = d.id_degustacion
    LEFT JOIN menu m ON m.id_menu = dm.id_menu
    WHERE d.estado != 'cancelada'
      AND fd.fecha BETWEEN p_fecha_desde AND p_fecha_hasta
    GROUP BY fd.fecha, fd.hora_inicio, p.primer_nombre, p.primer_apellido, p.telefono, te.descripcion, d.id_degustacion
    ORDER BY fd.fecha, fd.hora_inicio, p.primer_apellido;
$$;