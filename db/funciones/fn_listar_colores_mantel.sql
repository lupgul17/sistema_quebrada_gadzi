CREATE OR REPLACE FUNCTION fn_listar_colores_mantel() RETURNS TABLE(id_color_mantel integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_color_mantel, descripcion FROM tc_color_mantel ORDER BY descripcion;
$$;
