-- p_grupos:    [{"tipo": "menu"|"componente"|"cortesia", "nombre": "...", "cantidad_a_elegir": 1, "opciones": [ids]}]
-- p_incluidos: [{"id_servicio": 3, "cantidad": 1, "por_cada_personas": 40}] o [{"texto": "Cristalería..."}]
-- p_extras:    [{"id_servicio": 7, "precio": 1800, "calculo": "fijo"|"por_persona"|"hora_extra"}]
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
