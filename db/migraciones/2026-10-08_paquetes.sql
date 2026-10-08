
BEGIN;

-- Se puede correr aunque ya se haya corrido una versión anterior de este archivo: lo que cambió
-- de forma se rehace (los paquetes de prueba pierden opciones/incluidos, hay que volver a editarlos).

-- ---------- 1. Tablas ----------
CREATE TABLE IF NOT EXISTS paquete (
    id_paquete          SERIAL PRIMARY KEY,
    nombre              VARCHAR(150) NOT NULL,
    descripcion         TEXT,
    precio_por_persona  NUMERIC(10,2) NOT NULL CHECK (precio_por_persona > 0),
    minimo_personas     INTEGER NOT NULL DEFAULT 1 CHECK (minimo_personas > 0),
    id_tipo_menu        INTEGER NOT NULL REFERENCES tc_tipo_menu (id_tipo_menu),
    activo              BOOLEAN NOT NULL DEFAULT true,
    fecha_creacion      TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Horas de uso de instalaciones incluidas; si el evento dura más se sugiere la hora extra
ALTER TABLE paquete ADD COLUMN IF NOT EXISTS horas_incluidas INTEGER CHECK (horas_incluidas > 0);

-- Grupo de elección: 'menu' (menús del catálogo, ej. plato fuerte), 'componente' (ej. bebida fría:
-- naranjada/jamaica/gaseosa) o 'cortesia' (servicios a Q0, ej. discoteca/brindis/pastel)
CREATE TABLE IF NOT EXISTS paquete_grupo (
    id_paquete_grupo   SERIAL PRIMARY KEY,
    id_paquete         INTEGER NOT NULL REFERENCES paquete (id_paquete) ON DELETE CASCADE,
    tipo               VARCHAR(10) NOT NULL,
    nombre             VARCHAR(100) NOT NULL,
    cantidad_a_elegir  INTEGER NOT NULL DEFAULT 1 CHECK (cantidad_a_elegir > 0),
    orden              INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_paquete_grupo_paquete ON paquete_grupo (id_paquete);
ALTER TABLE paquete_grupo DROP CONSTRAINT IF EXISTS paquete_grupo_tipo_check;
ALTER TABLE paquete_grupo ADD CONSTRAINT paquete_grupo_tipo_check CHECK (tipo IN ('menu', 'componente', 'cortesia'));

-- La primera versión guardaba componentes en vez de menús: esa tabla se rehace
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'paquete_grupo_opcion')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'paquete_grupo_opcion' AND column_name = 'id_menu') THEN
        DROP TABLE paquete_grupo_opcion;
    END IF;
END $$;

-- Opción de un grupo: un menú, un componente o un servicio (según el tipo del grupo)
CREATE TABLE IF NOT EXISTS paquete_grupo_opcion (
    id_paquete_grupo_opcion SERIAL PRIMARY KEY,
    id_paquete_grupo  INTEGER NOT NULL REFERENCES paquete_grupo (id_paquete_grupo) ON DELETE CASCADE,
    id_menu           INTEGER REFERENCES menu (id_menu),
    id_componente     INTEGER REFERENCES componente_menu (id_componente),
    id_servicio       INTEGER REFERENCES servicios (id_servicio)
);
ALTER TABLE paquete_grupo_opcion ADD COLUMN IF NOT EXISTS id_componente INTEGER REFERENCES componente_menu (id_componente);
ALTER TABLE paquete_grupo_opcion DROP CONSTRAINT IF EXISTS chk_paquete_opcion_una;
ALTER TABLE paquete_grupo_opcion ADD CONSTRAINT chk_paquete_opcion_una CHECK (num_nonnulls(id_menu, id_componente, id_servicio) = 1);
CREATE INDEX IF NOT EXISTS idx_paquete_opcion_grupo ON paquete_grupo_opcion (id_paquete_grupo);

-- Lo que incluye el paquete (a Q0): un servicio (cantidad fija, o "1 por cada N personas" como
-- los meseros) o solo un texto que se muestra en la cotización (ej. "Cristalería: plato, tenedor...")
DROP TABLE IF EXISTS paquete_servicio_incluido;  -- versión anterior: solo servicios
CREATE TABLE IF NOT EXISTS paquete_incluido (
    id_paquete_incluido  SERIAL PRIMARY KEY,
    id_paquete           INTEGER NOT NULL REFERENCES paquete (id_paquete) ON DELETE CASCADE,
    id_servicio          INTEGER REFERENCES servicios (id_servicio),
    texto                VARCHAR(250),
    cantidad             INTEGER NOT NULL DEFAULT 1 CHECK (cantidad > 0),
    por_cada_personas    INTEGER CHECK (por_cada_personas > 0),
    orden                INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT chk_paquete_incluido_uno CHECK (num_nonnulls(id_servicio, texto) = 1)
);
CREATE INDEX IF NOT EXISTS idx_paquete_incluido_paquete ON paquete_incluido (id_paquete);

-- Extras opcionales con precio especial del paquete. calculo = cómo se sugiere la cantidad:
-- 'fijo' (la escribe el vendedor), 'por_persona' (los invitados), 'hora_extra' (horas sobre las incluidas)
CREATE TABLE IF NOT EXISTS paquete_extra (
    id_paquete   INTEGER NOT NULL REFERENCES paquete (id_paquete) ON DELETE CASCADE,
    id_servicio  INTEGER NOT NULL REFERENCES servicios (id_servicio),
    precio       NUMERIC(10,2) NOT NULL CHECK (precio >= 0),
    calculo      VARCHAR(12) NOT NULL DEFAULT 'fijo' CHECK (calculo IN ('fijo', 'por_persona', 'hora_extra')),
    orden        INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (id_paquete, id_servicio)
);

CREATE TABLE IF NOT EXISTS paquete_disponibilidad (
    id_paquete_disponibilidad SERIAL PRIMARY KEY,
    id_paquete   INTEGER NOT NULL REFERENCES paquete (id_paquete) ON DELETE CASCADE,
    id_locacion  INTEGER REFERENCES locacion (id_locacion),
    id_salon     INTEGER REFERENCES salon (id_salon),
    CONSTRAINT chk_paquete_disp_un_area CHECK ((id_locacion IS NULL) <> (id_salon IS NULL))
);
CREATE INDEX IF NOT EXISTS idx_paquete_disp_paquete ON paquete_disponibilidad (id_paquete);

-- De qué paquete salió una cotización y quién autorizó aplicarlo bajo el mínimo
ALTER TABLE cotizacion ADD COLUMN IF NOT EXISTS id_paquete INTEGER REFERENCES paquete (id_paquete);
ALTER TABLE cotizacion ADD COLUMN IF NOT EXISTS id_usuario_autoriza_minimo INTEGER REFERENCES usuario (id_usuario);

-- Lo que se eligió e incluye, congelado al aplicar. Va ligado al menú de la línea del paquete
-- (no a la cotización) para que siga ahí cuando se hace una versión nueva, que copia las líneas.
CREATE TABLE IF NOT EXISTS paquete_aplicado (
    id_menu          INTEGER PRIMARY KEY REFERENCES menu (id_menu) ON DELETE CASCADE,
    id_paquete       INTEGER NOT NULL REFERENCES paquete (id_paquete),
    elecciones       TEXT,              -- "Milanesa de pollo · Jamaica · 3 tortillas"
    incluye          JSONB NOT NULL DEFAULT '[]'::jsonb,  -- textos de "incluye"
    horas_incluidas  INTEGER
);

-- ---------- 2. ¿Se puede usar este paquete en este evento? (misma regla que los menús) ----------
CREATE OR REPLACE FUNCTION fn_paquete_disponible_evento(p_id_paquete INTEGER, p_id_evento INTEGER)
RETURNS BOOLEAN
LANGUAGE sql STABLE
AS $$
    SELECT NOT EXISTS (SELECT 1 FROM paquete_disponibilidad pd WHERE pd.id_paquete = p_id_paquete)
        OR EXISTS (
            SELECT 1
            FROM paquete_disponibilidad pd
            JOIN evento_salon es ON es.id_evento = p_id_evento
            JOIN salon s ON s.id_salon = es.id_salon
            WHERE pd.id_paquete = p_id_paquete
              AND (pd.id_salon = s.id_salon OR pd.id_locacion = s.id_locacion)
        );
$$;

-- ---------- 3. Listado (con grupos, opciones, incluidos, extras y áreas en JSON) ----------
DROP FUNCTION IF EXISTS fn_listar_paquetes(INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION fn_listar_paquetes(
    p_id_evento   INTEGER DEFAULT NULL,  -- solo los activos que se pueden usar en ese evento
    p_id_paquete  INTEGER DEFAULT NULL   -- uno solo (detalle)
)
RETURNS TABLE (
    id_paquete          INTEGER,
    nombre              VARCHAR,
    descripcion         TEXT,
    precio_por_persona  NUMERIC,
    minimo_personas     INTEGER,
    horas_incluidas     INTEGER,
    id_tipo_menu        INTEGER,
    tipo_menu           VARCHAR,
    activo              BOOLEAN,
    grupos              JSON,   -- [{id, tipo, nombre, cantidad_a_elegir, opciones: [{id, nombre, categoria, detalle}]}]
    incluidos           JSON,   -- [{id_servicio, texto, nombre, cantidad, por_cada_personas}]
    extras              JSON,   -- [{id_servicio, nombre, unidad_medida, precio, precio_catalogo, calculo}]
    disponibilidad      JSON    -- [] = todos lados; si no, [{tipo, id, nombre}]
)
LANGUAGE sql STABLE
AS $$
    SELECT
        p.id_paquete, p.nombre, p.descripcion, p.precio_por_persona, p.minimo_personas, p.horas_incluidas,
        p.id_tipo_menu, tm.descripcion AS tipo_menu, p.activo,
        (
            SELECT COALESCE(json_agg(json_build_object(
                       'id', g.id_paquete_grupo,
                       'tipo', g.tipo,
                       'nombre', g.nombre,
                       'cantidad_a_elegir', g.cantidad_a_elegir,
                       'opciones', (
                           SELECT COALESCE(json_agg(json_build_object(
                                      'id', COALESCE(o.id_menu, o.id_componente, o.id_servicio),
                                      'nombre', COALESCE(m.nombre, cm.nombre, sv.nombre),
                                      -- menú: su tipo; componente: su categoría; cortesía: la del servicio
                                      'categoria', COALESCE(tmo.descripcion, cc.descripcion, cs.descripcion),
                                      -- menú: sus componentes, para ver qué trae cada opción
                                      'detalle', (SELECT string_agg(c2.nombre, ', ' ORDER BY c2.nombre)
                                                  FROM menu_componentes_menu mc
                                                  JOIN componente_menu c2 ON c2.id_componente = mc.id_componente
                                                  WHERE mc.id_menu = o.id_menu)
                                  ) ORDER BY o.id_paquete_grupo_opcion), '[]'::json)
                           FROM paquete_grupo_opcion o
                           LEFT JOIN menu m ON m.id_menu = o.id_menu
                           LEFT JOIN tc_tipo_menu tmo ON tmo.id_tipo_menu = m.id_tipo_menu
                           LEFT JOIN componente_menu cm ON cm.id_componente = o.id_componente
                           LEFT JOIN tc_categoria_componente_menu cc ON cc.id_categoria_componente_menu = cm.id_categoria_componente_menu
                           LEFT JOIN servicios sv ON sv.id_servicio = o.id_servicio
                           LEFT JOIN tc_categoria_servicio cs ON cs.id_categoria_servicio = sv.id_categoria_servicio
                           WHERE o.id_paquete_grupo = g.id_paquete_grupo
                       )
                   ) ORDER BY g.orden, g.id_paquete_grupo), '[]'::json)
            FROM paquete_grupo g
            WHERE g.id_paquete = p.id_paquete
        ) AS grupos,
        (
            SELECT COALESCE(json_agg(json_build_object(
                       'id_servicio', i.id_servicio, 'texto', i.texto, 'nombre', COALESCE(sv.nombre, i.texto),
                       'cantidad', i.cantidad, 'por_cada_personas', i.por_cada_personas
                   ) ORDER BY i.orden, i.id_paquete_incluido), '[]'::json)
            FROM paquete_incluido i
            LEFT JOIN servicios sv ON sv.id_servicio = i.id_servicio
            WHERE i.id_paquete = p.id_paquete
        ) AS incluidos,
        (
            SELECT COALESCE(json_agg(json_build_object(
                       'id_servicio', e.id_servicio, 'nombre', sv.nombre, 'unidad_medida', sv.unidad_medida,
                       'precio', e.precio, 'precio_catalogo', sv.precio_base, 'calculo', e.calculo
                   ) ORDER BY e.orden, sv.nombre), '[]'::json)
            FROM paquete_extra e
            JOIN servicios sv ON sv.id_servicio = e.id_servicio
            WHERE e.id_paquete = p.id_paquete
        ) AS extras,
        (
            SELECT COALESCE(json_agg(json_build_object(
                       'tipo', CASE WHEN pd.id_salon IS NULL THEN 'locacion' ELSE 'salon' END,
                       'id', COALESCE(pd.id_salon, pd.id_locacion),
                       'nombre', COALESCE(sa.nombre, lo.nombre)
                   ) ORDER BY (pd.id_salon IS NOT NULL), COALESCE(sa.nombre, lo.nombre)), '[]'::json)
            FROM paquete_disponibilidad pd
            LEFT JOIN salon sa ON sa.id_salon = pd.id_salon
            LEFT JOIN locacion lo ON lo.id_locacion = pd.id_locacion
            WHERE pd.id_paquete = p.id_paquete
        ) AS disponibilidad
    FROM paquete p
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = p.id_tipo_menu
    WHERE (p_id_paquete IS NULL OR p.id_paquete = p_id_paquete)
      AND (p_id_evento IS NULL OR (p.activo AND fn_paquete_disponible_evento(p.id_paquete, p_id_evento)))
    ORDER BY p.nombre, p.precio_por_persona;
$$;

-- ---------- 4. Guardar (crear o editar) un paquete completo ----------
-- p_grupos:    [{"tipo": "menu"|"componente"|"cortesia", "nombre": "...", "cantidad_a_elegir": 1, "opciones": [ids]}]
-- p_incluidos: [{"id_servicio": 3, "cantidad": 1, "por_cada_personas": 40}] o [{"texto": "Cristalería..."}]
-- p_extras:    [{"id_servicio": 7, "precio": 1800, "calculo": "fijo"|"por_persona"|"hora_extra"}]
DROP PROCEDURE IF EXISTS sp_guardar_paquete;
CREATE OR REPLACE PROCEDURE sp_guardar_paquete(
    p_id_paquete          INTEGER,   -- NULL = nuevo
    p_nombre              VARCHAR,
    p_descripcion         TEXT,
    p_precio_por_persona  NUMERIC,
    p_minimo_personas     INTEGER,
    p_horas_incluidas     INTEGER,
    p_id_tipo_menu        INTEGER,
    p_activo              BOOLEAN,
    p_grupos              JSONB,
    p_incluidos           JSONB,
    p_extras              JSONB,
    p_locaciones          INTEGER[],
    p_salones             INTEGER[],
    OUT p_id_paquete_out  INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_grupo     JSONB;
    v_id_grupo  INTEGER;
    v_orden     INTEGER := 0;
    v_tipo      VARCHAR;
    v_cantidad  INTEGER;
    v_opciones  INTEGER[];
    v_validas   INTEGER;
    v_nombre    VARCHAR := TRIM(p_nombre);
    v_loc       INTEGER[] := COALESCE(p_locaciones, '{}');
    v_sal       INTEGER[] := COALESCE(p_salones, '{}');
BEGIN
    IF v_nombre IS NULL OR v_nombre = '' THEN
        RAISE EXCEPTION 'El nombre del paquete es obligatorio';
    END IF;
    IF p_precio_por_persona IS NULL OR p_precio_por_persona <= 0 THEN
        RAISE EXCEPTION 'El precio por persona debe ser mayor a cero';
    END IF;
    IF p_minimo_personas IS NULL OR p_minimo_personas <= 0 THEN
        RAISE EXCEPTION 'El mínimo de personas debe ser mayor a cero';
    END IF;
    IF p_horas_incluidas IS NOT NULL AND p_horas_incluidas <= 0 THEN
        RAISE EXCEPTION 'Las horas incluidas deben ser mayores a cero';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tc_tipo_menu WHERE id_tipo_menu = p_id_tipo_menu) THEN
        RAISE EXCEPTION 'Tipo de menú inválido';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM jsonb_array_elements(COALESCE(p_grupos, '[]'::jsonb)) g WHERE g->>'tipo' = 'menu') THEN
        RAISE EXCEPTION 'El paquete necesita al menos un grupo de menús (ej. plato fuerte)';
    END IF;
    IF EXISTS (SELECT 1 FROM UNNEST(v_loc) x WHERE NOT EXISTS (SELECT 1 FROM locacion l WHERE l.id_locacion = x)) THEN
        RAISE EXCEPTION 'Alguna de las locaciones elegidas no existe';
    END IF;
    IF EXISTS (SELECT 1 FROM UNNEST(v_sal) x WHERE NOT EXISTS (SELECT 1 FROM salon s WHERE s.id_salon = x)) THEN
        RAISE EXCEPTION 'Alguno de los salones elegidos no existe';
    END IF;

    IF p_id_paquete IS NULL THEN
        INSERT INTO paquete (nombre, descripcion, precio_por_persona, minimo_personas, horas_incluidas, id_tipo_menu, activo)
        VALUES (v_nombre, NULLIF(TRIM(p_descripcion), ''), p_precio_por_persona, p_minimo_personas, p_horas_incluidas,
                p_id_tipo_menu, COALESCE(p_activo, true))
        RETURNING id_paquete INTO p_id_paquete_out;
    ELSE
        UPDATE paquete
        SET nombre = v_nombre, descripcion = NULLIF(TRIM(p_descripcion), ''), precio_por_persona = p_precio_por_persona,
            minimo_personas = p_minimo_personas, horas_incluidas = p_horas_incluidas,
            id_tipo_menu = p_id_tipo_menu, activo = COALESCE(p_activo, true)
        WHERE id_paquete = p_id_paquete;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No existe el paquete con id = %', p_id_paquete;
        END IF;
        p_id_paquete_out := p_id_paquete;
        -- Las cotizaciones guardan sus propias líneas: rehacer la estructura no las afecta
        DELETE FROM paquete_grupo WHERE id_paquete = p_id_paquete_out;
        DELETE FROM paquete_incluido WHERE id_paquete = p_id_paquete_out;
        DELETE FROM paquete_extra WHERE id_paquete = p_id_paquete_out;
        DELETE FROM paquete_disponibilidad WHERE id_paquete = p_id_paquete_out;
    END IF;

    -- Grupos y sus opciones
    FOR v_grupo IN SELECT * FROM jsonb_array_elements(COALESCE(p_grupos, '[]'::jsonb)) LOOP
        v_tipo := v_grupo->>'tipo';
        v_cantidad := COALESCE((v_grupo->>'cantidad_a_elegir')::INTEGER, 1);
        -- Sin repetidos pero respetando el orden en que se cargaron (así se muestran al elegir)
        SELECT ARRAY(
            SELECT x FROM (
                SELECT (t.x)::INTEGER AS x, MIN(t.n) AS n
                FROM jsonb_array_elements_text(COALESCE(v_grupo->'opciones', '[]'::jsonb)) WITH ORDINALITY AS t(x, n)
                GROUP BY 1
            ) s ORDER BY n
        ) INTO v_opciones;

        IF v_tipo IS NULL OR v_tipo NOT IN ('menu', 'componente', 'cortesia') THEN
            RAISE EXCEPTION 'Tipo de grupo inválido: %', v_tipo;
        END IF;
        IF COALESCE(TRIM(v_grupo->>'nombre'), '') = '' THEN
            RAISE EXCEPTION 'Cada grupo necesita un nombre';
        END IF;
        IF array_length(v_opciones, 1) IS NULL THEN
            RAISE EXCEPTION 'El grupo "%" no tiene opciones', v_grupo->>'nombre';
        END IF;
        IF v_cantidad < 1 OR v_cantidad > array_length(v_opciones, 1) THEN
            RAISE EXCEPTION 'En "%" no se pueden elegir % de % opciones', v_grupo->>'nombre', v_cantidad, array_length(v_opciones, 1);
        END IF;

        v_validas := CASE v_tipo
            -- Solo menús del catálogo (no los armados a medida de un evento)
            WHEN 'menu' THEN (SELECT COUNT(*) FROM menu WHERE id_menu = ANY(v_opciones) AND NOT es_personalizado)
            WHEN 'componente' THEN (SELECT COUNT(*) FROM componente_menu WHERE id_componente = ANY(v_opciones))
            ELSE (SELECT COUNT(*) FROM servicios WHERE id_servicio = ANY(v_opciones))
        END;
        IF v_validas <> array_length(v_opciones, 1) THEN
            RAISE EXCEPTION 'Alguna opción de "%" no es válida', v_grupo->>'nombre';
        END IF;

        INSERT INTO paquete_grupo (id_paquete, tipo, nombre, cantidad_a_elegir, orden)
        VALUES (p_id_paquete_out, v_tipo, TRIM(v_grupo->>'nombre'), v_cantidad, v_orden)
        RETURNING id_paquete_grupo INTO v_id_grupo;
        v_orden := v_orden + 1;

        -- El orden de las opciones es el del arreglo (id serial creciente)
        INSERT INTO paquete_grupo_opcion (id_paquete_grupo, id_menu, id_componente, id_servicio)
        SELECT v_id_grupo,
               CASE WHEN v_tipo = 'menu' THEN x END,
               CASE WHEN v_tipo = 'componente' THEN x END,
               CASE WHEN v_tipo = 'cortesia' THEN x END
        FROM UNNEST(v_opciones) WITH ORDINALITY AS t(x, n)
        ORDER BY n;
    END LOOP;

    -- Incluidos: servicio o texto
    IF EXISTS (
        SELECT 1 FROM jsonb_array_elements(COALESCE(p_incluidos, '[]'::jsonb)) i
        WHERE num_nonnulls(NULLIF(i->>'id_servicio', ''), NULLIF(TRIM(i->>'texto'), '')) <> 1
    ) THEN
        RAISE EXCEPTION 'Cada "incluye" debe ser un servicio o un texto';
    END IF;
    INSERT INTO paquete_incluido (id_paquete, id_servicio, texto, cantidad, por_cada_personas, orden)
    SELECT p_id_paquete_out, (i->>'id_servicio')::INTEGER, NULLIF(TRIM(i->>'texto'), ''),
           COALESCE((i->>'cantidad')::INTEGER, 1), (i->>'por_cada_personas')::INTEGER, n
    FROM jsonb_array_elements(COALESCE(p_incluidos, '[]'::jsonb)) WITH ORDINALITY AS t(i, n);

    -- Extras opcionales con su precio de paquete
    IF (SELECT COUNT(*) FROM jsonb_array_elements(COALESCE(p_extras, '[]'::jsonb)) e)
       <> (SELECT COUNT(DISTINCT e->>'id_servicio') FROM jsonb_array_elements(COALESCE(p_extras, '[]'::jsonb)) e) THEN
        RAISE EXCEPTION 'Un mismo servicio está dos veces en los extras';
    END IF;
    INSERT INTO paquete_extra (id_paquete, id_servicio, precio, calculo, orden)
    SELECT p_id_paquete_out, (e->>'id_servicio')::INTEGER, (e->>'precio')::NUMERIC, COALESCE(e->>'calculo', 'fijo'), n
    FROM jsonb_array_elements(COALESCE(p_extras, '[]'::jsonb)) WITH ORDINALITY AS t(e, n);

    -- Áreas (sin áreas = todos lados); un salón cuya locación ya está marcada sobra
    INSERT INTO paquete_disponibilidad (id_paquete, id_locacion)
    SELECT DISTINCT p_id_paquete_out, x FROM UNNEST(v_loc) x;
    INSERT INTO paquete_disponibilidad (id_paquete, id_salon)
    SELECT DISTINCT p_id_paquete_out, s.id_salon
    FROM UNNEST(v_sal) x JOIN salon s ON s.id_salon = x
    WHERE NOT (s.id_locacion = ANY (v_loc));
END;
$$;

-- ---------- 5. Duplicar (misma estructura, otro precio/área) ----------
CREATE OR REPLACE PROCEDURE sp_duplicar_paquete(
    p_id_paquete           INTEGER,
    p_nombre               VARCHAR,
    p_precio_por_persona   NUMERIC,
    p_locaciones           INTEGER[],
    p_salones              INTEGER[],
    OUT p_id_paquete_nuevo INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_original paquete%ROWTYPE;
    v_grupo    RECORD;
    v_nuevo_g  INTEGER;
    v_loc      INTEGER[] := COALESCE(p_locaciones, '{}');
BEGIN
    SELECT * INTO v_original FROM paquete WHERE id_paquete = p_id_paquete;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el paquete con id = %', p_id_paquete;
    END IF;
    IF p_precio_por_persona IS NOT NULL AND p_precio_por_persona <= 0 THEN
        RAISE EXCEPTION 'El precio por persona debe ser mayor a cero';
    END IF;

    INSERT INTO paquete (nombre, descripcion, precio_por_persona, minimo_personas, horas_incluidas, id_tipo_menu, activo)
    VALUES (COALESCE(NULLIF(TRIM(p_nombre), ''), v_original.nombre), v_original.descripcion,
            COALESCE(p_precio_por_persona, v_original.precio_por_persona), v_original.minimo_personas,
            v_original.horas_incluidas, v_original.id_tipo_menu, true)
    RETURNING id_paquete INTO p_id_paquete_nuevo;

    FOR v_grupo IN SELECT * FROM paquete_grupo WHERE id_paquete = p_id_paquete ORDER BY orden LOOP
        INSERT INTO paquete_grupo (id_paquete, tipo, nombre, cantidad_a_elegir, orden)
        VALUES (p_id_paquete_nuevo, v_grupo.tipo, v_grupo.nombre, v_grupo.cantidad_a_elegir, v_grupo.orden)
        RETURNING id_paquete_grupo INTO v_nuevo_g;
        INSERT INTO paquete_grupo_opcion (id_paquete_grupo, id_menu, id_componente, id_servicio)
        SELECT v_nuevo_g, id_menu, id_componente, id_servicio FROM paquete_grupo_opcion
        WHERE id_paquete_grupo = v_grupo.id_paquete_grupo ORDER BY id_paquete_grupo_opcion;
    END LOOP;

    INSERT INTO paquete_incluido (id_paquete, id_servicio, texto, cantidad, por_cada_personas, orden)
    SELECT p_id_paquete_nuevo, id_servicio, texto, cantidad, por_cada_personas, orden
    FROM paquete_incluido WHERE id_paquete = p_id_paquete;

    -- Los precios de los extras se copian igual; si en la otra área cambian, se editan después
    INSERT INTO paquete_extra (id_paquete, id_servicio, precio, calculo, orden)
    SELECT p_id_paquete_nuevo, id_servicio, precio, calculo, orden FROM paquete_extra WHERE id_paquete = p_id_paquete;

    INSERT INTO paquete_disponibilidad (id_paquete, id_locacion)
    SELECT DISTINCT p_id_paquete_nuevo, x FROM UNNEST(v_loc) x;
    INSERT INTO paquete_disponibilidad (id_paquete, id_salon)
    SELECT DISTINCT p_id_paquete_nuevo, s.id_salon
    FROM UNNEST(COALESCE(p_salones, '{}')) x JOIN salon s ON s.id_salon = x
    WHERE NOT (s.id_locacion = ANY (v_loc));
END;
$$;

-- ---------- 6. Aplicar un paquete a un evento (crea una nueva versión de la cotización) ----------
-- p_extras: [{"id_servicio": 7, "cantidad": 2}] (solo los extras que el cliente quiere)
DROP PROCEDURE IF EXISTS sp_aplicar_paquete;
CREATE OR REPLACE PROCEDURE sp_aplicar_paquete(
    p_id_evento             INTEGER,
    p_id_paquete            INTEGER,
    p_menus                 INTEGER[],  -- menús elegidos en los grupos de menús
    p_componentes           INTEGER[],  -- componentes elegidos en los grupos de componentes
    p_cortesias             INTEGER[],  -- servicios elegidos en los grupos de cortesía
    p_extras                JSONB,
    p_cantidad              INTEGER,    -- NULL = adultos del evento
    p_deposito_garantia     NUMERIC,
    p_id_empleado           INTEGER,
    p_id_usuario_autoriza   INTEGER,    -- obligatorio si la cantidad es menor al mínimo
    OUT p_id_cotizacion     INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_paquete    paquete%ROWTYPE;
    v_cantidad   INTEGER := p_cantidad;
    v_personas   INTEGER;
    v_grupo      RECORD;
    v_elegidos   INTEGER;
    v_menus      INTEGER[] := (SELECT ARRAY(SELECT DISTINCT x FROM UNNEST(COALESCE(p_menus, '{}')) x));
    v_comp       INTEGER[] := (SELECT ARRAY(SELECT DISTINCT x FROM UNNEST(COALESCE(p_componentes, '{}')) x));
    v_cort       INTEGER[] := (SELECT ARRAY(SELECT DISTINCT x FROM UNNEST(COALESCE(p_cortesias, '{}')) x));
    v_extras     JSONB := COALESCE(p_extras, '[]'::jsonb);
    v_id_menu    INTEGER;
    v_elecciones TEXT;
    v_linea      INTEGER;
    v_rol        VARCHAR;
BEGIN
    SELECT * INTO v_paquete FROM paquete WHERE id_paquete = p_id_paquete;
    IF NOT FOUND OR NOT v_paquete.activo THEN
        RAISE EXCEPTION 'El paquete no existe o está inactivo';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM evento WHERE id_evento = p_id_evento) THEN
        RAISE EXCEPTION 'No existe el evento con id = %', p_id_evento;
    END IF;
    IF NOT fn_paquete_disponible_evento(p_id_paquete, p_id_evento) THEN
        RAISE EXCEPTION 'Este paquete no se ofrece en los salones de este evento';
    END IF;

    IF v_cantidad IS NULL THEN
        SELECT total_adultos INTO v_cantidad FROM evento WHERE id_evento = p_id_evento;
    END IF;
    IF v_cantidad IS NULL OR v_cantidad <= 0 THEN
        RAISE EXCEPTION 'Indicá la cantidad de personas (el evento no tiene adultos registrados)';
    END IF;
    -- Para "1 por cada N personas" cuentan todos los invitados (los niños van aparte en el precio)
    SELECT v_cantidad + COALESCE(total_menores, 0) INTO v_personas FROM evento WHERE id_evento = p_id_evento;

    -- Bajo el mínimo: solo con autorización de Administrador o Superusuario
    IF v_cantidad < v_paquete.minimo_personas THEN
        IF p_id_usuario_autoriza IS NULL THEN
            RAISE EXCEPTION 'El paquete es para mínimo % personas y el evento tiene %: hace falta la autorización de un administrador',
                v_paquete.minimo_personas, v_cantidad;
        END IF;
        SELECT ra.descripcion INTO v_rol
        FROM usuario u JOIN tc_rol_acceso ra ON ra.id_rol_acceso = u.id_rol_acceso
        WHERE u.id_usuario = p_id_usuario_autoriza AND u.activo;
        IF v_rol IS NULL OR v_rol NOT IN ('Administrador', 'Superusuario') THEN
            RAISE EXCEPTION 'Solo un Administrador o Superusuario puede autorizar el paquete bajo el mínimo';
        END IF;
    END IF;

    -- Cada grupo con la cantidad exacta de opciones elegidas
    FOR v_grupo IN SELECT * FROM paquete_grupo WHERE id_paquete = p_id_paquete ORDER BY orden LOOP
        SELECT COUNT(*) INTO v_elegidos
        FROM paquete_grupo_opcion o
        WHERE o.id_paquete_grupo = v_grupo.id_paquete_grupo
          AND CASE v_grupo.tipo
                  WHEN 'menu' THEN o.id_menu = ANY(v_menus)
                  WHEN 'componente' THEN o.id_componente = ANY(v_comp)
                  ELSE o.id_servicio = ANY(v_cort)
              END;
        IF v_elegidos <> v_grupo.cantidad_a_elegir THEN
            RAISE EXCEPTION 'En "%" hay que elegir % opción(es)', v_grupo.nombre, v_grupo.cantidad_a_elegir;
        END IF;
    END LOOP;
    -- ...y nada que no sea del paquete
    IF EXISTS (SELECT 1 FROM UNNEST(v_menus) x WHERE NOT EXISTS (
                   SELECT 1 FROM paquete_grupo g JOIN paquete_grupo_opcion o ON o.id_paquete_grupo = g.id_paquete_grupo
                   WHERE g.id_paquete = p_id_paquete AND g.tipo = 'menu' AND o.id_menu = x))
       OR EXISTS (SELECT 1 FROM UNNEST(v_comp) x WHERE NOT EXISTS (
                   SELECT 1 FROM paquete_grupo g JOIN paquete_grupo_opcion o ON o.id_paquete_grupo = g.id_paquete_grupo
                   WHERE g.id_paquete = p_id_paquete AND g.tipo = 'componente' AND o.id_componente = x))
       OR EXISTS (SELECT 1 FROM UNNEST(v_cort) x WHERE NOT EXISTS (
                   SELECT 1 FROM paquete_grupo g JOIN paquete_grupo_opcion o ON o.id_paquete_grupo = g.id_paquete_grupo
                   WHERE g.id_paquete = p_id_paquete AND g.tipo = 'cortesia' AND o.id_servicio = x))
    THEN
        RAISE EXCEPTION 'Se eligió una opción que no pertenece al paquete';
    END IF;

    -- Extras: solo los del paquete, con cantidad válida y sin repetir
    IF EXISTS (
        SELECT 1 FROM jsonb_array_elements(v_extras) e
        WHERE NOT EXISTS (SELECT 1 FROM paquete_extra pe
                          WHERE pe.id_paquete = p_id_paquete AND pe.id_servicio = (e->>'id_servicio')::INTEGER)
           OR COALESCE((e->>'cantidad')::INTEGER, 0) <= 0
    ) THEN
        RAISE EXCEPTION 'Algún extra no es de este paquete o no tiene cantidad';
    END IF;
    IF (SELECT COUNT(*) FROM jsonb_array_elements(v_extras))
       <> (SELECT COUNT(DISTINCT e->>'id_servicio') FROM jsonb_array_elements(v_extras) e) THEN
        RAISE EXCEPTION 'Un extra está repetido';
    END IF;

    -- Nueva versión de la cotización (la anterior queda como reemplazada)
    CALL sp_crear_cotizacion(p_id_evento, 8, COALESCE(p_deposito_garantia, 0), p_id_empleado, p_id_cotizacion);

    -- La nueva versión hereda las líneas de la anterior: el paquete las reemplaza, salvo los
    -- platillos extra de degustación (se cobran aparte y siguen vinculados a la degustación)
    DELETE FROM cotizacion_menu cm
    WHERE cm.id_cotizacion = p_id_cotizacion
      AND NOT EXISTS (SELECT 1 FROM degustacion_menu dm WHERE dm.id_cotizacion_menu = cm.id_cotizacion_menu);
    DELETE FROM cotizacion_servicios WHERE id_cotizacion = p_id_cotizacion;

    -- Lo elegido en texto, en el orden de los grupos: "Milanesa de pollo · Jamaica · 3 tortillas"
    SELECT string_agg(COALESCE(m.nombre, c.nombre), ' · ' ORDER BY g.orden, o.id_paquete_grupo_opcion) INTO v_elecciones
    FROM paquete_grupo g
    JOIN paquete_grupo_opcion o ON o.id_paquete_grupo = g.id_paquete_grupo
    LEFT JOIN menu m ON m.id_menu = o.id_menu
    LEFT JOIN componente_menu c ON c.id_componente = o.id_componente
    WHERE g.id_paquete = p_id_paquete
      AND ((g.tipo = 'menu' AND o.id_menu = ANY(v_menus)) OR (g.tipo = 'componente' AND o.id_componente = ANY(v_comp)));

    -- Línea del paquete: un menú a medida del evento con los componentes de los menús elegidos más
    -- los componentes elegidos, a precio fijo por persona (los precios de cada menú no cuentan)
    INSERT INTO menu (nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, activo, es_personalizado, id_evento)
    VALUES ('Paquete ' || v_paquete.nombre, v_paquete.id_tipo_menu, v_paquete.precio_por_persona, 'por_persona',
            v_elecciones, true, true, p_id_evento)
    RETURNING id_menu INTO v_id_menu;
    INSERT INTO menu_componentes_menu (id_menu, id_componente)
    SELECT DISTINCT v_id_menu, x.id_componente
    FROM (SELECT mc.id_componente FROM menu_componentes_menu mc WHERE mc.id_menu = ANY(v_menus)
          UNION SELECT UNNEST(v_comp)) x;
    CALL sp_agregar_menu_cotizacion(p_id_cotizacion, v_id_menu, v_cantidad, v_linea);

    INSERT INTO paquete_aplicado (id_menu, id_paquete, elecciones, incluye, horas_incluidas)
    VALUES (v_id_menu, p_id_paquete, v_elecciones,
            (SELECT COALESCE(jsonb_agg(i.texto ORDER BY i.orden), '[]'::jsonb)
             FROM paquete_incluido i WHERE i.id_paquete = p_id_paquete AND i.texto IS NOT NULL),
            v_paquete.horas_incluidas);

    -- Servicios incluidos y cortesías: a Q0 (ya van en el precio por persona)
    INSERT INTO cotizacion_servicios (id_cotizacion, id_servicio, cantidad, precio_unitario_congelado, subtotal)
    SELECT p_id_cotizacion, i.id_servicio,
           CASE WHEN i.por_cada_personas IS NULL THEN i.cantidad
                ELSE i.cantidad * CEIL(v_personas::NUMERIC / i.por_cada_personas)::INTEGER END,
           0, 0
    FROM paquete_incluido i
    WHERE i.id_paquete = p_id_paquete AND i.id_servicio IS NOT NULL
    ORDER BY i.orden;
    INSERT INTO cotizacion_servicios (id_cotizacion, id_servicio, cantidad, precio_unitario_congelado, subtotal)
    SELECT p_id_cotizacion, x, 1, 0, 0 FROM UNNEST(v_cort) x;

    -- Extras elegidos: con el precio especial del paquete
    INSERT INTO cotizacion_servicios (id_cotizacion, id_servicio, cantidad, precio_unitario_congelado, subtotal)
    SELECT p_id_cotizacion, pe.id_servicio, (e->>'cantidad')::INTEGER, pe.precio, pe.precio * (e->>'cantidad')::INTEGER
    FROM jsonb_array_elements(v_extras) e
    JOIN paquete_extra pe ON pe.id_paquete = p_id_paquete AND pe.id_servicio = (e->>'id_servicio')::INTEGER
    ORDER BY pe.orden;

    UPDATE cotizacion
    SET id_paquete = p_id_paquete,
        id_usuario_autoriza_minimo = CASE WHEN v_cantidad < v_paquete.minimo_personas THEN p_id_usuario_autoriza END
    WHERE id_cotizacion = p_id_cotizacion;

    CALL sp_refrescar_totales_cotizacion(p_id_cotizacion);
END;
$$;

-- ---------- 7. Paquete(s) de una cotización, para mostrar y para el PDF ----------
CREATE OR REPLACE FUNCTION fn_cotizacion_paquete(p_id_cotizacion INTEGER)
RETURNS TABLE (
    id_cotizacion_menu  INTEGER,
    paquete             VARCHAR,
    elecciones          TEXT,
    incluye             JSONB,
    horas_incluidas     INTEGER
)
LANGUAGE sql STABLE
AS $$
    SELECT cm.id_cotizacion_menu, p.nombre, pa.elecciones, pa.incluye, pa.horas_incluidas
    FROM cotizacion_menu cm
    JOIN paquete_aplicado pa ON pa.id_menu = cm.id_menu
    JOIN paquete p ON p.id_paquete = pa.id_paquete
    WHERE cm.id_cotizacion = p_id_cotizacion
    ORDER BY cm.id_cotizacion_menu;
$$;

COMMIT;
