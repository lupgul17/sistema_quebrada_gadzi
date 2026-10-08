CREATE OR REPLACE FUNCTION fn_listar_paquetes(
    p_id_evento   INTEGER DEFAULT NULL,  -- solo los activos que se pueden usar en ese evento
    p_id_paquete  INTEGER DEFAULT NULL   -- uno solo (detalle)
)
RETURNS TABLE (
    id_paquete          INTEGER,
    nombre              VARCHAR,
    descripcion         TEXT,
    precio_por_persona  NUMERIC,
    minimo_personas     INTEGER,
    horas_incluidas     INTEGER,
    id_tipo_menu        INTEGER,
    tipo_menu           VARCHAR,
    activo              BOOLEAN,
    grupos              JSON,   -- [{id, tipo, nombre, cantidad_a_elegir, opciones: [{id, nombre, categoria, detalle}]}]
    incluidos           JSON,   -- [{id_servicio, texto, nombre, cantidad, por_cada_personas}]
    extras              JSON,   -- [{id_servicio, nombre, unidad_medida, precio, precio_catalogo, calculo}]
    disponibilidad      JSON    -- [] = todos lados; si no, [{tipo, id, nombre}]
)
LANGUAGE sql STABLE
AS $$
    SELECT
        p.id_paquete, p.nombre, p.descripcion, p.precio_por_persona, p.minimo_personas, p.horas_incluidas,
        p.id_tipo_menu, tm.descripcion AS tipo_menu, p.activo,
        (
            SELECT COALESCE(json_agg(json_build_object(
                       'id', g.id_paquete_grupo,
                       'tipo', g.tipo,
                       'nombre', g.nombre,
                       'cantidad_a_elegir', g.cantidad_a_elegir,
                       'opciones', (
                           SELECT COALESCE(json_agg(json_build_object(
                                      'id', COALESCE(o.id_menu, o.id_componente, o.id_servicio),
                                      'nombre', COALESCE(m.nombre, cm.nombre, sv.nombre),
                                      -- menú: su tipo; componente: su categoría; cortesía: la del servicio
                                      'categoria', COALESCE(tmo.descripcion, cc.descripcion, cs.descripcion),
                                      -- menú: sus componentes, para ver qué trae cada opción
                                      'detalle', (SELECT string_agg(c2.nombre, ', ' ORDER BY c2.nombre)
                                                  FROM menu_componentes_menu mc
                                                  JOIN componente_menu c2 ON c2.id_componente = mc.id_componente
                                                  WHERE mc.id_menu = o.id_menu)
                                  ) ORDER BY o.id_paquete_grupo_opcion), '[]'::json)
                           FROM paquete_grupo_opcion o
                           LEFT JOIN menu m ON m.id_menu = o.id_menu
                           LEFT JOIN tc_tipo_menu tmo ON tmo.id_tipo_menu = m.id_tipo_menu
                           LEFT JOIN componente_menu cm ON cm.id_componente = o.id_componente
                           LEFT JOIN tc_categoria_componente_menu cc ON cc.id_categoria_componente_menu = cm.id_categoria_componente_menu
                           LEFT JOIN servicios sv ON sv.id_servicio = o.id_servicio
                           LEFT JOIN tc_categoria_servicio cs ON cs.id_categoria_servicio = sv.id_categoria_servicio
                           WHERE o.id_paquete_grupo = g.id_paquete_grupo
                       )
                   ) ORDER BY g.orden, g.id_paquete_grupo), '[]'::json)
            FROM paquete_grupo g
            WHERE g.id_paquete = p.id_paquete
        ) AS grupos,
        (
            SELECT COALESCE(json_agg(json_build_object(
                       'id_servicio', i.id_servicio, 'texto', i.texto, 'nombre', COALESCE(sv.nombre, i.texto),
                       'cantidad', i.cantidad, 'por_cada_personas', i.por_cada_personas
                   ) ORDER BY i.orden, i.id_paquete_incluido), '[]'::json)
            FROM paquete_incluido i
            LEFT JOIN servicios sv ON sv.id_servicio = i.id_servicio
            WHERE i.id_paquete = p.id_paquete
        ) AS incluidos,
        (
            SELECT COALESCE(json_agg(json_build_object(
                       'id_servicio', e.id_servicio, 'nombre', sv.nombre, 'unidad_medida', sv.unidad_medida,
                       'precio', e.precio, 'precio_catalogo', sv.precio_base, 'calculo', e.calculo
                   ) ORDER BY e.orden, sv.nombre), '[]'::json)
            FROM paquete_extra e
            JOIN servicios sv ON sv.id_servicio = e.id_servicio
            WHERE e.id_paquete = p.id_paquete
        ) AS extras,
        (
            SELECT COALESCE(json_agg(json_build_object(
                       'tipo', CASE WHEN pd.id_salon IS NULL THEN 'locacion' ELSE 'salon' END,
                       'id', COALESCE(pd.id_salon, pd.id_locacion),
                       'nombre', COALESCE(sa.nombre, lo.nombre)
                   ) ORDER BY (pd.id_salon IS NOT NULL), COALESCE(sa.nombre, lo.nombre)), '[]'::json)
            FROM paquete_disponibilidad pd
            LEFT JOIN salon sa ON sa.id_salon = pd.id_salon
            LEFT JOIN locacion lo ON lo.id_locacion = pd.id_locacion
            WHERE pd.id_paquete = p.id_paquete
        ) AS disponibilidad
    FROM paquete p
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = p.id_tipo_menu
    WHERE (p_id_paquete IS NULL OR p.id_paquete = p_id_paquete)
      AND (p_id_evento IS NULL OR (p.activo AND fn_paquete_disponible_evento(p.id_paquete, p_id_evento)))
    ORDER BY p.nombre, p.precio_por_persona;
$$;
