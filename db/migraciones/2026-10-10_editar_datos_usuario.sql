-- =====================================================================================
-- Ver y editar los datos personales de un usuario
--
-- Hasta ahora en Usuarios solo se podía cambiar rol, áreas y estado. Esto agrega:
--   - fn_obtener_usuario: los datos de la persona detrás de un usuario (para el diálogo Editar).
--   - sp_editar_datos_usuario: actualiza nombres, CUI, teléfono y correo de esa persona.
-- No toca el NIT: si la persona también es cliente, su NIT se queda como está.
--
-- Correr TODO este archivo de una vez en el SQL Editor de Neon (va en una transacción).
-- =====================================================================================
BEGIN;

CREATE OR REPLACE FUNCTION fn_obtener_usuario(p_id_usuario INTEGER)
RETURNS TABLE(id_usuario integer, username character varying, primer_nombre character varying, segundo_nombre character varying,
              primer_apellido character varying, segundo_apellido character varying, cui character varying,
              telefono character varying, correo character varying, tipo_empleado character varying)
LANGUAGE sql STABLE
AS $$
    SELECT
        u.id_usuario, u.username,
        p.primer_nombre, p.segundo_nombre, p.primer_apellido, p.segundo_apellido,
        p.cui, p.telefono, p.correo,
        (SELECT te.descripcion
           FROM empleado e
           JOIN tc_tipo_empleado te ON te.id_tipo_empleado = e.id_tipo_empleado
          WHERE e.id_persona = u.id_persona
          ORDER BY e.id_empleado LIMIT 1) AS tipo_empleado
    FROM usuario u
    JOIN persona p ON p.id_persona = u.id_persona
    WHERE u.id_usuario = p_id_usuario;
$$;

CREATE OR REPLACE PROCEDURE sp_editar_datos_usuario(IN p_id_usuario integer, IN p_primer_nombre character varying, IN p_segundo_nombre character varying,
                                                    IN p_primer_apellido character varying, IN p_segundo_apellido character varying,
                                                    IN p_cui character varying, IN p_telefono character varying, IN p_correo character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_persona INTEGER;
BEGIN
    SELECT id_persona INTO v_id_persona FROM usuario WHERE id_usuario = p_id_usuario;

    IF v_id_persona IS NULL THEN
        RAISE EXCEPTION 'No existe el usuario con id = %', p_id_usuario;
    END IF;
    IF NULLIF(TRIM(p_primer_nombre), '') IS NULL OR NULLIF(TRIM(p_primer_apellido), '') IS NULL THEN
        RAISE EXCEPTION 'Primer nombre y primer apellido son obligatorios';
    END IF;

    UPDATE persona
    SET
        primer_nombre = TRIM(p_primer_nombre),
        segundo_nombre = NULLIF(TRIM(p_segundo_nombre), ''),
        primer_apellido = TRIM(p_primer_apellido),
        segundo_apellido = NULLIF(TRIM(p_segundo_apellido), ''),
        cui = NULLIF(TRIM(p_cui), ''),
        telefono = NULLIF(TRIM(p_telefono), ''),
        correo = NULLIF(TRIM(p_correo), '')
    WHERE id_persona = v_id_persona;
END;
$$;

COMMIT;
