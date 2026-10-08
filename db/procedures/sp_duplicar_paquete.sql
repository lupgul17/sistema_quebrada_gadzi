CREATE OR REPLACE PROCEDURE sp_duplicar_paquete(
    p_id_paquete           INTEGER,
    p_nombre               VARCHAR,
    p_precio_por_persona   NUMERIC,
    p_locaciones           INTEGER[],
    p_salones              INTEGER[],
    OUT p_id_paquete_nuevo INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_original paquete%ROWTYPE;
    v_grupo    RECORD;
    v_nuevo_g  INTEGER;
    v_loc      INTEGER[] := COALESCE(p_locaciones, '{}');
BEGIN
    SELECT * INTO v_original FROM paquete WHERE id_paquete = p_id_paquete;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el paquete con id = %', p_id_paquete;
    END IF;
    IF p_precio_por_persona IS NOT NULL AND p_precio_por_persona <= 0 THEN
        RAISE EXCEPTION 'El precio por persona debe ser mayor a cero';
    END IF;

    INSERT INTO paquete (nombre, descripcion, precio_por_persona, minimo_personas, horas_incluidas, id_tipo_menu, activo)
    VALUES (COALESCE(NULLIF(TRIM(p_nombre), ''), v_original.nombre), v_original.descripcion,
            COALESCE(p_precio_por_persona, v_original.precio_por_persona), v_original.minimo_personas,
            v_original.horas_incluidas, v_original.id_tipo_menu, true)
    RETURNING id_paquete INTO p_id_paquete_nuevo;

    FOR v_grupo IN SELECT * FROM paquete_grupo WHERE id_paquete = p_id_paquete ORDER BY orden LOOP
        INSERT INTO paquete_grupo (id_paquete, tipo, nombre, cantidad_a_elegir, orden)
        VALUES (p_id_paquete_nuevo, v_grupo.tipo, v_grupo.nombre, v_grupo.cantidad_a_elegir, v_grupo.orden)
        RETURNING id_paquete_grupo INTO v_nuevo_g;
        INSERT INTO paquete_grupo_opcion (id_paquete_grupo, id_menu, id_componente, id_servicio)
        SELECT v_nuevo_g, id_menu, id_componente, id_servicio FROM paquete_grupo_opcion
        WHERE id_paquete_grupo = v_grupo.id_paquete_grupo ORDER BY id_paquete_grupo_opcion;
    END LOOP;

    INSERT INTO paquete_incluido (id_paquete, id_servicio, texto, cantidad, por_cada_personas, orden)
    SELECT p_id_paquete_nuevo, id_servicio, texto, cantidad, por_cada_personas, orden
    FROM paquete_incluido WHERE id_paquete = p_id_paquete;

    -- Los precios de los extras se copian igual; si en la otra área cambian, se editan después
    INSERT INTO paquete_extra (id_paquete, id_servicio, precio, calculo, orden)
    SELECT p_id_paquete_nuevo, id_servicio, precio, calculo, orden FROM paquete_extra WHERE id_paquete = p_id_paquete;

    INSERT INTO paquete_disponibilidad (id_paquete, id_locacion)
    SELECT DISTINCT p_id_paquete_nuevo, x FROM UNNEST(v_loc) x;
    INSERT INTO paquete_disponibilidad (id_paquete, id_salon)
    SELECT DISTINCT p_id_paquete_nuevo, s.id_salon
    FROM UNNEST(COALESCE(p_salones, '{}')) x JOIN salon s ON s.id_salon = x
    WHERE NOT (s.id_locacion = ANY (v_loc));
END;
$$;
