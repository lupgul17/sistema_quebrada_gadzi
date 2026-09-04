CREATE OR REPLACE PROCEDURE sp_editar_componente_menu(
    p_id_componente                  INTEGER,
    p_id_categoria_componente_menu   INTEGER,
    p_nombre                         VARCHAR,
    p_recargo                        DECIMAL,
    p_activo                         BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM componente_menu WHERE id_componente = p_id_componente) THEN
        RAISE EXCEPTION 'No existe un componente con id_componente = %', p_id_componente;
    END IF;

    UPDATE componente_menu
    SET id_categoria_componente_menu = p_id_categoria_componente_menu,
        nombre = p_nombre,
        recargo = p_recargo,
        activo = p_activo
    WHERE id_componente = p_id_componente;
END;
$$;