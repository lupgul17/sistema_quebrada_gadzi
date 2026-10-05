CREATE OR REPLACE FUNCTION fn_listar_colores_cubremanteles() RETURNS TABLE(id_color_cubremanteles integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_color_cubremanteles, descripcion FROM tc_color_cubremanteles ORDER BY descripcion;
$$;
