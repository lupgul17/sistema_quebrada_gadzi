CREATE OR REPLACE FUNCTION fn_listar_tipos_pago()
RETURNS TABLE (id_tipo_pago INTEGER, descripcion VARCHAR)
LANGUAGE sql
STABLE
AS $$
    SELECT id_tipo_pago, descripcion FROM tc_tipo_pago ORDER BY descripcion;
$$;