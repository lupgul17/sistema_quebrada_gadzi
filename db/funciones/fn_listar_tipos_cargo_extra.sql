CREATE OR REPLACE FUNCTION fn_listar_tipos_cargo_extra() RETURNS TABLE(id_tipo_cargo_extra integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_tipo_cargo_extra, descripcion FROM tc_tipo_cargo_extra ORDER BY descripcion;
$$;
