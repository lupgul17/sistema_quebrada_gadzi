CREATE OR REPLACE PROCEDURE sp_editar_cliente(IN p_id_cliente integer, IN p_primer_nombre character varying, IN p_segundo_nombre character varying, IN p_primer_apellido character varying, IN p_segundo_apellido character varying, IN p_cui character varying, IN p_nit character varying, IN p_telefono character varying, IN p_correo character varying)
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
