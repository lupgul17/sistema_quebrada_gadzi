CREATE OR REPLACE PROCEDURE sp_cambiar_estado_cotizacion(
    p_id_cotizacion  INTEGER,
    p_nuevo_estado   VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_actual VARCHAR;
BEGIN
    SELECT ec.descripcion INTO v_estado_actual
    FROM cotizacion c JOIN tc_estado_cotizacion ec ON ec.id_estado_cotizacion = c.id_estado_cotizacion
    WHERE c.id_cotizacion = p_id_cotizacion;

    IF v_estado_actual IS NULL THEN
        RAISE EXCEPTION 'No existe una cotizacion con id_cotizacion = %', p_id_cotizacion;
    END IF;

    IF NOT (
        (v_estado_actual = 'estimada' AND p_nuevo_estado = 'enviada')
        OR (v_estado_actual = 'enviada' AND p_nuevo_estado IN ('aceptada', 'vencida'))
    ) THEN
        RAISE EXCEPTION 'No se puede pasar de % a %', v_estado_actual, p_nuevo_estado;
    END IF;

    UPDATE cotizacion
    SET id_estado_cotizacion = (SELECT id_estado_cotizacion FROM tc_estado_cotizacion WHERE descripcion = p_nuevo_estado)
    WHERE id_cotizacion = p_id_cotizacion;
END;
$$;