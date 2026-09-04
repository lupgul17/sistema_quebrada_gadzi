CREATE OR REPLACE FUNCTION fn_listar_componentes_menu(p_id_categoria INTEGER DEFAULT NULL)
RETURNS TABLE (
    id_componente                   INTEGER,
    nombre                          VARCHAR,
    recargo                         DECIMAL,
    activo                          BOOLEAN,
    id_categoria_componente_menu   INTEGER,
    categoria                       VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        cm.id_componente,
        cm.nombre,
        cm.recargo,
        cm.activo,
        cc.id_categoria_componente_menu,
        cc.descripcion AS categoria
    FROM componente_menu cm
    JOIN tc_categoria_componente_menu cc ON cc.id_categoria_componente_menu = cm.id_categoria_componente_menu
    WHERE p_id_categoria IS NULL OR cm.id_categoria_componente_menu = p_id_categoria
    ORDER BY cc.descripcion, cm.nombre;
$$;