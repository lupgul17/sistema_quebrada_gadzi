CREATE OR REPLACE FUNCTION fn_listar_eventos(
    p_estado VARCHAR DEFAULT NULL,
    p_fecha_desde DATE DEFAULT NULL,
    p_fecha_hasta DATE DEFAULT NULL,
    p_id_cliente INTEGER DEFAULT NULL
)
RETURNS TABLE (
    id_evento       INTEGER,
    fecha           DATE,
    hora_inicio     TIME,
    hora_fin        TIME,
    estado          VARCHAR,
    tipo_evento     VARCHAR,
    total_adultos   INTEGER,
    total_menores   INTEGER,
    cliente         TEXT,
    salones         TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        e.id_evento,
        e.fecha,
        e.hora_inicio,
        e.hora_fin,
        e.estado,
        te.descripcion AS tipo_evento,
        e.total_adultos,
        e.total_menores,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        STRING_AGG(s.nombre, ', ' ORDER BY s.nombre) AS salones
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    LEFT JOIN evento_salon es ON es.id_evento = e.id_evento
    LEFT JOIN salon s ON s.id_salon = es.id_salon
    WHERE
        (p_estado IS NULL OR e.estado = p_estado)
        AND (p_fecha_desde IS NULL OR e.fecha >= p_fecha_desde)
        AND (p_fecha_hasta IS NULL OR e.fecha <= p_fecha_hasta)
        AND (p_id_cliente IS NULL OR e.id_cliente = p_id_cliente)
    GROUP BY e.id_evento, e.fecha, e.hora_inicio, e.hora_fin, e.estado, te.descripcion, e.total_adultos, e.total_menores, p.primer_nombre, p.primer_apellido
    ORDER BY e.fecha DESC, e.hora_inicio;
$$;