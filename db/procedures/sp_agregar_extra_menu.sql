CREATE OR REPLACE FUNCTION sp_agregar_extra_menu(
    p_id_evento INTEGER,
    p_id_menu INTEGER,
    p_descripcion TEXT,            -- puede ser NULL
    p_cantidad INTEGER,
    p_precio_base NUMERIC,
    p_id_empleado INTEGER,
    OUT p_id_extras_menu INTEGER
) AS $$
DECLARE
    v_id_extra INTEGER;
    v_subtotal NUMERIC;
BEGIN
    INSERT INTO extras (id_evento, id_empleado)
    VALUES (p_id_evento, p_id_empleado)
    ON CONFLICT (id_evento) DO NOTHING;

    SELECT id_extra INTO v_id_extra
    FROM extras
    WHERE id_evento = p_id_evento;

    v_subtotal := p_cantidad * p_precio_base;

    INSERT INTO extras_menu (
        id_extra, id_menu, descripcion, cantidad, precio_base, subtotal, estado
    ) VALUES (
        v_id_extra, p_id_menu, p_descripcion, p_cantidad, p_precio_base, v_subtotal, 'aprobado'
    )
    RETURNING id_extras_menu INTO p_id_extras_menu;

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
END;
$$ LANGUAGE plpgsql;