CREATE OR REPLACE FUNCTION fn_cotizacion_paquete(p_id_cotizacion INTEGER)
RETURNS TABLE (
    id_cotizacion_menu  INTEGER,
    paquete             VARCHAR,
    elecciones          TEXT,
    incluye             JSONB,
    horas_incluidas     INTEGER
)
LANGUAGE sql STABLE
AS $$
    SELECT cm.id_cotizacion_menu, p.nombre, pa.elecciones, pa.incluye, pa.horas_incluidas
    FROM cotizacion_menu cm
    JOIN paquete_aplicado pa ON pa.id_menu = cm.id_menu
    JOIN paquete p ON p.id_paquete = pa.id_paquete
    WHERE cm.id_cotizacion = p_id_cotizacion
    ORDER BY cm.id_cotizacion_menu;
$$;
