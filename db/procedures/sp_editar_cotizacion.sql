CREATE OR REPLACE PROCEDURE sp_editar_cotizacion(IN p_id_cotizacion integer, IN p_brindis boolean, IN p_cantidad_mesa_principal integer, IN p_cantidad_mesas_reservadas integer, IN p_id_color_mantel integer, IN p_id_color_cubremanteles integer, IN p_observaciones text, IN p_boquitas text)
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
