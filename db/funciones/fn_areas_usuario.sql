CREATE OR REPLACE FUNCTION fn_areas_usuario(p_id_usuario INTEGER)
RETURNS JSON
LANGUAGE sql STABLE
AS $$
    SELECT COALESCE(json_agg(json_build_object(
               'tipo', CASE WHEN ua.id_salon IS NULL THEN 'locacion' ELSE 'salon' END,
               'id', COALESCE(ua.id_salon, ua.id_locacion),
               'nombre', COALESCE(s.nombre, l.nombre)
           ) ORDER BY (ua.id_salon IS NOT NULL), COALESCE(s.nombre, l.nombre)), '[]'::json)
    FROM usuario_area ua
    LEFT JOIN salon s ON s.id_salon = ua.id_salon
    LEFT JOIN locacion l ON l.id_locacion = ua.id_locacion
    WHERE ua.id_usuario = p_id_usuario;
$$;
