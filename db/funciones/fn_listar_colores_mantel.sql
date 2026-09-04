CREATE OR REPLACE FUNCTION fn_listar_colores_mantel()
RETURNS TABLE (id_color_mantel INTEGER, descripcion VARCHAR)
LANGUAGE sql
STABLE
AS $$
    SELECT id_color_mantel, descripcion FROM tc_color_mantel ORDER BY descripcion;
$$;