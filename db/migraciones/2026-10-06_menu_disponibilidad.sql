-- =====================================================================================
-- Disponibilidad de menús por área (locación completa o salón específico)
--
-- Regla: un menú SIN filas en menu_disponibilidad se ofrece en todos lados (es el valor por
-- defecto y así quedan todos los menús actuales, sin migrar datos). Con filas, se ofrece solo
-- en esas áreas. Los precios distintos por área se manejan con menús repetidos (cada copia
-- con su precio), por eso no hay precio por locación.
--
-- Correr TODO este archivo de una vez en el SQL Editor de Neon. Va en una transacción:
-- si algo falla, no se aplica nada.
-- =====================================================================================
BEGIN;

-- ---------- 1. Tabla ----------
CREATE TABLE IF NOT EXISTS menu_disponibilidad (
    id_menu_disponibilidad SERIAL PRIMARY KEY,
    id_menu      INTEGER NOT NULL REFERENCES menu (id_menu) ON DELETE CASCADE,
    id_locacion  INTEGER REFERENCES locacion (id_locacion),
    id_salon     INTEGER REFERENCES salon (id_salon),
    -- Cada fila es UNA locación completa o UN salón, nunca las dos cosas ni ninguna
    CONSTRAINT chk_menu_disp_un_area CHECK ((id_locacion IS NULL) <> (id_salon IS NULL))
);
CREATE INDEX IF NOT EXISTS idx_menu_disp_menu ON menu_disponibilidad (id_menu);
CREATE UNIQUE INDEX IF NOT EXISTS uq_menu_disp_locacion ON menu_disponibilidad (id_menu, id_locacion) WHERE id_locacion IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_menu_disp_salon ON menu_disponibilidad (id_menu, id_salon) WHERE id_salon IS NOT NULL;

-- ---------- 2. ¿Se puede usar este menú en este evento? ----------
-- Personalizados: solo en su propio evento. Catálogo: sin restricción, o alguna de sus áreas
-- coincide con un salón del evento (el salón mismo o la locación del salón).
CREATE OR REPLACE FUNCTION fn_menu_disponible_evento(p_id_menu INTEGER, p_id_evento INTEGER)
RETURNS BOOLEAN
LANGUAGE sql STABLE
AS $$
    SELECT CASE
        WHEN m.es_personalizado THEN COALESCE(m.id_evento = p_id_evento, false)
        ELSE NOT EXISTS (SELECT 1 FROM menu_disponibilidad md WHERE md.id_menu = m.id_menu)
          OR EXISTS (
                SELECT 1
                FROM menu_disponibilidad md
                JOIN evento_salon es ON es.id_evento = p_id_evento
                JOIN salon s ON s.id_salon = es.id_salon
                WHERE md.id_menu = m.id_menu
                  AND (md.id_salon = s.id_salon OR md.id_locacion = s.id_locacion)
             )
    END
    FROM menu m
    WHERE m.id_menu = p_id_menu;
$$;

-- ---------- 3. Áreas para elegir (locaciones con sus salones) ----------
CREATE OR REPLACE FUNCTION fn_listar_areas_menu()
RETURNS TABLE (id_locacion INTEGER, locacion VARCHAR, id_salon INTEGER, salon VARCHAR)
LANGUAGE sql STABLE
AS $$
    SELECT l.id_locacion, l.nombre, s.id_salon, s.nombre
    FROM locacion l
    LEFT JOIN salon s ON s.id_locacion = l.id_locacion
    ORDER BY l.nombre, s.nombre;
$$;

-- ---------- 4. Listado de menús (cambia la firma y las columnas: hay que borrar la anterior) ----------
DROP FUNCTION IF EXISTS fn_listar_menus(integer);
CREATE OR REPLACE FUNCTION fn_listar_menus(
    p_id_tipo_menu      INTEGER DEFAULT NULL,
    p_id_evento         INTEGER DEFAULT NULL,  -- solo los que se pueden usar en ese evento (y activos)
    p_id_locacion       INTEGER DEFAULT NULL,  -- catálogo: disponibles en esa locación
    p_id_salon          INTEGER DEFAULT NULL,  -- catálogo: disponibles en ese salón
    p_sin_restriccion   BOOLEAN DEFAULT false  -- catálogo: solo los de "todos lados"
)
RETURNS TABLE (
    id_menu         INTEGER,
    nombre          VARCHAR,
    precio_base     NUMERIC,
    unidad_medida   VARCHAR,
    descripcion     TEXT,
    activo          BOOLEAN,
    id_tipo_menu    INTEGER,
    tipo_menu       VARCHAR,
    componentes     TEXT,
    disponibilidad  JSON   -- [] = todos lados; si no, [{tipo: 'locacion'|'salon', id, nombre}]
)
LANGUAGE sql STABLE
AS $$
    SELECT
        m.id_menu, m.nombre, m.precio_base, m.unidad_medida, m.descripcion, m.activo,
        tm.id_tipo_menu, tm.descripcion AS tipo_menu,
        STRING_AGG(cm.nombre, ', ' ORDER BY cm.nombre) AS componentes,
        (
            SELECT COALESCE(json_agg(json_build_object(
                       'tipo', CASE WHEN md.id_salon IS NULL THEN 'locacion' ELSE 'salon' END,
                       'id', COALESCE(md.id_salon, md.id_locacion),
                       'nombre', COALESCE(sa.nombre, lo.nombre)
                   ) ORDER BY (md.id_salon IS NOT NULL), COALESCE(sa.nombre, lo.nombre)), '[]'::json)
            FROM menu_disponibilidad md
            LEFT JOIN salon sa ON sa.id_salon = md.id_salon
            LEFT JOIN locacion lo ON lo.id_locacion = md.id_locacion
            WHERE md.id_menu = m.id_menu
        ) AS disponibilidad
    FROM menu m
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    LEFT JOIN menu_componentes_menu mcm ON mcm.id_menu = m.id_menu
    LEFT JOIN componente_menu cm ON cm.id_componente = mcm.id_componente
    WHERE (p_id_tipo_menu IS NULL OR m.id_tipo_menu = p_id_tipo_menu)
      AND NOT m.es_personalizado
      AND (p_id_evento IS NULL OR (m.activo AND fn_menu_disponible_evento(m.id_menu, p_id_evento)))
      AND (NOT p_sin_restriccion OR NOT EXISTS (SELECT 1 FROM menu_disponibilidad x WHERE x.id_menu = m.id_menu))
      AND (p_id_locacion IS NULL
           OR NOT EXISTS (SELECT 1 FROM menu_disponibilidad x WHERE x.id_menu = m.id_menu)
           OR EXISTS (SELECT 1 FROM menu_disponibilidad x LEFT JOIN salon xs ON xs.id_salon = x.id_salon
                      WHERE x.id_menu = m.id_menu AND (x.id_locacion = p_id_locacion OR xs.id_locacion = p_id_locacion)))
      AND (p_id_salon IS NULL
           OR NOT EXISTS (SELECT 1 FROM menu_disponibilidad x WHERE x.id_menu = m.id_menu)
           OR EXISTS (SELECT 1 FROM menu_disponibilidad x
                      WHERE x.id_menu = m.id_menu
                        AND (x.id_salon = p_id_salon
                             OR x.id_locacion = (SELECT s2.id_locacion FROM salon s2 WHERE s2.id_salon = p_id_salon))))
    GROUP BY m.id_menu, tm.id_tipo_menu, tm.descripcion
    ORDER BY tm.descripcion, m.nombre, m.precio_base;
$$;

-- ---------- 5. Detalle del menú (suma las áreas: cambia el tipo de retorno) ----------
DROP FUNCTION IF EXISTS fn_menu_detalle(integer);
CREATE OR REPLACE FUNCTION fn_menu_detalle(p_id_menu INTEGER)
RETURNS TABLE (
    id_menu          INTEGER,
    nombre           VARCHAR,
    precio_base      NUMERIC,
    unidad_medida    VARCHAR,
    descripcion      TEXT,
    activo           BOOLEAN,
    id_tipo_menu     INTEGER,
    tipo_menu        VARCHAR,
    componentes_ids  INTEGER[],
    locaciones_ids   INTEGER[],
    salones_ids      INTEGER[]
)
LANGUAGE sql STABLE
AS $$
    SELECT
        m.id_menu, m.nombre, m.precio_base, m.unidad_medida, m.descripcion, m.activo,
        tm.id_tipo_menu, tm.descripcion AS tipo_menu,
        ARRAY_AGG(cm.id_componente ORDER BY cm.nombre) FILTER (WHERE cm.id_componente IS NOT NULL) AS componentes_ids,
        COALESCE((SELECT ARRAY_AGG(md.id_locacion ORDER BY md.id_locacion) FROM menu_disponibilidad md
                  WHERE md.id_menu = m.id_menu AND md.id_locacion IS NOT NULL), '{}') AS locaciones_ids,
        COALESCE((SELECT ARRAY_AGG(md.id_salon ORDER BY md.id_salon) FROM menu_disponibilidad md
                  WHERE md.id_menu = m.id_menu AND md.id_salon IS NOT NULL), '{}') AS salones_ids
    FROM menu m
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    LEFT JOIN menu_componentes_menu mcm ON mcm.id_menu = m.id_menu
    LEFT JOIN componente_menu cm ON cm.id_componente = mcm.id_componente
    WHERE m.id_menu = p_id_menu
    GROUP BY m.id_menu, tm.id_tipo_menu, tm.descripcion;
$$;

-- ---------- 6. Guardar las áreas de un menú (ambos arreglos vacíos = todos lados) ----------
CREATE OR REPLACE PROCEDURE sp_guardar_disponibilidad_menu(
    p_id_menu      INTEGER,
    p_locaciones   INTEGER[],
    p_salones      INTEGER[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_locaciones INTEGER[] := COALESCE(p_locaciones, '{}');
    v_salones    INTEGER[] := COALESCE(p_salones, '{}');
BEGIN
    IF EXISTS (SELECT 1 FROM UNNEST(v_locaciones) x WHERE NOT EXISTS (SELECT 1 FROM locacion l WHERE l.id_locacion = x)) THEN
        RAISE EXCEPTION 'Alguna de las locaciones elegidas no existe';
    END IF;
    IF EXISTS (SELECT 1 FROM UNNEST(v_salones) x WHERE NOT EXISTS (SELECT 1 FROM salon s WHERE s.id_salon = x)) THEN
        RAISE EXCEPTION 'Alguno de los salones elegidos no existe';
    END IF;

    DELETE FROM menu_disponibilidad WHERE id_menu = p_id_menu;

    INSERT INTO menu_disponibilidad (id_menu, id_locacion)
    SELECT DISTINCT p_id_menu, x FROM UNNEST(v_locaciones) x;

    -- Un salón cuya locación completa ya está marcada sobra: no se guarda
    INSERT INTO menu_disponibilidad (id_menu, id_salon)
    SELECT DISTINCT p_id_menu, s.id_salon
    FROM UNNEST(v_salones) x
    JOIN salon s ON s.id_salon = x
    WHERE NOT (s.id_locacion = ANY (v_locaciones));
END;
$$;

-- ---------- 7. Crear / editar menú (suman las áreas: cambia la firma) ----------
DROP PROCEDURE IF EXISTS sp_crear_menu(varchar, integer, numeric, varchar, text, integer[]);
CREATE OR REPLACE PROCEDURE sp_crear_menu(
    p_nombre         VARCHAR,
    p_id_tipo_menu   INTEGER,
    p_precio_base    NUMERIC,
    p_unidad_medida  VARCHAR,
    p_descripcion    TEXT,
    p_componentes    INTEGER[],
    p_locaciones     INTEGER[],
    p_salones        INTEGER[],
    OUT p_id_menu    INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO menu (nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, activo)
    VALUES (p_nombre, p_id_tipo_menu, p_precio_base, p_unidad_medida, p_descripcion, true)
    RETURNING id_menu INTO p_id_menu;

    INSERT INTO menu_componentes_menu (id_menu, id_componente)
    SELECT DISTINCT p_id_menu, x FROM UNNEST(COALESCE(p_componentes, '{}')) x;

    CALL sp_guardar_disponibilidad_menu(p_id_menu, p_locaciones, p_salones);
END;
$$;

DROP PROCEDURE IF EXISTS sp_editar_menu(integer, varchar, integer, numeric, varchar, text, boolean, integer[]);
CREATE OR REPLACE PROCEDURE sp_editar_menu(
    p_id_menu        INTEGER,
    p_nombre         VARCHAR,
    p_id_tipo_menu   INTEGER,
    p_precio_base    NUMERIC,
    p_unidad_medida  VARCHAR,
    p_descripcion    TEXT,
    p_activo         BOOLEAN,
    p_componentes    INTEGER[],
    p_locaciones     INTEGER[],
    p_salones        INTEGER[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM menu WHERE id_menu = p_id_menu) THEN
        RAISE EXCEPTION 'No existe un menu con id_menu = %', p_id_menu;
    END IF;

    UPDATE menu
    SET nombre = p_nombre, id_tipo_menu = p_id_tipo_menu, precio_base = p_precio_base,
        unidad_medida = p_unidad_medida, descripcion = p_descripcion, activo = p_activo
    WHERE id_menu = p_id_menu;

    DELETE FROM menu_componentes_menu WHERE id_menu = p_id_menu;
    INSERT INTO menu_componentes_menu (id_menu, id_componente)
    SELECT DISTINCT p_id_menu, x FROM UNNEST(COALESCE(p_componentes, '{}')) x;

    CALL sp_guardar_disponibilidad_menu(p_id_menu, p_locaciones, p_salones);
END;
$$;

-- ---------- 8. Duplicar menú (misma receta, otro precio/área) ----------
CREATE OR REPLACE PROCEDURE sp_duplicar_menu(
    p_id_menu           INTEGER,
    p_nombre            VARCHAR,   -- NULL = mismo nombre
    p_precio_base       NUMERIC,   -- NULL = mismo precio
    p_locaciones        INTEGER[],
    p_salones           INTEGER[],
    OUT p_id_menu_nuevo INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_original menu%ROWTYPE;
BEGIN
    SELECT * INTO v_original FROM menu WHERE id_menu = p_id_menu;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe un menu con id_menu = %', p_id_menu;
    END IF;
    IF v_original.es_personalizado THEN
        RAISE EXCEPTION 'Los menus a medida de un evento no se duplican';
    END IF;
    IF p_precio_base IS NOT NULL AND p_precio_base <= 0 THEN
        RAISE EXCEPTION 'El precio debe ser mayor a cero';
    END IF;

    INSERT INTO menu (nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, activo)
    VALUES (
        COALESCE(NULLIF(TRIM(p_nombre), ''), v_original.nombre),
        v_original.id_tipo_menu,
        COALESCE(p_precio_base, v_original.precio_base),
        v_original.unidad_medida,
        v_original.descripcion,
        true
    )
    RETURNING id_menu INTO p_id_menu_nuevo;

    INSERT INTO menu_componentes_menu (id_menu, id_componente)
    SELECT p_id_menu_nuevo, id_componente FROM menu_componentes_menu WHERE id_menu = p_id_menu;

    CALL sp_guardar_disponibilidad_menu(p_id_menu_nuevo, p_locaciones, p_salones);
END;
$$;

-- ---------- 9. Validar el área al usarlo (misma firma: solo se reemplaza el cuerpo) ----------
CREATE OR REPLACE PROCEDURE sp_agregar_menu_cotizacion(IN p_id_cotizacion integer, IN p_id_menu integer, IN p_cantidad integer, OUT p_id_cotizacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_precio_base DECIMAL;
    v_tipo_menu   VARCHAR;
    v_id_evento   INTEGER;
    v_activa      BOOLEAN;
    v_cantidad    INTEGER := p_cantidad;
BEGIN
    SELECT id_evento, activa INTO v_id_evento, v_activa FROM cotizacion WHERE id_cotizacion = p_id_cotizacion;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la cotizacion con id = %', p_id_cotizacion;
    END IF;
    IF NOT v_activa THEN
        RAISE EXCEPTION 'Solo se puede editar la version activa de la cotizacion';
    END IF;

    SELECT m.precio_base, tm.descripcion INTO v_precio_base, v_tipo_menu
    FROM menu m JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    WHERE m.id_menu = p_id_menu;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el menu con id = %', p_id_menu;
    END IF;

    IF NOT fn_menu_disponible_evento(p_id_menu, v_id_evento) THEN
        RAISE EXCEPTION 'Este menu no se ofrece en los salones de este evento';
    END IF;

    IF v_cantidad IS NULL THEN
        SELECT CASE WHEN v_tipo_menu = 'individual_infantil' THEN total_menores ELSE total_adultos END
        INTO v_cantidad FROM evento WHERE id_evento = v_id_evento;
        IF v_cantidad IS NULL OR v_cantidad <= 0 THEN
            RAISE EXCEPTION 'La cantidad automatica es 0 (el evento no tiene % registrados). Indica la cantidad manualmente.',
                CASE WHEN v_tipo_menu = 'individual_infantil' THEN 'ninos' ELSE 'adultos' END;
        END IF;
    ELSIF v_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor a cero';
    END IF;

    INSERT INTO cotizacion_menu (id_cotizacion, id_menu, precio_unitario_congelado, cantidad, subtotal)
    VALUES (p_id_cotizacion, p_id_menu, v_precio_base, v_cantidad, v_precio_base * v_cantidad)
    RETURNING id_cotizacion_menu INTO p_id_cotizacion_menu;

    CALL sp_refrescar_totales_cotizacion(p_id_cotizacion);
END;
$$;

CREATE OR REPLACE PROCEDURE sp_agregar_menu_degustacion(IN p_id_degustacion integer, IN p_id_menu integer, OUT p_id_degustacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_cantidad_actual        INTEGER;
    v_es_adicional           BOOLEAN;
    v_id_evento              INTEGER;
    v_id_cotizacion          INTEGER;
    v_precio_menu            DECIMAL;
    v_id_cotizacion_menu     INTEGER;
BEGIN
    SELECT id_evento INTO v_id_evento FROM degustacion WHERE id_degustacion = p_id_degustacion;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la degustacion con id = %', p_id_degustacion;
    END IF;

    IF NOT fn_menu_disponible_evento(p_id_menu, v_id_evento) THEN
        RAISE EXCEPTION 'Este menu no se ofrece en los salones de este evento';
    END IF;

    SELECT COUNT(*) INTO v_cantidad_actual FROM degustacion_menu WHERE id_degustacion = p_id_degustacion;

    IF v_cantidad_actual >= 4 THEN
        RAISE EXCEPTION 'Ya se alcanzó el máximo de 4 platillos de degustación para este evento';
    END IF;

    v_es_adicional := v_cantidad_actual >= 2;

    INSERT INTO degustacion_menu (id_degustacion, id_menu, resultado, es_adicional)
    VALUES (p_id_degustacion, p_id_menu, 'pendiente', v_es_adicional)
    RETURNING id_degustacion_menu INTO p_id_degustacion_menu;

    IF v_es_adicional THEN
        SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion WHERE id_evento = v_id_evento AND activa = true;

        IF v_id_cotizacion IS NULL THEN
            RAISE EXCEPTION 'Este evento no tiene ninguna cotización activa todavía — no se puede cobrar el platillo extra hasta que exista una';
        END IF;

        SELECT precio_base INTO v_precio_menu FROM menu WHERE id_menu = p_id_menu;

        INSERT INTO cotizacion_menu (id_cotizacion, id_menu, precio_unitario_congelado, cantidad, subtotal)
        VALUES (v_id_cotizacion, p_id_menu, v_precio_menu, 1, v_precio_menu)
        RETURNING id_cotizacion_menu INTO v_id_cotizacion_menu;

        UPDATE degustacion_menu
        SET id_cotizacion_menu = v_id_cotizacion_menu
        WHERE id_degustacion_menu = p_id_degustacion_menu;

        CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION sp_agregar_extra_menu(p_id_evento integer, p_id_menu integer, p_descripcion text, p_cantidad integer, p_precio_base numeric, p_id_empleado integer, OUT p_id_extras_menu integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_extra INTEGER;
    v_subtotal NUMERIC;
BEGIN
    -- p_id_menu es NULL en los extras personalizados (solo descripción): no hay área que validar
    IF p_id_menu IS NOT NULL AND NOT fn_menu_disponible_evento(p_id_menu, p_id_evento) THEN
        RAISE EXCEPTION 'Este menu no se ofrece en los salones de este evento';
    END IF;

    INSERT INTO extras (id_evento, id_empleado)
    VALUES (p_id_evento, p_id_empleado)
    ON CONFLICT (id_evento) DO NOTHING;

    SELECT id_extra INTO v_id_extra
    FROM extras
    WHERE id_evento = p_id_evento;

    v_subtotal := p_cantidad * p_precio_base;

    INSERT INTO extras_menu (
        id_extra, id_menu, descripcion, cantidad, precio_base, subtotal, estado
    ) VALUES (
        v_id_extra, p_id_menu, p_descripcion, p_cantidad, p_precio_base, v_subtotal, 'aprobado'
    )
    RETURNING id_extras_menu INTO p_id_extras_menu;

    UPDATE extras
    SET total = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM extras_servicios
        WHERE id_extra = v_id_extra AND estado != 'cancelado'
    ) + (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM extras_menu
        WHERE id_extra = v_id_extra AND estado != 'cancelado'
    )
    WHERE id_extra = v_id_extra;
END;
$$;

COMMIT;
