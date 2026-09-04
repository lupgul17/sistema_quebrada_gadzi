CREATE OR REPLACE PROCEDURE sp_editar_menu(
    p_id_menu        INTEGER,
    p_nombre         VARCHAR,
    p_id_tipo_menu   INTEGER,
    p_precio_base    DECIMAL,
    p_unidad_medida  VARCHAR,
    p_descripcion    TEXT,
    p_activo         BOOLEAN,
    p_componentes    INTEGER[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_componente INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM menu WHERE id_menu = p_id_menu) THEN
        RAISE EXCEPTION 'No existe un menu con id_menu = %', p_id_menu;
    END IF;

    UPDATE menu
    SET nombre = p_nombre, id_tipo_menu = p_id_tipo_menu, precio_base = p_precio_base,
        unidad_medida = p_unidad_medida, descripcion = p_descripcion, activo = p_activo
    WHERE id_menu = p_id_menu;

    DELETE FROM menu_componentes_menu WHERE id_menu = p_id_menu;

    FOREACH v_id_componente IN ARRAY p_componentes
    LOOP
        INSERT INTO menu_componentes_menu (id_menu, id_componente)
        VALUES (p_id_menu, v_id_componente);
    END LOOP;
END;
$$;