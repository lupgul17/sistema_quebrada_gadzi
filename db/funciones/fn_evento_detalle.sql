CREATE OR REPLACE FUNCTION fn_evento_detalle(p_id_evento INTEGER)
RETURNS TABLE (
    id_evento         INTEGER,
    fecha             DATE,
    hora_inicio       TIME,
    hora_fin          TIME,
    estado            VARCHAR,
    reserva_temporal  BOOLEAN,
    total_adultos     INTEGER,
    total_menores     INTEGER,
    notas             TEXT,
    id_cliente        INTEGER,
    cliente           TEXT,
    telefono_cliente  VARCHAR,
    id_tipo_evento    INTEGER,
    tipo_evento       VARCHAR,
    salones           TEXT,
    salones_ids       INTEGER[],
    fecha_creacion    TIMESTAMPTZ
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
        e.reserva_temporal,
        e.total_adultos,
        e.total_menores,
        e.notas,
        c.id_cliente,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        p.telefono AS telefono_cliente,
        te.id_tipo_evento,
        te.descripcion AS tipo_evento,
        STRING_AGG(s.nombre, ', ' ORDER BY s.nombre) AS salones,
        ARRAY_AGG(s.id_salon ORDER BY s.nombre) AS salones_ids,
        e.fecha_creacion
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    LEFT JOIN evento_salon es ON es.id_evento = e.id_evento
    LEFT JOIN salon s ON s.id_salon = es.id_salon
    WHERE e.id_evento = p_id_evento
    GROUP BY e.id_evento, c.id_cliente, p.primer_nombre, p.primer_apellido, p.telefono, te.id_tipo_evento, te.descripcion;
$$;