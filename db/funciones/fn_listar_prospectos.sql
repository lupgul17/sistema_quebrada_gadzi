CREATE OR REPLACE FUNCTION fn_listar_prospectos(
    p_estado VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id_prospecto     INTEGER,
    nombre           VARCHAR,
    telefono         VARCHAR,
    correo           VARCHAR,
    id_tipo_evento   INTEGER,
    tipo_evento      VARCHAR,
    id_salon         INTEGER,
    salon            VARCHAR,
    locacion         VARCHAR,
    fecha_tentativa  DATE,
    invitados        INTEGER,
    mensaje          TEXT,
    estado           VARCHAR,
    notas_internas   TEXT,
    id_cliente       INTEGER,
    id_evento        INTEGER,
    fecha_creacion   TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        p.id_prospecto, p.nombre, p.telefono, p.correo,
        p.id_tipo_evento, te.descripcion AS tipo_evento,
        p.id_salon, s.nombre AS salon, l.nombre AS locacion,
        p.fecha_tentativa, p.invitados, p.mensaje, p.estado, p.notas_internas,
        p.id_cliente, p.id_evento, p.fecha_creacion
    FROM prospecto p
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = p.id_tipo_evento
    LEFT JOIN salon s ON s.id_salon = p.id_salon
    LEFT JOIN locacion l ON l.id_locacion = s.id_locacion
    WHERE p_estado IS NULL OR p.estado = p_estado
    ORDER BY (p.estado = 'nuevo') DESC, p.fecha_creacion DESC;
$$;
