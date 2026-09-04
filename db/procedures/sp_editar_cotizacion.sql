CREATE OR REPLACE PROCEDURE sp_editar_cotizacion(
    p_id_cotizacion             INTEGER,
    p_brindis                   BOOLEAN,
    p_cantidad_mesa_principal   INTEGER,
    p_cantidad_mesas_reservadas INTEGER,
    p_id_color_mantel           INTEGER,
    p_id_color_cubremanteles    INTEGER,
    p_observaciones             TEXT,
    p_boquitas                  TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cotizacion WHERE id_cotizacion = p_id_cotizacion) THEN
        RAISE EXCEPTION 'No existe una cotizacion con id_cotizacion = %', p_id_cotizacion;
    END IF;

    UPDATE cotizacion
    SET brindis = p_brindis,
        cantidad_mesa_principal = p_cantidad_mesa_principal,
        cantidad_mesas_reservadas = p_cantidad_mesas_reservadas,
        id_color_mantel = p_id_color_mantel,
        id_color_cubremanteles = p_id_color_cubremanteles,
        observaciones = p_observaciones,
        boquitas = p_boquitas
    WHERE id_cotizacion = p_id_cotizacion;
END;
$$;