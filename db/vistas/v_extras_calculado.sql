CREATE OR REPLACE VIEW v_extras_calculado AS
 SELECT ex.id_extra,
    ex.id_evento,
    (COALESCE(es.subtotal, (0)::numeric) + COALESCE(em.subtotal, (0)::numeric)) AS total
   FROM ((public.extras ex
     LEFT JOIN ( SELECT extras_servicios.id_extra,
            sum(extras_servicios.subtotal) AS subtotal
           FROM public.extras_servicios
          WHERE ((extras_servicios.estado)::text = ANY ((ARRAY['aprobado'::character varying, 'pagado'::character varying])::text[]))
          GROUP BY extras_servicios.id_extra) es ON ((es.id_extra = ex.id_extra)))
     LEFT JOIN ( SELECT extras_menu.id_extra,
            sum(extras_menu.subtotal) AS subtotal
           FROM public.extras_menu
          WHERE ((extras_menu.estado)::text = ANY ((ARRAY['aprobado'::character varying, 'pagado'::character varying])::text[]))
          GROUP BY extras_menu.id_extra) em ON ((em.id_extra = ex.id_extra)));
