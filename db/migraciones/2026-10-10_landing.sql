-- =====================================================================================
-- Landing pública conectada al sistema
--   1. Las solicitudes guardan adultos y niños por separado (invitados queda como la suma,
--      para no romper lo que ya lo usa). Al convertir la solicitud en evento ya van separados.
--   2. Las fechas ocupadas dicen si la reserva es temporal (por confirmarse) o firme.
--
-- Correr TODO este archivo de una vez en el SQL Editor de Neon (va en una transacción).
-- =====================================================================================
BEGIN;

-- ---------- 1. Adultos y niños en las solicitudes ----------
ALTER TABLE prospecto ADD COLUMN IF NOT EXISTS adultos INTEGER CHECK (adultos IS NULL OR adultos >= 0);
ALTER TABLE prospecto ADD COLUMN IF NOT EXISTS ninos INTEGER CHECK (ninos IS NULL OR ninos >= 0);
-- Las solicitudes viejas solo tenían el total: se toma como adultos
UPDATE prospecto SET adultos = invitados WHERE adultos IS NULL AND ninos IS NULL AND invitados IS NOT NULL;

DROP PROCEDURE IF EXISTS sp_crear_prospecto;
CREATE OR REPLACE PROCEDURE sp_crear_prospecto(
    IN p_nombre character varying, IN p_telefono character varying, IN p_correo character varying,
    IN p_id_tipo_evento integer, IN p_id_salon integer, IN p_fecha_tentativa date,
    IN p_adultos integer, IN p_ninos integer, IN p_mensaje text, IN p_ip_origen character varying,
    OUT p_id_prospecto integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        RAISE EXCEPTION 'Falta el nombre';
    END IF;
    IF p_telefono IS NULL OR TRIM(p_telefono) = '' THEN
        RAISE EXCEPTION 'Falta el teléfono';
    END IF;
    IF p_fecha_tentativa IS NOT NULL AND p_fecha_tentativa < CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha tentativa no puede estar en el pasado';
    END IF;
    IF COALESCE(p_adultos, 0) < 0 OR COALESCE(p_ninos, 0) < 0 THEN
        RAISE EXCEPTION 'La cantidad de invitados no puede ser negativa';
    END IF;

    INSERT INTO prospecto (
        nombre, telefono, correo, id_tipo_evento, id_salon,
        fecha_tentativa, adultos, ninos, invitados, mensaje, ip_origen
    )
    VALUES (
        TRIM(p_nombre), TRIM(p_telefono), NULLIF(TRIM(p_correo), ''), p_id_tipo_evento, p_id_salon,
        p_fecha_tentativa, p_adultos, p_ninos,
        NULLIF(COALESCE(p_adultos, 0) + COALESCE(p_ninos, 0), 0),
        NULLIF(TRIM(p_mensaje), ''), p_ip_origen
    )
    RETURNING id_prospecto INTO p_id_prospecto;
END;
$$;

DROP FUNCTION IF EXISTS fn_listar_prospectos(character varying);
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

-- ---------- 2. Fechas ocupadas: temporal o firme ----------
-- Mismo criterio que fn_validar_disponibilidad_salon (confirmado, en curso, o reserva temporal
-- vigente). Devuelve SOLO fecha, salón y si es temporal: nunca datos del evento ni del cliente.
-- Si en el mismo día y salón hay una firme y una temporal, gana la firme.
DROP FUNCTION IF EXISTS fn_fechas_ocupadas_publico(date, date);
CREATE OR REPLACE FUNCTION fn_fechas_ocupadas_publico(p_desde date, p_hasta date)
RETURNS TABLE(fecha date, id_salon integer, temporal boolean)
    LANGUAGE sql STABLE
    AS $$
    SELECT e.fecha, es.id_salon, NOT bool_or(e.estado IN ('confirmado', 'en_curso')) AS temporal
    FROM evento e
    JOIN evento_salon es ON es.id_evento = e.id_evento
    LEFT JOIN cotizacion c ON c.id_evento = e.id_evento AND c.activa = true
    WHERE e.fecha BETWEEN p_desde AND p_hasta
      AND (
            e.estado IN ('confirmado', 'en_curso')
            OR (
                e.estado = 'cotizacion'
                AND e.reserva_temporal = true
                AND COALESCE(c.fecha_cotizacion + c.vigencia_dias, e.fecha_creacion::date + 8) >= CURRENT_DATE
            )
          )
    GROUP BY e.fecha, es.id_salon
    ORDER BY e.fecha, es.id_salon;
$$;

COMMIT;
