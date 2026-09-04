CREATE OR REPLACE FUNCTION fn_listar_tipos_descuento()
RETURNS TABLE (id_tipo_descuento INTEGER, descripcion VARCHAR)
LANGUAGE sql
STABLE
AS $$
    SELECT id_tipo_descuento, descripcion FROM tc_tipo_descuento ORDER BY descripcion;
$$;

