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
    v_id_persona  INTEGER;
    v_count_cui   INTEGER;
BEGIN
    -- 1. Buscar por CUI primero (identifica a la persona real, sin ambigüedad si no hay duplicados cargados)
    IF p_cui IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count_cui FROM persona WHERE cui = p_cui;

        IF v_count_cui > 1 THEN
            RAISE EXCEPTION 'Hay más de una persona con el CUI %, no se puede determinar automáticamente cuál usar. Revisar manualmente.', p_cui;
        ELSIF v_count_cui = 1 THEN
            SELECT id_persona INTO v_id_persona FROM persona WHERE cui = p_cui;
        END IF;
    END IF;

    -- 2. Sin CUI o sin match por CUI: correo como respaldo (útil si el cliente no dio CUI todavía)
    IF v_id_persona IS NULL AND p_correo IS NOT NULL THEN
        SELECT id_persona INTO v_id_persona FROM persona WHERE correo = p_correo;
    END IF;

    -- 3. Si encontramos una persona existente, solo vincularla (no sobreescribir sus datos)
    IF v_id_persona IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM cliente WHERE id_persona = v_id_persona) THEN
            RAISE EXCEPTION 'Ya existe un cliente para esta persona (id_persona = %)', v_id_persona;
        END IF;

        INSERT INTO cliente (id_persona) VALUES (v_id_persona)
        RETURNING id_cliente INTO p_id_cliente;
        RETURN;
    END IF;

    -- 4. No existe la persona todavía: crearla desde cero, como ya hacía
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