CREATE OR REPLACE FUNCTION fn_listar_categorias_servicio() RETURNS TABLE(id_categoria_servicio integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_categoria_servicio, descripcion FROM tc_categoria_servicio ORDER BY descripcion;
$$;
