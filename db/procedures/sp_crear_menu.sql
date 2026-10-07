CREATE OR REPLACE PROCEDURE sp_crear_menu(IN p_nombre character varying, IN p_id_tipo_menu integer, IN p_precio_base numeric, IN p_unidad_medida character varying, IN p_descripcion text, IN p_componentes integer[], IN p_locaciones integer[], IN p_salones integer[], OUT p_id_menu integer)
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
