CREATE OR REPLACE FUNCTION fn_salones_usuario(p_id_usuario INTEGER)
RETURNS INTEGER[]
LANGUAGE sql STABLE
AS $$
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM usuario u JOIN tc_rol_acceso r ON r.id_rol_acceso = u.id_rol_acceso
            WHERE u.id_usuario = p_id_usuario AND r.descripcion = 'Superusuario'
        ) THEN NULL
        WHEN NOT EXISTS (SELECT 1 FROM usuario_area WHERE id_usuario = p_id_usuario) THEN NULL
        ELSE (
            SELECT COALESCE(array_agg(DISTINCT s.id_salon ORDER BY s.id_salon), '{}')
            FROM usuario_area ua
            JOIN salon s ON s.id_salon = ua.id_salon OR s.id_locacion = ua.id_locacion
            WHERE ua.id_usuario = p_id_usuario
        )
    END;
$$;
