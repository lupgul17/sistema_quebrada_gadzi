CREATE OR REPLACE PROCEDURE sp_editar_menu(IN p_id_menu integer, IN p_nombre character varying, IN p_id_tipo_menu integer, IN p_precio_base numeric, IN p_unidad_medida character varying, IN p_descripcion text, IN p_activo boolean, IN p_componentes integer[], IN p_locaciones integer[], IN p_salones integer[])
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
