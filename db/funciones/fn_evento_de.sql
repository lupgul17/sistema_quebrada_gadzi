CREATE OR REPLACE FUNCTION fn_evento_de(p_tipo VARCHAR, p_id INTEGER)
RETURNS INTEGER
LANGUAGE sql STABLE
AS $$
    SELECT CASE p_tipo
        WHEN 'evento' THEN (SELECT id_evento FROM evento WHERE id_evento = p_id)
        WHEN 'cotizacion' THEN (SELECT id_evento FROM cotizacion WHERE id_cotizacion = p_id)
        WHEN 'cotizacion_menu' THEN (
            SELECT c.id_evento FROM cotizacion_menu cm JOIN cotizacion c ON c.id_cotizacion = cm.id_cotizacion
            WHERE cm.id_cotizacion_menu = p_id)
        WHEN 'cotizacion_servicios' THEN (
            SELECT c.id_evento FROM cotizacion_servicios cs JOIN cotizacion c ON c.id_cotizacion = cs.id_cotizacion
            WHERE cs.id_cotizacion_servicios = p_id)
        WHEN 'descuento' THEN (
            SELECT c.id_evento FROM cotizacion_servicios_descuento d
            JOIN cotizacion_servicios cs ON cs.id_cotizacion_servicios = d.id_cotizacion_servicios
            JOIN cotizacion c ON c.id_cotizacion = cs.id_cotizacion
            WHERE d.id_descuento = p_id)
        WHEN 'pago' THEN (SELECT id_evento FROM pago WHERE id_pago = p_id)
        WHEN 'degustacion' THEN (SELECT id_evento FROM degustacion WHERE id_degustacion = p_id)
        WHEN 'degustacion_menu' THEN (
            SELECT d.id_evento FROM degustacion_menu dm JOIN degustacion d ON d.id_degustacion = dm.id_degustacion
            WHERE dm.id_degustacion_menu = p_id)
        WHEN 'extras_servicios' THEN (
            SELECT e.id_evento FROM extras_servicios es JOIN extras e ON e.id_extra = es.id_extra
            WHERE es.id_extras_servicios = p_id)
        WHEN 'extras_menu' THEN (
            SELECT e.id_evento FROM extras_menu em JOIN extras e ON e.id_extra = em.id_extra
            WHERE em.id_extras_menu = p_id)
    END;
$$;
