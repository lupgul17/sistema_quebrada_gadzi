CREATE OR REPLACE PROCEDURE sp_resolver_menu_degustacion(
    p_id_degustacion_menu  INTEGER,
    p_resultado            VARCHAR,
    p_notas                TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM degustacion_menu WHERE id_degustacion_menu = p_id_degustacion_menu) THEN
        RAISE EXCEPTION 'No existe una linea de degustacion_menu con id = %', p_id_degustacion_menu;
    END IF;

    IF p_resultado NOT IN ('pendiente', 'aprobado', 'rechazado') THEN
        RAISE EXCEPTION 'Resultado invalido: %', p_resultado;
    END IF;

    UPDATE degustacion_menu
    SET resultado = p_resultado,
        notas = p_notas
    WHERE id_degustacion_menu = p_id_degustacion_menu;
END;
$$;