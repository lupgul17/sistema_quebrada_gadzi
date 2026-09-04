CREATE OR REPLACE PROCEDURE sp_agregar_menu_degustacion(
    p_id_degustacion            INTEGER,
    p_id_menu                   INTEGER,
    OUT p_id_degustacion_menu   INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO degustacion_menu (id_degustacion, id_menu, resultado)
    VALUES (p_id_degustacion, p_id_menu, 'pendiente')
    RETURNING id_degustacion_menu INTO p_id_degustacion_menu;
END;
$$;