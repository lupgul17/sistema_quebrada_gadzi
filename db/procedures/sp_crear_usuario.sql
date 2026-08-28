CREATE OR REPLACE PROCEDURE sp_crear_usuario(
    p_primer_nombre    VARCHAR,
    p_segundo_nombre   VARCHAR,
    p_primer_apellido  VARCHAR,
    p_segundo_apellido VARCHAR,
    p_cui              VARCHAR,
    p_nit              VARCHAR,
    p_telefono         VARCHAR,
    p_correo           VARCHAR,
    p_username         VARCHAR,
    p_password_hash    VARCHAR,
    p_id_tipo_usuario  INTEGER,
    p_id_tipo_empleado INTEGER,
    OUT p_id_usuario   INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_persona INTEGER;
BEGIN
    INSERT INTO persona (
        primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
        cui, nit, telefono, correo
    )
    VALUES (
        p_primer_nombre, p_segundo_nombre, p_primer_apellido, p_segundo_apellido,
        p_cui, p_nit, p_telefono, p_correo
    )
    RETURNING id_persona INTO v_id_persona;

    INSERT INTO empleado (id_persona, id_tipo_empleado)
    VALUES (v_id_persona, p_id_tipo_empleado);

    INSERT INTO usuario (id_persona, id_tipo_usuario, username, password_hash, confirmacion)
    VALUES (v_id_persona, p_id_tipo_usuario, p_username, p_password_hash, true)
    RETURNING id_usuario INTO p_id_usuario;
END;
$$;