CREATE OR REPLACE FUNCTION fn_evento_en_alcance(p_id_evento INTEGER, p_salones INTEGER[])
RETURNS BOOLEAN
LANGUAGE sql STABLE
AS $$
    SELECT p_id_evento IS NOT NULL AND (
        p_salones IS NULL
        OR EXISTS (SELECT 1 FROM evento_salon es WHERE es.id_evento = p_id_evento AND es.id_salon = ANY (p_salones))
    );
$$;
