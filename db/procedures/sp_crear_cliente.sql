CREATE OR REPLACE PROCEDURE sp_crear_cliente(
    p_primer_nombre    VARCHAR,
    p_segundo_nombre   VARCHAR,
    p_primer_apellido  VARCHAR,
    p_segundo_apellido VARCHAR,
    p_cui              VARCHAR,
    p_nit              VARCHAR,
    p_telefono         VARCHAR,
    p_correo           VARCHAR,
    OUT p_id_cliente   INTEGER
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

    INSERT INTO cliente (id_persona)
    VALUES (v_id_persona)
    RETURNING id_cliente INTO p_id_cliente;
END;
$$;