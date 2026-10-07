CREATE OR REPLACE FUNCTION fn_menu_disponible_evento(p_id_menu integer, p_id_evento integer) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    SELECT CASE
        WHEN m.es_personalizado THEN COALESCE(m.id_evento = p_id_evento, false)
        ELSE NOT EXISTS (SELECT 1 FROM menu_disponibilidad md WHERE md.id_menu = m.id_menu)
          OR EXISTS (
                SELECT 1
                FROM menu_disponibilidad md
                JOIN evento_salon es ON es.id_evento = p_id_evento
                JOIN salon s ON s.id_salon = es.id_salon
                WHERE md.id_menu = m.id_menu
                  AND (md.id_salon = s.id_salon OR md.id_locacion = s.id_locacion)
             )
    END
    FROM menu m
    WHERE m.id_menu = p_id_menu;
$$;
