CREATE OR REPLACE PROCEDURE sp_verificar_pago(IN p_id_pago integer, IN p_nuevo_estado character varying, IN p_id_empleado integer, IN p_motivo_rechazo text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_actual VARCHAR;
BEGIN
    SELECT estado INTO v_estado_actual FROM pago WHERE id_pago = p_id_pago;

    IF v_estado_actual IS NULL THEN
        RAISE EXCEPTION 'No existe un pago con id_pago = %', p_id_pago;
    END IF;

    IF v_estado_actual != 'pendiente' THEN
        RAISE EXCEPTION 'Este pago ya fue % y no se puede modificar', v_estado_actual;
    END IF;

    IF p_nuevo_estado NOT IN ('verificado', 'rechazado') THEN
        RAISE EXCEPTION 'Estado invalido: %', p_nuevo_estado;
    END IF;

    IF p_nuevo_estado = 'rechazado' AND (p_motivo_rechazo IS NULL OR TRIM(p_motivo_rechazo) = '') THEN
        RAISE EXCEPTION 'Hace falta indicar el motivo del rechazo';
    END IF;

    UPDATE pago
    SET estado = p_nuevo_estado,
        id_empleado = p_id_empleado,
        motivo_rechazo = CASE WHEN p_nuevo_estado = 'rechazado' THEN p_motivo_rechazo ELSE NULL END
    WHERE id_pago = p_id_pago;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;
