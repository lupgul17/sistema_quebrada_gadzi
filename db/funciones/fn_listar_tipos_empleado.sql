CREATE OR REPLACE FUNCTION fn_listar_tipos_empleado() RETURNS TABLE(id_tipo_empleado integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$ SELECT id_tipo_empleado, descripcion FROM tc_tipo_empleado ORDER BY id_tipo_empleado; $$;
