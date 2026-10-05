CREATE OR REPLACE PROCEDURE sp_crear_menu_personalizado(IN p_id_cotizacion integer, IN p_nombre character varying, IN p_id_tipo_menu integer, IN p_precio numeric, IN p_descripcion text, IN p_componentes integer[], IN p_cantidad integer, OUT p_id_menu integer, OUT p_id_cotizacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_evento  INTEGER;
    v_activa     BOOLEAN;
    v_unidad     VARCHAR;
    v_nombre     VARCHAR := TRIM(p_nombre);
    v_ids        INTEGER[];
    v_validos    INTEGER;
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
        RAISE EXCEPTION 'El precio debe ser mayor a cero';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tc_tipo_menu WHERE id_tipo_menu = p_id_tipo_menu) THEN
        RAISE EXCEPTION 'Tipo de menu invalido';
    END IF;

    SELECT ARRAY_AGG(DISTINCT t.x) INTO v_ids FROM UNNEST(COALESCE(p_componentes, ARRAY[]::INTEGER[])) AS t(x);
    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'Elegi al menos un componente';
    END IF;

    SELECT COUNT(*) INTO v_validos FROM componente_menu WHERE id_componente = ANY(v_ids) AND activo;
    IF v_validos <> array_length(v_ids, 1) THEN
        RAISE EXCEPTION 'Alguno de los componentes no existe o esta inactivo';
    END IF;

    SELECT unidad_medida INTO v_unidad
    FROM menu WHERE id_tipo_menu = p_id_tipo_menu AND NOT es_personalizado
    ORDER BY id_menu LIMIT 1;
    v_unidad := COALESCE(v_unidad, 'por_persona');

    INSERT INTO menu (nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, activo, es_personalizado, id_evento)
    VALUES (v_nombre, p_id_tipo_menu, p_precio, v_unidad, NULLIF(TRIM(p_descripcion), ''), true, true, v_id_evento)
    RETURNING id_menu INTO p_id_menu;

    INSERT INTO menu_componentes_menu (id_menu, id_componente)
    SELECT p_id_menu, UNNEST(v_ids);

    CALL sp_agregar_menu_cotizacion(p_id_cotizacion, p_id_menu, p_cantidad, p_id_cotizacion_menu);
END;
$$;
