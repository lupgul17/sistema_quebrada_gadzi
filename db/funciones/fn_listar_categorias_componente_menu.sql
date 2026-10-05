CREATE OR REPLACE FUNCTION fn_listar_categorias_componente_menu() RETURNS TABLE(id_categoria_componente_menu integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_categoria_componente_menu, descripcion FROM tc_categoria_componente_menu ORDER BY descripcion;
$$;
