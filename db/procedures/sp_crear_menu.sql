CREATE OR REPLACE PROCEDURE sp_crear_menu(
    p_nombre         VARCHAR,
    p_id_tipo_menu   INTEGER,
    p_precio_base    DECIMAL,
    p_unidad_medida  VARCHAR,
    p_descripcion    TEXT,
    p_componentes    INTEGER[],
    OUT p_id_menu    INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_componente INTEGER;
BEGIN
    INSERT INTO menu (nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, activo)
    VALUES (p_nombre, p_id_tipo_menu, p_precio_base, p_unidad_medida, p_descripcion, true)
    RETURNING id_menu INTO p_id_menu;

    FOREACH v_id_componente IN ARRAY p_componentes
    LOOP
        INSERT INTO menu_componentes_menu (id_menu, id_componente)
        VALUES (p_id_menu, v_id_componente);
    END LOOP;
END;
$$;