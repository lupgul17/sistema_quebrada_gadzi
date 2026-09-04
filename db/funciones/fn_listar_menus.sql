CREATE OR REPLACE FUNCTION fn_listar_menus(p_id_tipo_menu INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_menu         INTEGER,
    nombre          VARCHAR,
    precio_base     DECIMAL,
    unidad_medida   VARCHAR,
    descripcion     TEXT,
    activo          BOOLEAN,
    id_tipo_menu    INTEGER,
    tipo_menu       VARCHAR,
    componentes     TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        m.id_menu, m.nombre, m.precio_base, m.unidad_medida, m.descripcion, m.activo,
        tm.id_tipo_menu, tm.descripcion AS tipo_menu,
        STRING_AGG(cm.nombre, ', ' ORDER BY cm.nombre) AS componentes
    FROM menu m
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    LEFT JOIN menu_componentes_menu mcm ON mcm.id_menu = m.id_menu
    LEFT JOIN componente_menu cm ON cm.id_componente = mcm.id_componente
    WHERE p_id_tipo_menu IS NULL OR m.id_tipo_menu = p_id_tipo_menu
    GROUP BY m.id_menu, tm.id_tipo_menu, tm.descripcion
    ORDER BY tm.descripcion, m.nombre;
$$;