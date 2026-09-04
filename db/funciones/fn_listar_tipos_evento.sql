CREATE OR REPLACE FUNCTION fn_listar_tipos_evento()
RETURNS TABLE (
    id_tipo_evento  INTEGER,
    descripcion     VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT id_tipo_evento, descripcion
    FROM tc_tipo_evento
    ORDER BY descripcion;
$$;