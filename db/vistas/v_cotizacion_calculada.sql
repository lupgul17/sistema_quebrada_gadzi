CREATE OR REPLACE VIEW v_cotizacion_calculada AS
 SELECT c.id_cotizacion,
    c.id_evento,
    COALESCE(m.subtotal, (0)::numeric) AS subtotal_menus,
    COALESCE(s.subtotal, (0)::numeric) AS subtotal_servicios,
    (((COALESCE(m.subtotal, (0)::numeric) + COALESCE(s.subtotal, (0)::numeric)) + c.deposito_garantia) - COALESCE(d.total_descuento, (0)::numeric)) AS total,
    COALESCE(d.total_descuento, (0)::numeric) AS total_descuento
   FROM (((public.cotizacion c
     LEFT JOIN ( SELECT cotizacion_menu.id_cotizacion,
            sum(cotizacion_menu.subtotal) AS subtotal
           FROM public.cotizacion_menu
          GROUP BY cotizacion_menu.id_cotizacion) m ON ((m.id_cotizacion = c.id_cotizacion)))
     LEFT JOIN ( SELECT cotizacion_servicios.id_cotizacion,
            sum(cotizacion_servicios.subtotal) AS subtotal
           FROM public.cotizacion_servicios
          GROUP BY cotizacion_servicios.id_cotizacion) s ON ((s.id_cotizacion = c.id_cotizacion)))
     LEFT JOIN ( SELECT cs.id_cotizacion,
            sum(csd.monto_descontado) AS total_descuento
           FROM (public.cotizacion_servicios_descuento csd
             JOIN public.cotizacion_servicios cs ON ((cs.id_cotizacion_servicios = csd.id_cotizacion_servicios)))
          WHERE ((csd.estado)::text = 'aprobado'::text)
          GROUP BY cs.id_cotizacion) d ON ((d.id_cotizacion = c.id_cotizacion)));
