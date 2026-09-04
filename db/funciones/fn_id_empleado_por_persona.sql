CREATE OR REPLACE FUNCTION fn_id_empleado_por_persona(p_id_persona INTEGER)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT id_empleado FROM empleado WHERE id_persona = p_id_persona;
$$;