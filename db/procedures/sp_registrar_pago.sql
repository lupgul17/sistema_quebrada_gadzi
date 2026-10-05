CREATE OR REPLACE PROCEDURE sp_registrar_pago(IN p_id_evento integer, IN p_fecha_pago date, IN p_monto numeric, IN p_id_tipo_pago integer, IN p_concepto character varying, IN p_origen character varying, IN p_id_empleado integer, IN p_path_comprobante character varying, IN p_notas text, OUT p_id_pago integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO pago (
        id_evento, fecha_pago, monto, id_tipo_pago, concepto,
        id_empleado, estado, origen, path_comprobante, notas
    )
    VALUES (
        p_id_evento, p_fecha_pago, p_monto, p_id_tipo_pago, p_concepto,
        p_id_empleado, 'pendiente', p_origen, p_path_comprobante, p_notas
    )
    RETURNING id_pago INTO p_id_pago;
END;
$$;
