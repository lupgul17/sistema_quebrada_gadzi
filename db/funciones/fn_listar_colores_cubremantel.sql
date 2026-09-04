CREATE OR REPLACE FUNCTION fn_listar_colores_cubremanteles()
RETURNS TABLE (id_color_cubremanteles INTEGER, descripcion VARCHAR)
LANGUAGE sql
STABLE
AS $$
    SELECT id_color_cubremanteles, descripcion FROM tc_color_cubremanteles ORDER BY descripcion;
$$;