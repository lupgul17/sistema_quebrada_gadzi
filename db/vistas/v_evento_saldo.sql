CREATE OR REPLACE VIEW v_evento_saldo AS
 SELECT e.id_evento,
    COALESCE(vc.total, (0)::numeric) AS total_cotizado,
    COALESCE(ve.total, (0)::numeric) AS total_extras,
    (COALESCE(vc.total, (0)::numeric) + COALESCE(ve.total, (0)::numeric)) AS total_a_pagar,
    COALESCE(pagos.total_pagado, (0)::numeric) AS total_pagado,
    ((COALESCE(vc.total, (0)::numeric) + COALESCE(ve.total, (0)::numeric)) - COALESCE(pagos.total_pagado, (0)::numeric)) AS saldo_pendiente,
        CASE
            WHEN ((COALESCE(vc.total, (0)::numeric) + COALESCE(ve.total, (0)::numeric)) > (0)::numeric) THEN (COALESCE(pagos.total_pagado, (0)::numeric) / (COALESCE(vc.total, (0)::numeric) + COALESCE(ve.total, (0)::numeric)))
            ELSE (0)::numeric
        END AS porcentaje_pagado
   FROM ((((public.evento e
     LEFT JOIN public.cotizacion c ON (((c.id_evento = e.id_evento) AND (c.activa = true))))
     LEFT JOIN public.v_cotizacion_calculada vc ON ((vc.id_cotizacion = c.id_cotizacion)))
     LEFT JOIN public.v_extras_calculado ve ON ((ve.id_evento = e.id_evento)))
     LEFT JOIN ( SELECT pago.id_evento,
            sum(pago.monto) AS total_pagado
           FROM public.pago
          WHERE ((pago.estado)::text = 'verificado'::text)
          GROUP BY pago.id_evento) pagos ON ((pagos.id_evento = e.id_evento)));
