-- Cambia el estado / notas de un prospecto. Al pasar a 'convertido' exige el
-- cliente creado (el evento es opcional: puede que todavía no haya fecha).
CREATE OR REPLACE PROCEDURE sp_actualizar_prospecto(
    p_id_prospecto    INTEGER,
    p_estado          VARCHAR,
    p_notas_internas  TEXT,
    p_id_cliente      INTEGER,
    p_id_evento       INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM prospecto WHERE id_prospecto = p_id_prospecto) THEN
        RAISE EXCEPTION 'No existe un prospecto con id = %', p_id_prospecto;
    END IF;
    IF p_estado NOT IN ('nuevo', 'contactado', 'convertido', 'descartado') THEN
        RAISE EXCEPTION 'Estado inválido: %', p_estado;
    END IF;
    -- Acepta el cliente que llega ahora o el que ya quedó guardado en un paso anterior
    IF p_estado = 'convertido'
       AND COALESCE(p_id_cliente, (SELECT id_cliente FROM prospecto WHERE id_prospecto = p_id_prospecto)) IS NULL THEN
        RAISE EXCEPTION 'Para marcarlo como convertido hace falta el cliente creado';
    END IF;

    UPDATE prospecto
    SET estado = p_estado,
        notas_internas = p_notas_internas,
        id_cliente = COALESCE(p_id_cliente, id_cliente),
        id_evento = COALESCE(p_id_evento, id_evento)
    WHERE id_prospecto = p_id_prospecto;
END;
$$;
