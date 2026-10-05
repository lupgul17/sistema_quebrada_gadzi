CREATE OR REPLACE FUNCTION fn_listar_roles_acceso() RETURNS TABLE(id_rol_acceso integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$ SELECT id_rol_acceso, descripcion FROM tc_rol_acceso ORDER BY id_rol_acceso; $$;
