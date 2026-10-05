CREATE OR REPLACE PROCEDURE sp_crear_componente_menu(IN p_id_categoria_componente_menu integer, IN p_nombre character varying, IN p_recargo numeric, OUT p_id_componente integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO componente_menu (id_categoria_componente_menu, nombre, recargo, activo)
    VALUES (p_id_categoria_componente_menu, p_nombre, p_recargo, true)
    RETURNING id_componente INTO p_id_componente;
END;
$$;
