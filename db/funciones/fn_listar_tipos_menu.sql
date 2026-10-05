CREATE OR REPLACE FUNCTION fn_listar_tipos_menu() RETURNS TABLE(id_tipo_menu integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_tipo_menu, descripcion FROM tc_tipo_menu ORDER BY descripcion;
$$;
