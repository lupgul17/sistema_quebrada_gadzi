CREATE OR REPLACE FUNCTION fn_paquete_disponible_evento(p_id_paquete INTEGER, p_id_evento INTEGER)
RETURNS BOOLEAN
LANGUAGE sql STABLE
AS $$
    SELECT NOT EXISTS (SELECT 1 FROM paquete_disponibilidad pd WHERE pd.id_paquete = p_id_paquete)
        OR EXISTS (
            SELECT 1
            FROM paquete_disponibilidad pd
            JOIN evento_salon es ON es.id_evento = p_id_evento
            JOIN salon s ON s.id_salon = es.id_salon
            WHERE pd.id_paquete = p_id_paquete
              AND (pd.id_salon = s.id_salon OR pd.id_locacion = s.id_locacion)
        );
$$;
