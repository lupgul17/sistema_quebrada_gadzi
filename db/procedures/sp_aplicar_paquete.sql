-- p_extras: [{"id_servicio": 7, "cantidad": 2}] (solo los extras que el cliente quiere)
CREATE OR REPLACE PROCEDURE sp_aplicar_paquete(
    p_id_evento             INTEGER,
    p_id_paquete            INTEGER,
    p_menus                 INTEGER[],  -- menús elegidos en los grupos de menús
    p_componentes           INTEGER[],  -- componentes elegidos en los grupos de componentes
    p_cortesias             INTEGER[],  -- servicios elegidos en los grupos de cortesía
    p_extras                JSONB,
    p_cantidad              INTEGER,    -- NULL = adultos del evento
    p_deposito_garantia     NUMERIC,
    p_id_empleado           INTEGER,
    p_id_usuario_autoriza   INTEGER,    -- obligatorio si la cantidad es menor al mínimo
    OUT p_id_cotizacion     INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_paquete    paquete%ROWTYPE;
    v_cantidad   INTEGER := p_cantidad;
    v_personas   INTEGER;
    v_grupo      RECORD;
    v_elegidos   INTEGER;
    v_menus      INTEGER[] := (SELECT ARRAY(SELECT DISTINCT x FROM UNNEST(COALESCE(p_menus, '{}')) x));
    v_comp       INTEGER[] := (SELECT ARRAY(SELECT DISTINCT x FROM UNNEST(COALESCE(p_componentes, '{}')) x));
    v_cort       INTEGER[] := (SELECT ARRAY(SELECT DISTINCT x FROM UNNEST(COALESCE(p_cortesias, '{}')) x));
    v_extras     JSONB := COALESCE(p_extras, '[]'::jsonb);
    v_id_menu    INTEGER;
    v_elecciones TEXT;
    v_linea      INTEGER;
    v_rol        VARCHAR;
BEGIN
    SELECT * INTO v_paquete FROM paquete WHERE id_paquete = p_id_paquete;
    IF NOT FOUND OR NOT v_paquete.activo THEN
        RAISE EXCEPTION 'El paquete no existe o está inactivo';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM evento WHERE id_evento = p_id_evento) THEN
        RAISE EXCEPTION 'No existe el evento con id = %', p_id_evento;
    END IF;
    IF NOT fn_paquete_disponible_evento(p_id_paquete, p_id_evento) THEN
        RAISE EXCEPTION 'Este paquete no se ofrece en los salones de este evento';
    END IF;

    IF v_cantidad IS NULL THEN
        SELECT total_adultos INTO v_cantidad FROM evento WHERE id_evento = p_id_evento;
    END IF;
    IF v_cantidad IS NULL OR v_cantidad <= 0 THEN
        RAISE EXCEPTION 'Indicá la cantidad de personas (el evento no tiene adultos registrados)';
    END IF;
    -- Para "1 por cada N personas" cuentan todos los invitados (los niños van aparte en el precio)
    SELECT v_cantidad + COALESCE(total_menores, 0) INTO v_personas FROM evento WHERE id_evento = p_id_evento;

    -- Bajo el mínimo: solo con autorización de Administrador o Superusuario
    IF v_cantidad < v_paquete.minimo_personas THEN
        IF p_id_usuario_autoriza IS NULL THEN
            RAISE EXCEPTION 'El paquete es para mínimo % personas y el evento tiene %: hace falta la autorización de un administrador',
                v_paquete.minimo_personas, v_cantidad;
        END IF;
        SELECT ra.descripcion INTO v_rol
        FROM usuario u JOIN tc_rol_acceso ra ON ra.id_rol_acceso = u.id_rol_acceso
        WHERE u.id_usuario = p_id_usuario_autoriza AND u.activo;
        IF v_rol IS NULL OR v_rol NOT IN ('Administrador', 'Superusuario') THEN
            RAISE EXCEPTION 'Solo un Administrador o Superusuario puede autorizar el paquete bajo el mínimo';
        END IF;
    END IF;

    -- Cada grupo con la cantidad exacta de opciones elegidas
    FOR v_grupo IN SELECT * FROM paquete_grupo WHERE id_paquete = p_id_paquete ORDER BY orden LOOP
        SELECT COUNT(*) INTO v_elegidos
        FROM paquete_grupo_opcion o
        WHERE o.id_paquete_grupo = v_grupo.id_paquete_grupo
          AND CASE v_grupo.tipo
                  WHEN 'menu' THEN o.id_menu = ANY(v_menus)
                  WHEN 'componente' THEN o.id_componente = ANY(v_comp)
                  ELSE o.id_servicio = ANY(v_cort)
              END;
        IF v_elegidos <> v_grupo.cantidad_a_elegir THEN
            RAISE EXCEPTION 'En "%" hay que elegir % opción(es)', v_grupo.nombre, v_grupo.cantidad_a_elegir;
        END IF;
    END LOOP;
    -- ...y nada que no sea del paquete
    IF EXISTS (SELECT 1 FROM UNNEST(v_menus) x WHERE NOT EXISTS (
                   SELECT 1 FROM paquete_grupo g JOIN paquete_grupo_opcion o ON o.id_paquete_grupo = g.id_paquete_grupo
                   WHERE g.id_paquete = p_id_paquete AND g.tipo = 'menu' AND o.id_menu = x))
       OR EXISTS (SELECT 1 FROM UNNEST(v_comp) x WHERE NOT EXISTS (
                   SELECT 1 FROM paquete_grupo g JOIN paquete_grupo_opcion o ON o.id_paquete_grupo = g.id_paquete_grupo
                   WHERE g.id_paquete = p_id_paquete AND g.tipo = 'componente' AND o.id_componente = x))
       OR EXISTS (SELECT 1 FROM UNNEST(v_cort) x WHERE NOT EXISTS (
                   SELECT 1 FROM paquete_grupo g JOIN paquete_grupo_opcion o ON o.id_paquete_grupo = g.id_paquete_grupo
                   WHERE g.id_paquete = p_id_paquete AND g.tipo = 'cortesia' AND o.id_servicio = x))
    THEN
        RAISE EXCEPTION 'Se eligió una opción que no pertenece al paquete';
    END IF;

    -- Extras: solo los del paquete, con cantidad válida y sin repetir
    IF EXISTS (
        SELECT 1 FROM jsonb_array_elements(v_extras) e
        WHERE NOT EXISTS (SELECT 1 FROM paquete_extra pe
                          WHERE pe.id_paquete = p_id_paquete AND pe.id_servicio = (e->>'id_servicio')::INTEGER)
           OR COALESCE((e->>'cantidad')::INTEGER, 0) <= 0
    ) THEN
        RAISE EXCEPTION 'Algún extra no es de este paquete o no tiene cantidad';
    END IF;
    IF (SELECT COUNT(*) FROM jsonb_array_elements(v_extras))
       <> (SELECT COUNT(DISTINCT e->>'id_servicio') FROM jsonb_array_elements(v_extras) e) THEN
        RAISE EXCEPTION 'Un extra está repetido';
    END IF;

    -- Nueva versión de la cotización (la anterior queda como reemplazada)
    CALL sp_crear_cotizacion(p_id_evento, 8, COALESCE(p_deposito_garantia, 0), p_id_empleado, p_id_cotizacion);

    -- La nueva versión hereda las líneas de la anterior: el paquete las reemplaza, salvo los
    -- platillos extra de degustación (se cobran aparte y siguen vinculados a la degustación)
    DELETE FROM cotizacion_menu cm
    WHERE cm.id_cotizacion = p_id_cotizacion
      AND NOT EXISTS (SELECT 1 FROM degustacion_menu dm WHERE dm.id_cotizacion_menu = cm.id_cotizacion_menu);
    DELETE FROM cotizacion_servicios WHERE id_cotizacion = p_id_cotizacion;

    -- Lo elegido en texto, en el orden de los grupos: "Milanesa de pollo · Jamaica · 3 tortillas"
    SELECT string_agg(COALESCE(m.nombre, c.nombre), ' · ' ORDER BY g.orden, o.id_paquete_grupo_opcion) INTO v_elecciones
    FROM paquete_grupo g
    JOIN paquete_grupo_opcion o ON o.id_paquete_grupo = g.id_paquete_grupo
    LEFT JOIN menu m ON m.id_menu = o.id_menu
    LEFT JOIN componente_menu c ON c.id_componente = o.id_componente
    WHERE g.id_paquete = p_id_paquete
      AND ((g.tipo = 'menu' AND o.id_menu = ANY(v_menus)) OR (g.tipo = 'componente' AND o.id_componente = ANY(v_comp)));

    -- Línea del paquete: un menú a medida del evento con los componentes de los menús elegidos más
    -- los componentes elegidos, a precio fijo por persona (los precios de cada menú no cuentan)
    INSERT INTO menu (nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, activo, es_personalizado, id_evento)
    VALUES ('Paquete ' || v_paquete.nombre, v_paquete.id_tipo_menu, v_paquete.precio_por_persona, 'por_persona',
            v_elecciones, true, true, p_id_evento)
    RETURNING id_menu INTO v_id_menu;
    INSERT INTO menu_componentes_menu (id_menu, id_componente)
    SELECT DISTINCT v_id_menu, x.id_componente
    FROM (SELECT mc.id_componente FROM menu_componentes_menu mc WHERE mc.id_menu = ANY(v_menus)
          UNION SELECT UNNEST(v_comp)) x;
    CALL sp_agregar_menu_cotizacion(p_id_cotizacion, v_id_menu, v_cantidad, v_linea);

    INSERT INTO paquete_aplicado (id_menu, id_paquete, elecciones, incluye, horas_incluidas)
    VALUES (v_id_menu, p_id_paquete, v_elecciones,
            (SELECT COALESCE(jsonb_agg(i.texto ORDER BY i.orden), '[]'::jsonb)
             FROM paquete_incluido i WHERE i.id_paquete = p_id_paquete AND i.texto IS NOT NULL),
            v_paquete.horas_incluidas);

    -- Servicios incluidos y cortesías: a Q0 (ya van en el precio por persona)
    INSERT INTO cotizacion_servicios (id_cotizacion, id_servicio, cantidad, precio_unitario_congelado, subtotal)
    SELECT p_id_cotizacion, i.id_servicio,
           CASE WHEN i.por_cada_personas IS NULL THEN i.cantidad
                ELSE i.cantidad * CEIL(v_personas::NUMERIC / i.por_cada_personas)::INTEGER END,
           0, 0
    FROM paquete_incluido i
    WHERE i.id_paquete = p_id_paquete AND i.id_servicio IS NOT NULL
    ORDER BY i.orden;
    INSERT INTO cotizacion_servicios (id_cotizacion, id_servicio, cantidad, precio_unitario_congelado, subtotal)
    SELECT p_id_cotizacion, x, 1, 0, 0 FROM UNNEST(v_cort) x;

    -- Extras elegidos: con el precio especial del paquete
    INSERT INTO cotizacion_servicios (id_cotizacion, id_servicio, cantidad, precio_unitario_congelado, subtotal)
    SELECT p_id_cotizacion, pe.id_servicio, (e->>'cantidad')::INTEGER, pe.precio, pe.precio * (e->>'cantidad')::INTEGER
    FROM jsonb_array_elements(v_extras) e
    JOIN paquete_extra pe ON pe.id_paquete = p_id_paquete AND pe.id_servicio = (e->>'id_servicio')::INTEGER
    ORDER BY pe.orden;

    UPDATE cotizacion
    SET id_paquete = p_id_paquete,
        id_usuario_autoriza_minimo = CASE WHEN v_cantidad < v_paquete.minimo_personas THEN p_id_usuario_autoriza END
    WHERE id_cotizacion = p_id_cotizacion;

    CALL sp_refrescar_totales_cotizacion(p_id_cotizacion);
END;
$$;
