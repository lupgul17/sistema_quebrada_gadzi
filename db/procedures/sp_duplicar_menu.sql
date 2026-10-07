CREATE OR REPLACE PROCEDURE sp_duplicar_menu(IN p_id_menu integer, IN p_nombre character varying, IN p_precio_base numeric, IN p_locaciones integer[], IN p_salones integer[], OUT p_id_menu_nuevo integer)
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
