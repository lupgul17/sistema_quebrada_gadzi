CREATE OR REPLACE FUNCTION fn_listar_menus_degustacion(p_id_degustacion INTEGER)
RETURNS TABLE (
    id_degustacion_menu  INTEGER,
    id_menu              INTEGER,
    menu                 VARCHAR,
    tipo_menu            VARCHAR,
    resultado            VARCHAR,
    notas                TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        dm.id_degustacion_menu, dm.id_menu, m.nombre AS menu, tm.descripcion AS tipo_menu, dm.resultado, dm.notas
    FROM degustacion_menu dm
    JOIN menu m ON m.id_menu = dm.id_menu
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    WHERE dm.id_degustacion = p_id_degustacion
    ORDER BY m.nombre;
$$;