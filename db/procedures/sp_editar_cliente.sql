CREATE OR REPLACE PROCEDURE sp_editar_cliente(
    p_id_cliente       INTEGER,
    p_primer_nombre    VARCHAR,
    p_segundo_nombre   VARCHAR,
    p_primer_apellido  VARCHAR,
    p_segundo_apellido VARCHAR,
    p_cui              VARCHAR,
    p_nit              VARCHAR,
    p_telefono         VARCHAR,
    p_correo           VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_persona INTEGER;
BEGIN
    SELECT id_persona INTO v_id_persona
    FROM cliente
    WHERE id_cliente = p_id_cliente;

    IF v_id_persona IS NULL THEN
        RAISE EXCEPTION 'No existe un cliente con id_cliente = %', p_id_cliente;
    END IF;

    UPDATE persona
    SET
        primer_nombre = p_primer_nombre,
        segundo_nombre = p_segundo_nombre,
        primer_apellido = p_primer_apellido,
        segundo_apellido = p_segundo_apellido,
        cui = p_cui,
        nit = p_nit,
        telefono = p_telefono,
        correo = p_correo
    WHERE id_persona = v_id_persona;
END;
$$;