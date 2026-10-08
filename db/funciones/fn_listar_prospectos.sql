CREATE OR REPLACE FUNCTION fn_listar_prospectos(p_estado character varying DEFAULT NULL::character varying)
RETURNS TABLE(id_prospecto integer, nombre character varying, telefono character varying, correo character varying,
              id_tipo_evento integer, tipo_evento character varying, id_salon integer, salon character varying,
              locacion character varying, fecha_tentativa date, invitados integer, adultos integer, ninos integer,
              mensaje text, estado character varying, notas_internas text, id_cliente integer, id_evento integer,
              fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        p.id_prospecto, p.nombre, p.telefono, p.correo,
        p.id_tipo_evento, te.descripcion AS tipo_evento,
        p.id_salon, s.nombre AS salon, l.nombre AS locacion,
        p.fecha_tentativa, p.invitados, p.adultos, p.ninos, p.mensaje, p.estado, p.notas_internas,
        p.id_cliente, p.id_evento, p.fecha_creacion
    FROM prospecto p
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = p.id_tipo_evento
    LEFT JOIN salon s ON s.id_salon = p.id_salon
    LEFT JOIN locacion l ON l.id_locacion = s.id_locacion
    WHERE p_estado IS NULL OR p.estado = p_estado
    ORDER BY (p.estado = 'nuevo') DESC, p.fecha_creacion DESC;
$$;
