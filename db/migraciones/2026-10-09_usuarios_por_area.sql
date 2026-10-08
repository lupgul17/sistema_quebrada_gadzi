-- =====================================================================================
-- Usuarios por área + logo por locación
--
-- Cada usuario puede tener asignadas áreas: una locación completa (incluye sus salones, también
-- los que se agreguen después) o salones sueltos. Solo ve los eventos de esos salones (y lo que
-- cuelga de ellos: cotizaciones, pagos, degustaciones, extras). En el calendario ve los demás
-- eventos como "Ocupado", sin datos del cliente.
--   - Superusuario: ve todo siempre.
--   - Usuario SIN áreas asignadas: ve todo (así nadie se queda sin acceso al subir esto; el
--     Superusuario después le asigna sus áreas en Usuarios).
-- Los clientes son compartidos entre áreas.
--
-- Correr TODO este archivo de una vez en el SQL Editor de Neon (va en una transacción).
-- =====================================================================================
BEGIN;

-- ---------- 1. Logo de cada locación (archivo en la-quebrada-backend/assets) ----------
ALTER TABLE locacion ADD COLUMN IF NOT EXISTS logo VARCHAR(100);
UPDATE locacion SET logo = 'logo-quebrada.png' WHERE logo IS NULL AND nombre ILIKE '%quebrada%';
UPDATE locacion SET logo = 'logo-gadzi.png' WHERE logo IS NULL AND nombre ILIKE '%gadzi%';

-- ---------- 2. Áreas de cada usuario ----------
CREATE TABLE IF NOT EXISTS usuario_area (
    id_usuario_area SERIAL PRIMARY KEY,
    id_usuario   INTEGER NOT NULL REFERENCES usuario (id_usuario) ON DELETE CASCADE,
    id_locacion  INTEGER REFERENCES locacion (id_locacion),
    id_salon     INTEGER REFERENCES salon (id_salon),
    -- Cada fila es UNA locación completa o UN salón
    CONSTRAINT chk_usuario_area_una CHECK ((id_locacion IS NULL) <> (id_salon IS NULL))
);
CREATE INDEX IF NOT EXISTS idx_usuario_area_usuario ON usuario_area (id_usuario);
CREATE UNIQUE INDEX IF NOT EXISTS uq_usuario_area_locacion ON usuario_area (id_usuario, id_locacion) WHERE id_locacion IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_usuario_area_salon ON usuario_area (id_usuario, id_salon) WHERE id_salon IS NOT NULL;

-- ---------- 3. Salones que puede ver un usuario (NULL = todos) ----------
CREATE OR REPLACE FUNCTION fn_salones_usuario(p_id_usuario INTEGER)
RETURNS INTEGER[]
LANGUAGE sql STABLE
AS $$
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM usuario u JOIN tc_rol_acceso r ON r.id_rol_acceso = u.id_rol_acceso
            WHERE u.id_usuario = p_id_usuario AND r.descripcion = 'Superusuario'
        ) THEN NULL
        WHEN NOT EXISTS (SELECT 1 FROM usuario_area WHERE id_usuario = p_id_usuario) THEN NULL
        ELSE (
            SELECT COALESCE(array_agg(DISTINCT s.id_salon ORDER BY s.id_salon), '{}')
            FROM usuario_area ua
            JOIN salon s ON s.id_salon = ua.id_salon OR s.id_locacion = ua.id_locacion
            WHERE ua.id_usuario = p_id_usuario
        )
    END;
$$;

-- Áreas asignadas a un usuario, para mostrarlas: [{tipo, id, nombre}] ([] = todas)
CREATE OR REPLACE FUNCTION fn_areas_usuario(p_id_usuario INTEGER)
RETURNS JSON
LANGUAGE sql STABLE
AS $$
    SELECT COALESCE(json_agg(json_build_object(
               'tipo', CASE WHEN ua.id_salon IS NULL THEN 'locacion' ELSE 'salon' END,
               'id', COALESCE(ua.id_salon, ua.id_locacion),
               'nombre', COALESCE(s.nombre, l.nombre)
           ) ORDER BY (ua.id_salon IS NOT NULL), COALESCE(s.nombre, l.nombre)), '[]'::json)
    FROM usuario_area ua
    LEFT JOIN salon s ON s.id_salon = ua.id_salon
    LEFT JOIN locacion l ON l.id_locacion = ua.id_locacion
    WHERE ua.id_usuario = p_id_usuario;
$$;

-- Reemplaza las áreas de un usuario (sin áreas = todas). Un salón cuya locación ya está marcada sobra.
CREATE OR REPLACE PROCEDURE sp_guardar_areas_usuario(p_id_usuario INTEGER, p_locaciones INTEGER[], p_salones INTEGER[])
LANGUAGE plpgsql
AS $$
DECLARE
    v_loc INTEGER[] := COALESCE(p_locaciones, '{}');
    v_sal INTEGER[] := COALESCE(p_salones, '{}');
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario) THEN
        RAISE EXCEPTION 'No existe el usuario con id = %', p_id_usuario;
    END IF;
    IF EXISTS (SELECT 1 FROM UNNEST(v_loc) x WHERE NOT EXISTS (SELECT 1 FROM locacion l WHERE l.id_locacion = x)) THEN
        RAISE EXCEPTION 'Alguna de las locaciones elegidas no existe';
    END IF;
    IF EXISTS (SELECT 1 FROM UNNEST(v_sal) x WHERE NOT EXISTS (SELECT 1 FROM salon s WHERE s.id_salon = x)) THEN
        RAISE EXCEPTION 'Alguno de los salones elegidos no existe';
    END IF;

    DELETE FROM usuario_area WHERE id_usuario = p_id_usuario;
    INSERT INTO usuario_area (id_usuario, id_locacion) SELECT DISTINCT p_id_usuario, x FROM UNNEST(v_loc) x;
    INSERT INTO usuario_area (id_usuario, id_salon)
    SELECT DISTINCT p_id_usuario, s.id_salon
    FROM UNNEST(v_sal) x JOIN salon s ON s.id_salon = x
    WHERE NOT (s.id_locacion = ANY (v_loc));
END;
$$;

-- ---------- 4. ¿De qué evento es esto? (para validar el alcance de cualquier ruta con id) ----------
CREATE OR REPLACE FUNCTION fn_evento_de(p_tipo VARCHAR, p_id INTEGER)
RETURNS INTEGER
LANGUAGE sql STABLE
AS $$
    SELECT CASE p_tipo
        WHEN 'evento' THEN (SELECT id_evento FROM evento WHERE id_evento = p_id)
        WHEN 'cotizacion' THEN (SELECT id_evento FROM cotizacion WHERE id_cotizacion = p_id)
        WHEN 'cotizacion_menu' THEN (
            SELECT c.id_evento FROM cotizacion_menu cm JOIN cotizacion c ON c.id_cotizacion = cm.id_cotizacion
            WHERE cm.id_cotizacion_menu = p_id)
        WHEN 'cotizacion_servicios' THEN (
            SELECT c.id_evento FROM cotizacion_servicios cs JOIN cotizacion c ON c.id_cotizacion = cs.id_cotizacion
            WHERE cs.id_cotizacion_servicios = p_id)
        WHEN 'descuento' THEN (
            SELECT c.id_evento FROM cotizacion_servicios_descuento d
            JOIN cotizacion_servicios cs ON cs.id_cotizacion_servicios = d.id_cotizacion_servicios
            JOIN cotizacion c ON c.id_cotizacion = cs.id_cotizacion
            WHERE d.id_descuento = p_id)
        WHEN 'pago' THEN (SELECT id_evento FROM pago WHERE id_pago = p_id)
        WHEN 'degustacion' THEN (SELECT id_evento FROM degustacion WHERE id_degustacion = p_id)
        WHEN 'degustacion_menu' THEN (
            SELECT d.id_evento FROM degustacion_menu dm JOIN degustacion d ON d.id_degustacion = dm.id_degustacion
            WHERE dm.id_degustacion_menu = p_id)
        WHEN 'extras_servicios' THEN (
            SELECT e.id_evento FROM extras_servicios es JOIN extras e ON e.id_extra = es.id_extra
            WHERE es.id_extras_servicios = p_id)
        WHEN 'extras_menu' THEN (
            SELECT e.id_evento FROM extras_menu em JOIN extras e ON e.id_extra = em.id_extra
            WHERE em.id_extras_menu = p_id)
    END;
$$;

-- ¿El evento usa alguno de estos salones? (p_salones NULL = ve todo)
CREATE OR REPLACE FUNCTION fn_evento_en_alcance(p_id_evento INTEGER, p_salones INTEGER[])
RETURNS BOOLEAN
LANGUAGE sql STABLE
AS $$
    SELECT p_id_evento IS NOT NULL AND (
        p_salones IS NULL
        OR EXISTS (SELECT 1 FROM evento_salon es WHERE es.id_evento = p_id_evento AND es.id_salon = ANY (p_salones))
    );
$$;

COMMIT;
