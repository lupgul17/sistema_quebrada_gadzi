CREATE OR REPLACE PROCEDURE sp_crear_cotizacion(
    p_id_evento          INTEGER,
    p_vigencia_dias      INTEGER,
    p_deposito_garantia  DECIMAL,
    p_id_empleado        INTEGER,
    OUT p_id_cotizacion  INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nueva_version INTEGER;
BEGIN
    -- Desactivar la version activa anterior, si existe
    UPDATE cotizacion
    SET activa = false,
        id_estado_cotizacion = (SELECT id_estado_cotizacion FROM tc_estado_cotizacion WHERE descripcion = 'reemplazada')
    WHERE id_evento = p_id_evento AND activa = true;

    SELECT COALESCE(MAX(version), 0) + 1 INTO v_nueva_version
    FROM cotizacion WHERE id_evento = p_id_evento;

    INSERT INTO cotizacion (id_evento, version, fecha_cotizacion, vigencia_dias, deposito_garantia, activa, id_estado_cotizacion, id_empleado)
    VALUES (
        p_id_evento, v_nueva_version, CURRENT_DATE, p_vigencia_dias, p_deposito_garantia, true,
        (SELECT id_estado_cotizacion FROM tc_estado_cotizacion WHERE descripcion = 'estimada'),
        p_id_empleado
    )
    RETURNING id_cotizacion INTO p_id_cotizacion;
END;
$$;