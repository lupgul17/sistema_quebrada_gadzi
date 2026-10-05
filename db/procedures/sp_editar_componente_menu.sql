CREATE OR REPLACE PROCEDURE sp_editar_componente_menu(IN p_id_componente integer, IN p_id_categoria_componente_menu integer, IN p_nombre character varying, IN p_recargo numeric, IN p_activo boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM componente_menu WHERE id_componente = p_id_componente) THEN
        RAISE EXCEPTION 'No existe un componente con id_componente = %', p_id_componente;
    END IF;

    UPDATE componente_menu
    SET id_categoria_componente_menu = p_id_categoria_componente_menu,
        nombre = p_nombre,
        recargo = p_recargo,
        activo = p_activo
    WHERE id_componente = p_id_componente;
END;
$$;
