CREATE OR REPLACE PROCEDURE sp_guardar_areas_usuario(p_id_usuario INTEGER, p_locaciones INTEGER[], p_salones INTEGER[])
LANGUAGE plpgsql
AS $$
DECLARE
    v_loc INTEGER[] := COALESCE(p_locaciones, '{}');
    v_sal INTEGER[] := COALESCE(p_salones, '{}');
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario) THEN
        RAISE EXCEPTION 'No existe el usuario con id = %', p_id_usuario;
    END IF;
    IF EXISTS (SELECT 1 FROM UNNEST(v_loc) x WHERE NOT EXISTS (SELECT 1 FROM locacion l WHERE l.id_locacion = x)) THEN
        RAISE EXCEPTION 'Alguna de las locaciones elegidas no existe';
    END IF;
    IF EXISTS (SELECT 1 FROM UNNEST(v_sal) x WHERE NOT EXISTS (SELECT 1 FROM salon s WHERE s.id_salon = x)) THEN
        RAISE EXCEPTION 'Alguno de los salones elegidos no existe';
    END IF;

    DELETE FROM usuario_area WHERE id_usuario = p_id_usuario;
    INSERT INTO usuario_area (id_usuario, id_locacion) SELECT DISTINCT p_id_usuario, x FROM UNNEST(v_loc) x;
    INSERT INTO usuario_area (id_usuario, id_salon)
    SELECT DISTINCT p_id_usuario, s.id_salon
    FROM UNNEST(v_sal) x JOIN salon s ON s.id_salon = x
    WHERE NOT (s.id_locacion = ANY (v_loc));
END;
$$;
