CREATE OR REPLACE FUNCTION sp_cancelar_extra(
    p_tipo VARCHAR,           -- 'servicio' o 'menu'
    p_id_linea INTEGER,       -- id_extras_servicios o id_extras_menu según el tipo
    OUT p_ok BOOLEAN
) AS $$
DECLARE
    v_id_extra INTEGER;
BEGIN
    IF p_tipo = 'servicio' THEN
        UPDATE extras_servicios
        SET estado = 'cancelado'
        WHERE id_extras_servicios = p_id_linea AND estado != 'cancelado'
        RETURNING id_extra INTO v_id_extra;
    ELSIF p_tipo = 'menu' THEN
        UPDATE extras_menu
        SET estado = 'cancelado'
        WHERE id_extras_menu = p_id_linea AND estado != 'cancelado'
        RETURNING id_extra INTO v_id_extra;
    ELSE
        RAISE EXCEPTION 'Tipo de extra inválido: %', p_tipo;
    END IF;

    IF v_id_extra IS NULL THEN
        p_ok := FALSE;
        RETURN;
    END IF;

    UPDATE extras
    SET total = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM extras_servicios
        WHERE id_extra = v_id_extra AND estado != 'cancelado'
    ) + (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM extras_menu
        WHERE id_extra = v_id_extra AND estado != 'cancelado'
    )
    WHERE id_extra = v_id_extra;

    p_ok := TRUE;
END;
$$ LANGUAGE plpgsql;