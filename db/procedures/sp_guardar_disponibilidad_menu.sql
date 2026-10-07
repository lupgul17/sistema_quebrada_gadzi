CREATE OR REPLACE PROCEDURE sp_guardar_disponibilidad_menu(IN p_id_menu integer, IN p_locaciones integer[], IN p_salones integer[])
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_locaciones INTEGER[] := COALESCE(p_locaciones, '{}');
    v_salones    INTEGER[] := COALESCE(p_salones, '{}');
BEGIN
    IF EXISTS (SELECT 1 FROM UNNEST(v_locaciones) x WHERE NOT EXISTS (SELECT 1 FROM locacion l WHERE l.id_locacion = x)) THEN
        RAISE EXCEPTION 'Alguna de las locaciones elegidas no existe';
    END IF;
    IF EXISTS (SELECT 1 FROM UNNEST(v_salones) x WHERE NOT EXISTS (SELECT 1 FROM salon s WHERE s.id_salon = x)) THEN
        RAISE EXCEPTION 'Alguno de los salones elegidos no existe';
    END IF;

    DELETE FROM menu_disponibilidad WHERE id_menu = p_id_menu;

    INSERT INTO menu_disponibilidad (id_menu, id_locacion)
    SELECT DISTINCT p_id_menu, x FROM UNNEST(v_locaciones) x;

    -- Un salón cuya locación completa ya está marcada sobra: no se guarda
    INSERT INTO menu_disponibilidad (id_menu, id_salon)
    SELECT DISTINCT p_id_menu, s.id_salon
    FROM UNNEST(v_salones) x
    JOIN salon s ON s.id_salon = x
    WHERE NOT (s.id_locacion = ANY (v_locaciones));
END;
$$;
