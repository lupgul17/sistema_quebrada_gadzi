DROP FUNCTION fn_cotizacion_detalle(integer);

CREATE OR REPLACE FUNCTION fn_cotizacion_detalle(p_id_cotizacion INTEGER)
RETURNS TABLE (
    id_cotizacion            INTEGER,
    id_evento                INTEGER,
    version                  INTEGER,
    fecha_cotizacion         DATE,
    vigencia_dias            INTEGER,
    deposito_garantia        DECIMAL,
    activa                   BOOLEAN,
    id_estado_cotizacion     INTEGER,
    estado                   VARCHAR,
    id_empleado              INTEGER,
    vendedor                 TEXT,
    subtotal_menus           DECIMAL,
    subtotal_servicios       DECIMAL,
    total_descuento          DECIMAL,
    total                    DECIMAL,
    brindis                  BOOLEAN,
    cantidad_mesa_principal  INTEGER,
    cantidad_mesas_reservadas INTEGER,
    id_color_mantel          INTEGER,
    color_mantel             VARCHAR,
    id_color_cubremanteles   INTEGER,
    color_cubremanteles      VARCHAR,
    observaciones            TEXT,
    boquitas                 TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        c.id_cotizacion, c.id_evento, c.version, c.fecha_cotizacion, c.vigencia_dias,
        c.deposito_garantia, c.activa, c.id_estado_cotizacion, ec.descripcion AS estado,
        c.id_empleado,
        p.primer_nombre || ' ' || p.primer_apellido AS vendedor,
        vc.subtotal_menus, vc.subtotal_servicios, vc.total_descuento, vc.total,
        c.brindis, c.cantidad_mesa_principal, c.cantidad_mesas_reservadas,
        c.id_color_mantel, cm.descripcion AS color_mantel,
        c.id_color_cubremanteles, ccm.descripcion AS color_cubremanteles,
        c.observaciones, c.boquitas
    FROM cotizacion c
    JOIN tc_estado_cotizacion ec ON ec.id_estado_cotizacion = c.id_estado_cotizacion
    LEFT JOIN empleado e ON e.id_empleado = c.id_empleado
    LEFT JOIN persona p ON p.id_persona = e.id_persona
    LEFT JOIN tc_color_mantel cm ON cm.id_color_mantel = c.id_color_mantel
    LEFT JOIN tc_color_cubremanteles ccm ON ccm.id_color_cubremanteles = c.id_color_cubremanteles
    JOIN v_cotizacion_calculada vc ON vc.id_cotizacion = c.id_cotizacion
    WHERE c.id_cotizacion = p_id_cotizacion;
$$;