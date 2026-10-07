-- Menú a medida para una cotización (no aparece en el catálogo: es_personalizado = true).
-- p_precio es el precio base por plato SIN recargos. El SP suma siempre el recargo de cada
-- componente elegido que no venga incluido en el menú base (sin menú base, todos).
-- Reemplaza la versión anterior de 7 parámetros de entrada:
--   DROP PROCEDURE sp_crear_menu_personalizado(integer, varchar, integer, numeric, text, integer[], integer);
CREATE OR REPLACE PROCEDURE sp_crear_menu_personalizado(
    p_id_cotizacion          INTEGER,
    p_nombre                 VARCHAR,
    p_id_tipo_menu           INTEGER,
    p_precio                 NUMERIC,
    p_descripcion            TEXT,
    p_componentes            INTEGER[],
    p_cantidad               INTEGER,
    p_id_menu_base           INTEGER,
    OUT p_id_menu            INTEGER,
    OUT p_id_cotizacion_menu INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_evento  INTEGER;
    v_activa     BOOLEAN;
    v_unidad     VARCHAR;
    v_nombre     VARCHAR := TRIM(p_nombre);
    v_ids        INTEGER[];
    v_validos    INTEGER;
    v_recargo    NUMERIC;
BEGIN
    SELECT id_evento, activa INTO v_id_evento, v_activa FROM cotizacion WHERE id_cotizacion = p_id_cotizacion;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la cotizacion con id = %', p_id_cotizacion;
    END IF;
    IF NOT v_activa THEN
        RAISE EXCEPTION 'Solo se puede agregar un menu a la version activa de la cotizacion';
    END IF;
    IF v_nombre IS NULL OR v_nombre = '' THEN
        RAISE EXCEPTION 'El nombre del menu es obligatorio';
    END IF;
    IF p_precio IS NULL OR p_precio <= 0 THEN
        RAISE EXCEPTION 'El precio base debe ser mayor a cero';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tc_tipo_menu WHERE id_tipo_menu = p_id_tipo_menu) THEN
        RAISE EXCEPTION 'Tipo de menu invalido';
    END IF;
    IF p_id_menu_base IS NOT NULL AND NOT EXISTS (SELECT 1 FROM menu WHERE id_menu = p_id_menu_base) THEN
        RAISE EXCEPTION 'El menu base no existe';
    END IF;

    SELECT ARRAY_AGG(DISTINCT t.x) INTO v_ids FROM UNNEST(COALESCE(p_componentes, ARRAY[]::INTEGER[])) AS t(x);
    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'Elegi al menos un componente';
    END IF;

    SELECT COUNT(*) INTO v_validos FROM componente_menu WHERE id_componente = ANY(v_ids) AND activo;
    IF v_validos <> array_length(v_ids, 1) THEN
        RAISE EXCEPTION 'Alguno de los componentes no existe o esta inactivo';
    END IF;

    -- El recargo SIEMPRE se suma al precio base: lo calcula la base, no la pantalla.
    -- Cuentan los componentes elegidos que no vienen incluidos en el menu base (si no hay menu base, todos).
    SELECT COALESCE(SUM(cm.recargo), 0) INTO v_recargo
    FROM componente_menu cm
    WHERE cm.id_componente = ANY(v_ids)
      AND (p_id_menu_base IS NULL
           OR NOT EXISTS (SELECT 1 FROM menu_componentes_menu mcm
                          WHERE mcm.id_menu = p_id_menu_base AND mcm.id_componente = cm.id_componente));

    SELECT unidad_medida INTO v_unidad
    FROM menu WHERE id_tipo_menu = p_id_tipo_menu AND NOT es_personalizado
    ORDER BY id_menu LIMIT 1;
    v_unidad := COALESCE(v_unidad, 'por_persona');

    INSERT INTO menu (nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, activo, es_personalizado, id_evento)
    VALUES (v_nombre, p_id_tipo_menu, p_precio + v_recargo, v_unidad, NULLIF(TRIM(p_descripcion), ''), true, true, v_id_evento)
    RETURNING id_menu INTO p_id_menu;

    INSERT INTO menu_componentes_menu (id_menu, id_componente)
    SELECT p_id_menu, UNNEST(v_ids);

    CALL sp_agregar_menu_cotizacion(p_id_cotizacion, p_id_menu, p_cantidad, p_id_cotizacion_menu);
END;
$$;
