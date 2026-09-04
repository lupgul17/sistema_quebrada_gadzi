CREATE OR REPLACE FUNCTION fn_listar_degustaciones_por_fecha(p_id_fecha_degustacion INTEGER)
RETURNS TABLE (
    id_degustacion  INTEGER,
    id_evento       INTEGER,
    cliente         TEXT,
    telefono        VARCHAR,
    tipo_evento     VARCHAR,
    fecha_evento    DATE,
    estado          VARCHAR,
    notas           TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        d.id_degustacion, d.id_evento,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        p.telefono,
        te.descripcion AS tipo_evento,
        e.fecha AS fecha_evento,
        d.estado, d.notas
    FROM degustacion d
    JOIN evento e ON e.id_evento = d.id_evento
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    WHERE d.id_fecha_degustacion = p_id_fecha_degustacion AND d.estado != 'cancelada'
    ORDER BY p.primer_apellido;
$$;