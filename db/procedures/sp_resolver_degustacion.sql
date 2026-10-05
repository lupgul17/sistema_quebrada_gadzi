CREATE OR REPLACE PROCEDURE sp_resolver_degustacion(IN p_id_degustacion integer, IN p_resultado character varying, IN p_motivo_rechazo text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado VARCHAR;
BEGIN
    SELECT estado INTO v_estado FROM degustacion WHERE id_degustacion = p_id_degustacion;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe una degustacion con id = %', p_id_degustacion;
    END IF;

    IF v_estado <> 'realizada' THEN
        RAISE EXCEPTION 'Solo se puede registrar el resultado de una degustacion ya realizada (estado actual: %)', v_estado;
    END IF;

    IF p_resultado NOT IN ('aprobada', 'rechazada') THEN
        RAISE EXCEPTION 'Resultado invalido: %', p_resultado;
    END IF;

    IF p_resultado = 'rechazada' AND (p_motivo_rechazo IS NULL OR TRIM(p_motivo_rechazo) = '') THEN
        RAISE EXCEPTION 'El motivo de rechazo es obligatorio';
    END IF;

    UPDATE degustacion
    SET resultado = p_resultado,
        motivo_rechazo = CASE WHEN p_resultado = 'rechazada' THEN TRIM(p_motivo_rechazo) ELSE NULL END
    WHERE id_degustacion = p_id_degustacion;
END;
$$;
