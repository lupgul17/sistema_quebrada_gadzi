CREATE OR REPLACE FUNCTION fn_eventos_checkpoint_pendiente() RETURNS TABLE(id_evento integer, fecha date, dias_para_evento integer, cliente text, correo_cliente character varying, total_a_pagar numeric, total_pagado numeric, porcentaje_pagado numeric, id_tipo_recordatorio integer, tipo_recordatorio character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        e.id_evento,
        e.fecha,
        (e.fecha - CURRENT_DATE) AS dias_para_evento,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        p.correo AS correo_cliente,
        vs.total_a_pagar,
        vs.total_pagado,
        vs.porcentaje_pagado,
        tr.id_tipo_recordatorio,
        tr.descripcion AS tipo_recordatorio
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    JOIN v_evento_saldo vs ON vs.id_evento = e.id_evento
    CROSS JOIN tc_tipo_recordatorio tr
    WHERE e.estado = 'confirmado'
      AND p.correo IS NOT NULL
      AND (
            (tr.descripcion = 'checkpoint_50_proximo' AND (e.fecha - CURRENT_DATE) BETWEEN 28 AND 35 AND vs.porcentaje_pagado < 0.5)
         OR (tr.descripcion = 'checkpoint_50_vencido'  AND (e.fecha - CURRENT_DATE) < 30 AND (e.fecha - CURRENT_DATE) >= 7 AND vs.porcentaje_pagado < 0.5)
         OR (tr.descripcion = 'checkpoint_100_proximo' AND (e.fecha - CURRENT_DATE) BETWEEN 8 AND 14 AND vs.porcentaje_pagado < 1)
         OR (tr.descripcion = 'checkpoint_100_vencido' AND (e.fecha - CURRENT_DATE) < 7 AND (e.fecha - CURRENT_DATE) >= 0 AND vs.porcentaje_pagado < 1)
      )
      AND NOT EXISTS (
          SELECT 1 FROM recordatorio_enviado re
          WHERE re.id_evento = e.id_evento AND re.id_tipo_recordatorio = tr.id_tipo_recordatorio
      );
$$;
