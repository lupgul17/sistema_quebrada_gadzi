CREATE OR REPLACE PROCEDURE sp_registrar_pago(
    p_id_evento         INTEGER,
    p_fecha_pago        DATE,
    p_monto             DECIMAL,
    p_id_tipo_pago      INTEGER,
    p_concepto          VARCHAR,
    p_origen            VARCHAR,
    p_id_empleado       INTEGER,
    p_path_comprobante  VARCHAR,
    p_notas             TEXT,
    OUT p_id_pago       INTEGER
)
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