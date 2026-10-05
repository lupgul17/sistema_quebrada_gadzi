--
-- PostgreSQL database dump
--

\restrict ABHD4iIad3gmiXh08UVU73E5T7EkP69JveP7DVMSv5QG1ZzE4cNPhgyKJYoyPLH

-- Dumped from database version 18.6 (4e955f5)
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: fn_buscar_cliente(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_buscar_cliente(p_texto character varying) RETURNS TABLE(id_cliente integer, id_persona integer, primer_nombre character varying, segundo_nombre character varying, primer_apellido character varying, segundo_apellido character varying, cui character varying, nit character varying, telefono character varying, correo character varying, fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        c.id_cliente,
        p.id_persona,
        p.primer_nombre,
        p.segundo_nombre,
        p.primer_apellido,
        p.segundo_apellido,
        p.cui,
        p.nit,
        p.telefono,
        p.correo,
        c.fecha_creacion
    FROM cliente c
    JOIN persona p ON p.id_persona = c.id_persona
    WHERE
        unaccent(p.primer_nombre) ILIKE unaccent('%' || p_texto || '%')
        OR unaccent(p.segundo_nombre) ILIKE unaccent('%' || p_texto || '%')
        OR unaccent(p.primer_apellido) ILIKE unaccent('%' || p_texto || '%')
        OR unaccent(p.segundo_apellido) ILIKE unaccent('%' || p_texto || '%')
        OR p.telefono ILIKE '%' || p_texto || '%'
        OR p.cui ILIKE '%' || p_texto || '%'
    ORDER BY p.primer_apellido, p.primer_nombre;
$$;


--
-- Name: fn_buscar_usuario_login(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_buscar_usuario_login(p_username character varying) RETURNS TABLE(id_usuario integer, id_persona integer, username character varying, password_hash character varying, id_tipo_usuario integer, tipo_usuario character varying, id_rol_acceso integer, rol_acceso character varying, nombre_completo text, confirmacion boolean, activo boolean)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        u.id_usuario, u.id_persona, u.username, u.password_hash,
        u.id_tipo_usuario, tu.descripcion AS tipo_usuario,
        u.id_rol_acceso, tra.descripcion AS rol_acceso,
        p.primer_nombre || ' ' || p.primer_apellido AS nombre_completo,
        u.confirmacion, u.activo
    FROM usuario u
    JOIN persona p ON p.id_persona = u.id_persona
    JOIN tc_tipo_usuario tu ON tu.id_tipo_usuario = u.id_tipo_usuario
    LEFT JOIN tc_rol_acceso tra ON tra.id_rol_acceso = u.id_rol_acceso
    WHERE u.username = p_username;
$$;


--
-- Name: fn_cliente_detalle(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_cliente_detalle(p_id_cliente integer) RETURNS TABLE(id_cliente integer, id_persona integer, primer_nombre character varying, segundo_nombre character varying, primer_apellido character varying, segundo_apellido character varying, cui character varying, nit character varying, telefono character varying, correo character varying, fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        c.id_cliente,
        p.id_persona,
        p.primer_nombre,
        p.segundo_nombre,
        p.primer_apellido,
        p.segundo_apellido,
        p.cui,
        p.nit,
        p.telefono,
        p.correo,
        c.fecha_creacion
    FROM cliente c
    JOIN persona p ON p.id_persona = c.id_persona
    WHERE c.id_cliente = p_id_cliente;
$$;


--
-- Name: fn_cotizacion_detalle(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_cotizacion_detalle(p_id_cotizacion integer) RETURNS TABLE(id_cotizacion integer, id_evento integer, version integer, fecha_cotizacion date, vigencia_dias integer, deposito_garantia numeric, activa boolean, id_estado_cotizacion integer, estado character varying, id_empleado integer, vendedor text, subtotal_menus numeric, subtotal_servicios numeric, total_descuento numeric, total numeric, brindis boolean, cantidad_mesa_principal integer, cantidad_mesas_reservadas integer, id_color_mantel integer, color_mantel character varying, id_color_cubremanteles integer, color_cubremanteles character varying, observaciones text, boquitas text)
    LANGUAGE sql STABLE
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


--
-- Name: fn_cotizacion_menu_detalle(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_cotizacion_menu_detalle(p_id_cotizacion integer) RETURNS TABLE(id_cotizacion_menu integer, id_menu integer, menu character varying, tipo_menu character varying, cantidad integer, precio_unitario_congelado numeric, subtotal numeric, es_extra_degustacion boolean)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        cm.id_cotizacion_menu, cm.id_menu, m.nombre AS menu, tm.descripcion AS tipo_menu,
        cm.cantidad, cm.precio_unitario_congelado, cm.subtotal,
        EXISTS (SELECT 1 FROM degustacion_menu dm WHERE dm.id_cotizacion_menu = cm.id_cotizacion_menu) AS es_extra_degustacion
    FROM cotizacion_menu cm
    JOIN menu m ON m.id_menu = cm.id_menu
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    WHERE cm.id_cotizacion = p_id_cotizacion
    ORDER BY
        EXISTS (SELECT 1 FROM degustacion_menu dm WHERE dm.id_cotizacion_menu = cm.id_cotizacion_menu),
        m.nombre;
$$;


--
-- Name: fn_cotizacion_servicios_detalle(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_cotizacion_servicios_detalle(p_id_cotizacion integer) RETURNS TABLE(id_cotizacion_servicios integer, id_servicio integer, servicio character varying, categoria character varying, cantidad integer, precio_unitario_congelado numeric, subtotal numeric, tiene_descuento_pendiente boolean)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        cs.id_cotizacion_servicios, cs.id_servicio, s.nombre AS servicio, csc.descripcion AS categoria,
        cs.cantidad, cs.precio_unitario_congelado, cs.subtotal,
        EXISTS (
            SELECT 1 FROM cotizacion_servicios_descuento csd
            WHERE csd.id_cotizacion_servicios = cs.id_cotizacion_servicios AND csd.estado = 'pendiente'
        ) AS tiene_descuento_pendiente
    FROM cotizacion_servicios cs
    JOIN servicios s ON s.id_servicio = cs.id_servicio
    JOIN tc_categoria_servicio csc ON csc.id_categoria_servicio = s.id_categoria_servicio
    WHERE cs.id_cotizacion = p_id_cotizacion
    ORDER BY s.nombre;
$$;


--
-- Name: fn_cotizaciones_proximas_vencer(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_cotizaciones_proximas_vencer(p_dias_anticipacion integer DEFAULT 3) RETURNS TABLE(id_cotizacion integer, id_evento integer, cliente text, fecha_vencimiento date, dias_restantes integer, total numeric)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        c.id_cotizacion, c.id_evento,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        (c.fecha_cotizacion + c.vigencia_dias) AS fecha_vencimiento,
        (c.fecha_cotizacion + c.vigencia_dias) - CURRENT_DATE AS dias_restantes,
        c.total
    FROM cotizacion c
    JOIN evento e ON e.id_evento = c.id_evento
    JOIN cliente cl ON cl.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = cl.id_persona
    WHERE c.activa = true
      AND e.estado = 'cotizacion'
      AND e.reserva_temporal = true
      AND (c.fecha_cotizacion + c.vigencia_dias) BETWEEN CURRENT_DATE AND CURRENT_DATE + p_dias_anticipacion
    ORDER BY fecha_vencimiento;
$$;


--
-- Name: fn_degustacion_detalle(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_degustacion_detalle(p_id_degustacion integer) RETURNS TABLE(id_degustacion integer, id_evento integer, id_fecha_degustacion integer, fecha date, hora_inicio time without time zone, hora_fin time without time zone, hora_llegada time without time zone, estado character varying, resultado character varying, motivo_rechazo text, notas text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        d.id_degustacion, d.id_evento, d.id_fecha_degustacion, fd.fecha, fd.hora_inicio, fd.hora_fin, d.hora_llegada,
        d.estado, d.resultado, d.motivo_rechazo, d.notas
    FROM degustacion d
    JOIN fechas_degustacion fd ON fd.id_fecha_degustacion = d.id_fecha_degustacion
    WHERE d.id_degustacion = p_id_degustacion;
$$;


--
-- Name: fn_evento_detalle(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_evento_detalle(p_id_evento integer) RETURNS TABLE(id_evento integer, fecha date, hora_inicio time without time zone, hora_fin time without time zone, estado character varying, reserva_temporal boolean, total_adultos integer, total_menores integer, notas text, id_cliente integer, cliente text, telefono_cliente character varying, id_tipo_evento integer, tipo_evento character varying, salones text, salones_ids integer[], fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        e.id_evento,
        e.fecha,
        e.hora_inicio,
        e.hora_fin,
        e.estado,
        e.reserva_temporal,
        e.total_adultos,
        e.total_menores,
        e.notas,
        c.id_cliente,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        p.telefono AS telefono_cliente,
        te.id_tipo_evento,
        te.descripcion AS tipo_evento,
        STRING_AGG(s.nombre, ', ' ORDER BY s.nombre) AS salones,
        ARRAY_AGG(s.id_salon ORDER BY s.nombre) AS salones_ids,
        e.fecha_creacion
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    LEFT JOIN evento_salon es ON es.id_evento = e.id_evento
    LEFT JOIN salon s ON s.id_salon = es.id_salon
    WHERE e.id_evento = p_id_evento
    GROUP BY e.id_evento, c.id_cliente, p.primer_nombre, p.primer_apellido, p.telefono, te.id_tipo_evento, te.descripcion;
$$;


--
-- Name: fn_eventos_checkpoint_pendiente(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_eventos_checkpoint_pendiente() RETURNS TABLE(id_evento integer, fecha date, dias_para_evento integer, cliente text, correo_cliente character varying, total_a_pagar numeric, total_pagado numeric, porcentaje_pagado numeric, id_tipo_recordatorio integer, tipo_recordatorio character varying)
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


--
-- Name: fn_eventos_pendientes_pago(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_eventos_pendientes_pago() RETURNS TABLE(id_evento integer, fecha date, cliente text, saldo_pendiente numeric, total_a_pagar numeric, porcentaje_pagado numeric)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        e.id_evento, e.fecha,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        vs.saldo_pendiente, vs.total_a_pagar, vs.porcentaje_pagado
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    JOIN v_evento_saldo vs ON vs.id_evento = e.id_evento
    WHERE vs.saldo_pendiente > 0 AND e.estado = 'confirmado'
    ORDER BY e.fecha;
$$;


--
-- Name: fn_fechas_ocupadas_publico(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_fechas_ocupadas_publico(p_desde date, p_hasta date) RETURNS TABLE(fecha date, id_salon integer)
    LANGUAGE sql STABLE
    AS $$
    SELECT DISTINCT e.fecha, es.id_salon
    FROM evento e
    JOIN evento_salon es ON es.id_evento = e.id_evento
    LEFT JOIN cotizacion c ON c.id_evento = e.id_evento AND c.activa = true
    WHERE e.fecha BETWEEN p_desde AND p_hasta
      AND (
            e.estado IN ('confirmado', 'en_curso')
            OR (
                e.estado = 'cotizacion'
                AND e.reserva_temporal = true
                AND COALESCE(c.fecha_cotizacion + c.vigencia_dias, e.fecha_creacion::date + 8) >= CURRENT_DATE
            )
          )
    ORDER BY e.fecha, es.id_salon;
$$;


--
-- Name: fn_id_empleado_por_persona(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_id_empleado_por_persona(p_id_persona integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
    SELECT id_empleado FROM empleado WHERE id_persona = p_id_persona;
$$;


--
-- Name: fn_listar_categorias_componente_menu(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_categorias_componente_menu() RETURNS TABLE(id_categoria_componente_menu integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_categoria_componente_menu, descripcion FROM tc_categoria_componente_menu ORDER BY descripcion;
$$;


--
-- Name: fn_listar_categorias_servicio(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_categorias_servicio() RETURNS TABLE(id_categoria_servicio integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_categoria_servicio, descripcion FROM tc_categoria_servicio ORDER BY descripcion;
$$;


--
-- Name: fn_listar_clientes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_clientes() RETURNS TABLE(id_cliente integer, id_persona integer, primer_nombre character varying, segundo_nombre character varying, primer_apellido character varying, segundo_apellido character varying, cui character varying, nit character varying, telefono character varying, correo character varying, fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        c.id_cliente,
        p.id_persona,
        p.primer_nombre,
        p.segundo_nombre,
        p.primer_apellido,
        p.segundo_apellido,
        p.cui,
        p.nit,
        p.telefono,
        p.correo,
        c.fecha_creacion
    FROM cliente c
    JOIN persona p ON p.id_persona = c.id_persona
    ORDER BY p.primer_apellido, p.primer_nombre;
$$;


--
-- Name: fn_listar_colores_cubremanteles(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_colores_cubremanteles() RETURNS TABLE(id_color_cubremanteles integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_color_cubremanteles, descripcion FROM tc_color_cubremanteles ORDER BY descripcion;
$$;


--
-- Name: fn_listar_colores_mantel(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_colores_mantel() RETURNS TABLE(id_color_mantel integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_color_mantel, descripcion FROM tc_color_mantel ORDER BY descripcion;
$$;


--
-- Name: fn_listar_componentes_menu(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_componentes_menu(p_id_categoria integer DEFAULT NULL::integer) RETURNS TABLE(id_componente integer, nombre character varying, recargo numeric, activo boolean, id_categoria_componente_menu integer, categoria character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        cm.id_componente,
        cm.nombre,
        cm.recargo,
        cm.activo,
        cc.id_categoria_componente_menu,
        cc.descripcion AS categoria
    FROM componente_menu cm
    JOIN tc_categoria_componente_menu cc ON cc.id_categoria_componente_menu = cm.id_categoria_componente_menu
    WHERE p_id_categoria IS NULL OR cm.id_categoria_componente_menu = p_id_categoria
    ORDER BY cc.descripcion, cm.nombre;
$$;


--
-- Name: fn_listar_cotizaciones_evento(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_cotizaciones_evento(p_id_evento integer) RETURNS TABLE(id_cotizacion integer, version integer, fecha_cotizacion date, vigencia_dias integer, activa boolean, estado character varying, total numeric, vendedor text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        c.id_cotizacion, c.version, c.fecha_cotizacion, c.vigencia_dias, c.activa,
        ec.descripcion AS estado,
        vc.total,
        p.primer_nombre || ' ' || p.primer_apellido AS vendedor
    FROM cotizacion c
    JOIN tc_estado_cotizacion ec ON ec.id_estado_cotizacion = c.id_estado_cotizacion
    JOIN v_cotizacion_calculada vc ON vc.id_cotizacion = c.id_cotizacion
    LEFT JOIN empleado e ON e.id_empleado = c.id_empleado
    LEFT JOIN persona p ON p.id_persona = e.id_persona
    WHERE c.id_evento = p_id_evento
    ORDER BY c.version DESC;
$$;


--
-- Name: fn_listar_degustaciones_evento(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_degustaciones_evento(p_id_evento integer) RETURNS TABLE(id_degustacion integer, id_fecha_degustacion integer, fecha date, hora_inicio time without time zone, hora_fin time without time zone, hora_llegada time without time zone, estado character varying, resultado character varying, motivo_rechazo text, notas text, fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        d.id_degustacion, d.id_fecha_degustacion, fd.fecha, fd.hora_inicio, fd.hora_fin, d.hora_llegada,
        d.estado, d.resultado, d.motivo_rechazo, d.notas, d.fecha_creacion
    FROM degustacion d
    JOIN fechas_degustacion fd ON fd.id_fecha_degustacion = d.id_fecha_degustacion
    WHERE d.id_evento = p_id_evento
    ORDER BY fd.fecha DESC;
$$;


--
-- Name: fn_listar_degustaciones_por_fecha(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_degustaciones_por_fecha(p_id_fecha_degustacion integer) RETURNS TABLE(id_degustacion integer, id_evento integer, cliente text, telefono character varying, tipo_evento character varying, fecha_evento date, hora_llegada time without time zone, estado character varying, notas text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        d.id_degustacion, d.id_evento,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        p.telefono,
        te.descripcion AS tipo_evento,
        e.fecha AS fecha_evento,
        d.hora_llegada,
        d.estado, d.notas
    FROM degustacion d
    JOIN evento e ON e.id_evento = d.id_evento
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    WHERE d.id_fecha_degustacion = p_id_fecha_degustacion AND d.estado != 'cancelada'
    ORDER BY d.hora_llegada NULLS LAST, p.primer_apellido;
$$;


--
-- Name: fn_listar_descuentos_servicio(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_descuentos_servicio(p_id_cotizacion_servicios integer) RETURNS TABLE(id_descuento integer, id_tipo_descuento integer, tipo_descuento character varying, porcentaje numeric, monto_descontado numeric, motivo text, estado character varying, solicito text, aprobo text, fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        csd.id_descuento, csd.id_tipo_descuento, td.descripcion AS tipo_descuento,
        csd.porcentaje, csd.monto_descontado, csd.motivo, csd.estado,
        ps.primer_nombre || ' ' || ps.primer_apellido AS solicito,
        pa.primer_nombre || ' ' || pa.primer_apellido AS aprobo,
        csd.fecha_creacion
    FROM cotizacion_servicios_descuento csd
    JOIN tc_tipo_descuento td ON td.id_tipo_descuento = csd.id_tipo_descuento
    LEFT JOIN empleado es ON es.id_empleado = csd.id_empleado_solicito
    LEFT JOIN persona ps ON ps.id_persona = es.id_persona
    LEFT JOIN empleado ea ON ea.id_empleado = csd.id_empleado_aprobo
    LEFT JOIN persona pa ON pa.id_persona = ea.id_persona
    WHERE csd.id_cotizacion_servicios = p_id_cotizacion_servicios
    ORDER BY csd.fecha_creacion DESC;
$$;


--
-- Name: fn_listar_eventos(character varying, date, date, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_eventos(p_estado character varying DEFAULT NULL::character varying, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_id_cliente integer DEFAULT NULL::integer) RETURNS TABLE(id_evento integer, fecha date, hora_inicio time without time zone, hora_fin time without time zone, estado character varying, reserva_temporal boolean, tipo_evento character varying, total_adultos integer, total_menores integer, cliente text, salones text, locaciones text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        e.id_evento,
        e.fecha,
        e.hora_inicio,
        e.hora_fin,
        e.estado,
        e.reserva_temporal,
        te.descripcion AS tipo_evento,
        e.total_adultos,
        e.total_menores,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        STRING_AGG(DISTINCT s.nombre, ', ' ORDER BY s.nombre) AS salones,
        STRING_AGG(DISTINCT l.nombre, ', ' ORDER BY l.nombre) AS locaciones
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    LEFT JOIN evento_salon es ON es.id_evento = e.id_evento
    LEFT JOIN salon s ON s.id_salon = es.id_salon
    LEFT JOIN locacion l ON l.id_locacion = s.id_locacion
    WHERE
        (p_estado IS NULL OR e.estado = p_estado)
        AND (p_fecha_desde IS NULL OR e.fecha >= p_fecha_desde)
        AND (p_fecha_hasta IS NULL OR e.fecha <= p_fecha_hasta)
        AND (p_id_cliente IS NULL OR e.id_cliente = p_id_cliente)
    GROUP BY e.id_evento, e.fecha, e.hora_inicio, e.hora_fin, e.estado, e.reserva_temporal, te.descripcion, e.total_adultos, e.total_menores, p.primer_nombre, p.primer_apellido
    ORDER BY e.fecha DESC, e.hora_inicio;
$$;


--
-- Name: fn_listar_extras_evento(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_extras_evento(p_id_evento integer) RETURNS TABLE(id_extra integer, id_evento integer, total numeric, id_empleado integer, servicios json, menus json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id_extra,
        e.id_evento,
        e.total,
        e.id_empleado,
        COALESCE((
            SELECT json_agg(x.*)
            FROM (
                SELECT
                    es.id_extras_servicios,
                    es.id_servicio,
                    s.nombre AS servicio,
                    es.id_tipo_cargo_extra,
                    tce.descripcion AS tipo_cargo_extra,
                    es.descripcion,
                    es.cantidad,
                    es.precio_unitario,
                    es.subtotal,
                    es.estado
                FROM extras_servicios es
                LEFT JOIN servicios s ON s.id_servicio = es.id_servicio
                LEFT JOIN tc_tipo_cargo_extra tce ON tce.id_tipo_cargo_extra = es.id_tipo_cargo_extra
                WHERE es.id_extra = e.id_extra
                ORDER BY es.id_extras_servicios
            ) x
        ), '[]'::json) AS servicios,
        COALESCE((
            SELECT json_agg(y.*)
            FROM (
                SELECT
                    em.id_extras_menu,
                    em.id_menu,
                    m.nombre AS menu,
                    em.descripcion,
                    em.cantidad,
                    em.precio_base,
                    em.subtotal,
                    em.estado
                FROM extras_menu em
                LEFT JOIN menu m ON m.id_menu = em.id_menu
                WHERE em.id_extra = e.id_extra
                ORDER BY em.id_extras_menu
            ) y
        ), '[]'::json) AS menus
    FROM extras e
    WHERE e.id_evento = p_id_evento;
END;
$$;


--
-- Name: fn_listar_fechas_degustacion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_fechas_degustacion() RETURNS TABLE(id_fecha_degustacion integer, fecha date, hora_inicio time without time zone, hora_fin time without time zone, estado character varying, eventos_agendados bigint)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        fd.id_fecha_degustacion, fd.fecha, fd.hora_inicio, fd.hora_fin, fd.estado,
        COUNT(d.id_degustacion) FILTER (WHERE d.estado != 'cancelada') AS eventos_agendados
    FROM fechas_degustacion fd
    LEFT JOIN degustacion d ON d.id_fecha_degustacion = fd.id_fecha_degustacion
    GROUP BY fd.id_fecha_degustacion
    ORDER BY fd.fecha DESC, fd.hora_inicio;
$$;


--
-- Name: fn_listar_menus(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_menus(p_id_tipo_menu integer DEFAULT NULL::integer) RETURNS TABLE(id_menu integer, nombre character varying, precio_base numeric, unidad_medida character varying, descripcion text, activo boolean, id_tipo_menu integer, tipo_menu character varying, componentes text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        m.id_menu, m.nombre, m.precio_base, m.unidad_medida, m.descripcion, m.activo,
        tm.id_tipo_menu, tm.descripcion AS tipo_menu,
        STRING_AGG(cm.nombre, ', ' ORDER BY cm.nombre) AS componentes
    FROM menu m
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    LEFT JOIN menu_componentes_menu mcm ON mcm.id_menu = m.id_menu
    LEFT JOIN componente_menu cm ON cm.id_componente = mcm.id_componente
    WHERE (p_id_tipo_menu IS NULL OR m.id_tipo_menu = p_id_tipo_menu)
      AND NOT m.es_personalizado
    GROUP BY m.id_menu, tm.id_tipo_menu, tm.descripcion
    ORDER BY tm.descripcion, m.nombre;
$$;


--
-- Name: fn_listar_menus_degustacion(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_menus_degustacion(p_id_degustacion integer) RETURNS TABLE(id_degustacion_menu integer, id_menu integer, menu character varying, tipo_menu character varying, resultado character varying, es_adicional boolean, notas text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        dm.id_degustacion_menu, dm.id_menu, m.nombre AS menu, tm.descripcion AS tipo_menu, dm.resultado, dm.es_adicional, dm.notas
    FROM degustacion_menu dm
    JOIN menu m ON m.id_menu = dm.id_menu
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    WHERE dm.id_degustacion = p_id_degustacion
    ORDER BY dm.id_degustacion_menu;
$$;


--
-- Name: fn_listar_pagos_cliente(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_pagos_cliente(p_id_cliente integer) RETURNS TABLE(id_pago integer, id_evento integer, fecha_evento date, fecha_pago date, monto numeric, tipo_pago character varying, concepto character varying, estado character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        p.id_pago, p.id_evento, e.fecha AS fecha_evento, p.fecha_pago, p.monto, tp.descripcion AS tipo_pago, p.concepto, p.estado
    FROM pago p
    JOIN evento e ON e.id_evento = p.id_evento
    JOIN tc_tipo_pago tp ON tp.id_tipo_pago = p.id_tipo_pago
    WHERE e.id_cliente = p_id_cliente
    ORDER BY p.fecha_pago DESC;
$$;


--
-- Name: fn_listar_pagos_evento(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_pagos_evento(p_id_evento integer) RETURNS TABLE(id_pago integer, fecha_pago date, monto numeric, tipo_pago character varying, concepto character varying, estado character varying, origen character varying, empleado text, path_comprobante character varying, motivo_rechazo text, notas text, fecha_registro timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        p.id_pago, p.fecha_pago, p.monto, tp.descripcion AS tipo_pago, p.concepto, p.estado, p.origen,
        pe.primer_nombre || ' ' || pe.primer_apellido AS empleado,
        p.path_comprobante, p.motivo_rechazo, p.notas, p.fecha_registro
    FROM pago p
    JOIN tc_tipo_pago tp ON tp.id_tipo_pago = p.id_tipo_pago
    LEFT JOIN empleado e ON e.id_empleado = p.id_empleado
    LEFT JOIN persona pe ON pe.id_persona = e.id_persona
    WHERE p.id_evento = p_id_evento
    ORDER BY p.fecha_pago DESC, p.fecha_registro DESC;
$$;


--
-- Name: fn_listar_prospectos(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_prospectos(p_estado character varying DEFAULT NULL::character varying) RETURNS TABLE(id_prospecto integer, nombre character varying, telefono character varying, correo character varying, id_tipo_evento integer, tipo_evento character varying, id_salon integer, salon character varying, locacion character varying, fecha_tentativa date, invitados integer, mensaje text, estado character varying, notas_internas text, id_cliente integer, id_evento integer, fecha_creacion timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        p.id_prospecto, p.nombre, p.telefono, p.correo,
        p.id_tipo_evento, te.descripcion AS tipo_evento,
        p.id_salon, s.nombre AS salon, l.nombre AS locacion,
        p.fecha_tentativa, p.invitados, p.mensaje, p.estado, p.notas_internas,
        p.id_cliente, p.id_evento, p.fecha_creacion
    FROM prospecto p
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = p.id_tipo_evento
    LEFT JOIN salon s ON s.id_salon = p.id_salon
    LEFT JOIN locacion l ON l.id_locacion = s.id_locacion
    WHERE p_estado IS NULL OR p.estado = p_estado
    ORDER BY (p.estado = 'nuevo') DESC, p.fecha_creacion DESC;
$$;


--
-- Name: fn_listar_roles_acceso(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_roles_acceso() RETURNS TABLE(id_rol_acceso integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$ SELECT id_rol_acceso, descripcion FROM tc_rol_acceso ORDER BY id_rol_acceso; $$;


--
-- Name: fn_listar_salones(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_salones() RETURNS TABLE(id_salon integer, nombre character varying, capacidad integer, descripcion text, locacion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        s.id_salon,
        s.nombre,
        s.capacidad,
        s.descripcion,
        l.nombre AS locacion
    FROM salon s
    JOIN locacion l ON l.id_locacion = s.id_locacion
    ORDER BY l.nombre, s.nombre;
$$;


--
-- Name: fn_listar_servicios(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_servicios(p_id_categoria_servicio integer DEFAULT NULL::integer) RETURNS TABLE(id_servicio integer, nombre character varying, precio_base numeric, unidad_medida character varying, activo boolean, id_categoria_servicio integer, categoria character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        s.id_servicio,
        s.nombre,
        s.precio_base,
        s.unidad_medida,
        s.activo,
        cs.id_categoria_servicio,
        cs.descripcion AS categoria
    FROM servicios s
    JOIN tc_categoria_servicio cs ON cs.id_categoria_servicio = s.id_categoria_servicio
    WHERE p_id_categoria_servicio IS NULL OR s.id_categoria_servicio = p_id_categoria_servicio
    ORDER BY cs.descripcion, s.nombre;
$$;


--
-- Name: fn_listar_tipos_cargo_extra(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_tipos_cargo_extra() RETURNS TABLE(id_tipo_cargo_extra integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_tipo_cargo_extra, descripcion FROM tc_tipo_cargo_extra ORDER BY descripcion;
$$;


--
-- Name: fn_listar_tipos_descuento(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_tipos_descuento() RETURNS TABLE(id_tipo_descuento integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_tipo_descuento, descripcion FROM tc_tipo_descuento ORDER BY descripcion;
$$;


--
-- Name: fn_listar_tipos_empleado(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_tipos_empleado() RETURNS TABLE(id_tipo_empleado integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$ SELECT id_tipo_empleado, descripcion FROM tc_tipo_empleado ORDER BY id_tipo_empleado; $$;


--
-- Name: fn_listar_tipos_evento(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_tipos_evento() RETURNS TABLE(id_tipo_evento integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_tipo_evento, descripcion
    FROM tc_tipo_evento
    ORDER BY descripcion;
$$;


--
-- Name: fn_listar_tipos_menu(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_tipos_menu() RETURNS TABLE(id_tipo_menu integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_tipo_menu, descripcion FROM tc_tipo_menu ORDER BY descripcion;
$$;


--
-- Name: fn_listar_tipos_pago(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_tipos_pago() RETURNS TABLE(id_tipo_pago integer, descripcion character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_tipo_pago, descripcion FROM tc_tipo_pago ORDER BY descripcion;
$$;


--
-- Name: fn_listar_usuarios(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_listar_usuarios() RETURNS TABLE(id_usuario integer, username character varying, nombre_completo text, correo character varying, telefono character varying, id_rol_acceso integer, rol character varying, tipo_empleado character varying, activo boolean, fecha_ultimo_acceso timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        u.id_usuario, u.username,
        p.primer_nombre || ' ' || p.primer_apellido AS nombre_completo,
        p.correo, p.telefono,
        u.id_rol_acceso, tra.descripcion AS rol,
        (SELECT te.descripcion
           FROM empleado e
           JOIN tc_tipo_empleado te ON te.id_tipo_empleado = e.id_tipo_empleado
          WHERE e.id_persona = u.id_persona
          ORDER BY e.id_empleado LIMIT 1) AS tipo_empleado,
        u.activo, u.fecha_ultimo_acceso
    FROM usuario u
    JOIN persona p ON p.id_persona = u.id_persona
    LEFT JOIN tc_rol_acceso tra ON tra.id_rol_acceso = u.id_rol_acceso
    ORDER BY u.username;
$$;


--
-- Name: fn_menu_detalle(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_menu_detalle(p_id_menu integer) RETURNS TABLE(id_menu integer, nombre character varying, precio_base numeric, unidad_medida character varying, descripcion text, activo boolean, id_tipo_menu integer, tipo_menu character varying, componentes_ids integer[])
    LANGUAGE sql STABLE
    AS $$
    SELECT
        m.id_menu, m.nombre, m.precio_base, m.unidad_medida, m.descripcion, m.activo,
        tm.id_tipo_menu, tm.descripcion AS tipo_menu,
        ARRAY_AGG(cm.id_componente ORDER BY cm.nombre) FILTER (WHERE cm.id_componente IS NOT NULL) AS componentes_ids
    FROM menu m
    JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    LEFT JOIN menu_componentes_menu mcm ON mcm.id_menu = m.id_menu
    LEFT JOIN componente_menu cm ON cm.id_componente = mcm.id_componente
    WHERE m.id_menu = p_id_menu
    GROUP BY m.id_menu, tm.id_tipo_menu, tm.descripcion;
$$;


--
-- Name: fn_pagos_pendientes_verificacion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_pagos_pendientes_verificacion() RETURNS TABLE(id_pago integer, id_evento integer, cliente text, fecha_evento date, fecha_pago date, monto numeric, tipo_pago character varying, concepto character varying, origen character varying, path_comprobante character varying, fecha_registro timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        p.id_pago, p.id_evento,
        pc.primer_nombre || ' ' || pc.primer_apellido AS cliente,
        e.fecha AS fecha_evento,
        p.fecha_pago, p.monto, tp.descripcion AS tipo_pago, p.concepto, p.origen,
        p.path_comprobante, p.fecha_registro
    FROM pago p
    JOIN evento e ON e.id_evento = p.id_evento
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona pc ON pc.id_persona = c.id_persona
    JOIN tc_tipo_pago tp ON tp.id_tipo_pago = p.id_tipo_pago
    WHERE p.estado = 'pendiente'
    ORDER BY p.fecha_registro;
$$;


--
-- Name: fn_pagos_verificados(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_pagos_verificados() RETURNS TABLE(id_pago integer, id_evento integer, cliente text, fecha_evento date, fecha_pago date, monto numeric, tipo_pago character varying, concepto character varying, origen character varying, path_comprobante character varying, verifico text, fecha_registro timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        p.id_pago, p.id_evento,
        pc.primer_nombre || ' ' || pc.primer_apellido AS cliente,
        e.fecha AS fecha_evento,
        p.fecha_pago, p.monto, tp.descripcion AS tipo_pago, p.concepto, p.origen,
        p.path_comprobante,
        pv.primer_nombre || ' ' || pv.primer_apellido AS verifico,
        p.fecha_registro
    FROM pago p
    JOIN evento e ON e.id_evento = p.id_evento
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona pc ON pc.id_persona = c.id_persona
    JOIN tc_tipo_pago tp ON tp.id_tipo_pago = p.id_tipo_pago
    LEFT JOIN empleado ev ON ev.id_empleado = p.id_empleado
    LEFT JOIN persona pv ON pv.id_persona = ev.id_persona
    WHERE p.estado = 'verificado'
    ORDER BY p.fecha_pago DESC;
$$;


--
-- Name: fn_reporte_degustaciones_detallado(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_reporte_degustaciones_detallado(p_fecha_desde date, p_fecha_hasta date) RETURNS TABLE(id_degustacion integer, fecha_sesion date, hora_inicio time without time zone, cliente text, telefono character varying, tipo_evento character varying, fecha_evento date, menus json)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        d.id_degustacion,
        fd.fecha AS fecha_sesion,
        fd.hora_inicio,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        p.telefono,
        te.descripcion AS tipo_evento,
        e.fecha AS fecha_evento,
        COALESCE((
            SELECT json_agg(
                json_build_object(
                    'menu', m.nombre,
                    'es_adicional', dm.es_adicional,
                    'componentes', COALESCE((
                        SELECT json_agg(
                            json_build_object('categoria', cat.descripcion, 'nombre', cm.nombre)
                            ORDER BY cat.id_categoria_componente_menu, cm.nombre
                        )
                        FROM menu_componentes_menu mcm
                        JOIN componente_menu cm ON cm.id_componente = mcm.id_componente
                        JOIN tc_categoria_componente_menu cat ON cat.id_categoria_componente_menu = cm.id_categoria_componente_menu
                        WHERE mcm.id_menu = m.id_menu
                    ), '[]'::json)
                )
                ORDER BY dm.id_degustacion_menu
            )
            FROM degustacion_menu dm
            JOIN menu m ON m.id_menu = dm.id_menu
            WHERE dm.id_degustacion = d.id_degustacion
        ), '[]'::json) AS menus
    FROM degustacion d
    JOIN fechas_degustacion fd ON fd.id_fecha_degustacion = d.id_fecha_degustacion
    JOIN evento e ON e.id_evento = d.id_evento
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    WHERE d.estado != 'cancelada'
      AND fd.fecha BETWEEN p_fecha_desde AND p_fecha_hasta
    ORDER BY fd.fecha, fd.hora_inicio, p.primer_apellido;
$$;


--
-- Name: fn_reporte_eventos_detallado(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_reporte_eventos_detallado(p_fecha_desde date, p_fecha_hasta date) RETURNS TABLE(id_evento integer, fecha date, cliente text, tipo_evento character varying, salones text, estado character varying, total_adultos integer, total_menores integer, total_a_pagar numeric, total_pagado numeric, saldo_pendiente numeric, porcentaje_pagado numeric, tiene_degustacion boolean, total_extras numeric)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        e.id_evento, e.fecha,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        te.descripcion AS tipo_evento,
        STRING_AGG(DISTINCT s.nombre, ', ' ORDER BY s.nombre) AS salones,
        e.estado, e.total_adultos, e.total_menores,
        COALESCE(vs.total_a_pagar, 0) AS total_a_pagar,
        COALESCE(vs.total_pagado, 0) AS total_pagado,
        COALESCE(vs.saldo_pendiente, 0) AS saldo_pendiente,
        COALESCE(vs.porcentaje_pagado, 0) AS porcentaje_pagado,
        EXISTS(SELECT 1 FROM degustacion d WHERE d.id_evento = e.id_evento AND d.estado != 'cancelada') AS tiene_degustacion,
        COALESCE(ex.total, 0) AS total_extras
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    LEFT JOIN tc_tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
    LEFT JOIN evento_salon es ON es.id_evento = e.id_evento
    LEFT JOIN salon s ON s.id_salon = es.id_salon
    LEFT JOIN v_evento_saldo vs ON vs.id_evento = e.id_evento
    LEFT JOIN extras ex ON ex.id_evento = e.id_evento
    WHERE e.fecha BETWEEN p_fecha_desde AND p_fecha_hasta
    GROUP BY e.id_evento, p.primer_nombre, p.primer_apellido, te.descripcion, e.estado, e.total_adultos, e.total_menores,
             vs.total_a_pagar, vs.total_pagado, vs.saldo_pendiente, vs.porcentaje_pagado, ex.total
    ORDER BY e.fecha;
$$;


--
-- Name: fn_reporte_pendientes_pago(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_reporte_pendientes_pago() RETURNS TABLE(id_evento integer, fecha date, dias_para_evento integer, cliente text, total_a_pagar numeric, total_pagado numeric, saldo_pendiente numeric, porcentaje_pagado numeric, checkpoint character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        e.id_evento, e.fecha,
        (e.fecha - CURRENT_DATE) AS dias_para_evento,
        p.primer_nombre || ' ' || p.primer_apellido AS cliente,
        vs.total_a_pagar, vs.total_pagado, vs.saldo_pendiente, vs.porcentaje_pagado,
        CASE WHEN vs.porcentaje_pagado < 0.5 THEN '50%' ELSE '100%' END AS checkpoint
    FROM evento e
    JOIN cliente c ON c.id_cliente = e.id_cliente
    JOIN persona p ON p.id_persona = c.id_persona
    JOIN v_evento_saldo vs ON vs.id_evento = e.id_evento
    WHERE e.estado = 'confirmado' AND vs.porcentaje_pagado < 1
    ORDER BY e.fecha;
$$;


--
-- Name: fn_saldo_evento(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_saldo_evento(p_id_evento integer) RETURNS TABLE(id_evento integer, total_a_pagar numeric, total_pagado numeric, saldo_pendiente numeric, porcentaje_pagado numeric)
    LANGUAGE sql STABLE
    AS $$
    SELECT id_evento, total_a_pagar, total_pagado, saldo_pendiente, porcentaje_pagado
    FROM v_evento_saldo
    WHERE id_evento = p_id_evento;
$$;


--
-- Name: fn_salones_disponibilidad(date, time without time zone, time without time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_salones_disponibilidad(p_fecha date, p_hora_inicio time without time zone, p_hora_fin time without time zone, p_id_evento_excluir integer DEFAULT NULL::integer) RETURNS TABLE(id_salon integer, nombre character varying, capacidad integer, locacion character varying, disponible boolean)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        s.id_salon,
        s.nombre,
        s.capacidad,
        l.nombre AS locacion,
        fn_validar_disponibilidad_salon(s.id_salon, p_fecha, p_hora_inicio, p_hora_fin, p_id_evento_excluir) AS disponible
    FROM salon s
    JOIN locacion l ON l.id_locacion = s.id_locacion
    ORDER BY l.nombre, s.nombre;
$$;


--
-- Name: fn_usuario_auth(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_usuario_auth(p_id_usuario integer) RETURNS TABLE(id_usuario integer, id_persona integer, username character varying, activo boolean, confirmacion boolean, id_rol_acceso integer, rol_acceso character varying)
    LANGUAGE sql STABLE
    AS $$
    SELECT u.id_usuario, u.id_persona, u.username, u.activo, u.confirmacion, u.id_rol_acceso, tra.descripcion
    FROM usuario u
    LEFT JOIN tc_rol_acceso tra ON tra.id_rol_acceso = u.id_rol_acceso
    WHERE u.id_usuario = p_id_usuario;
$$;


--
-- Name: fn_validar_disponibilidad_salon(integer, date, time without time zone, time without time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_validar_disponibilidad_salon(p_id_salon integer, p_fecha date, p_hora_inicio time without time zone, p_hora_fin time without time zone, p_id_evento_excluir integer DEFAULT NULL::integer) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    SELECT NOT EXISTS (
        SELECT 1
        FROM evento_salon es
        JOIN evento e ON e.id_evento = es.id_evento
        LEFT JOIN cotizacion c ON c.id_evento = e.id_evento AND c.activa = true
        WHERE es.id_salon = p_id_salon
          AND e.fecha = p_fecha
          AND (p_id_evento_excluir IS NULL OR e.id_evento != p_id_evento_excluir)
          AND (e.hora_inicio, e.hora_fin) OVERLAPS (p_hora_inicio, p_hora_fin)
          AND (
                e.estado IN ('confirmado', 'en_curso')
                OR (
                    e.estado = 'cotizacion'
                    AND e.reserva_temporal = true
                    AND COALESCE(c.fecha_cotizacion + c.vigencia_dias, e.fecha_creacion::date + 8) >= CURRENT_DATE
                )
              )
    );
$$;


--
-- Name: sp_actualizar_prospecto(integer, character varying, text, integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_actualizar_prospecto(IN p_id_prospecto integer, IN p_estado character varying, IN p_notas_internas text, IN p_id_cliente integer, IN p_id_evento integer)
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


--
-- Name: sp_agendar_degustacion(integer, integer, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_agendar_degustacion(IN p_id_evento integer, IN p_id_fecha_degustacion integer, IN p_notas text, OUT p_id_degustacion integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO degustacion (id_evento, id_fecha_degustacion, estado, notas)
    VALUES (p_id_evento, p_id_fecha_degustacion, 'agendada', p_notas)
    RETURNING id_degustacion INTO p_id_degustacion;
END;
$$;


--
-- Name: sp_agendar_degustacion(integer, integer, time without time zone, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_agendar_degustacion(IN p_id_evento integer, IN p_id_fecha_degustacion integer, IN p_hora_llegada time without time zone, IN p_notas text, OUT p_id_degustacion integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO degustacion (id_evento, id_fecha_degustacion, hora_llegada, estado, notas)
    VALUES (p_id_evento, p_id_fecha_degustacion, p_hora_llegada, 'agendada', p_notas)
    RETURNING id_degustacion INTO p_id_degustacion;
END;
$$;


--
-- Name: sp_agregar_extra_menu(integer, integer, text, integer, numeric, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sp_agregar_extra_menu(p_id_evento integer, p_id_menu integer, p_descripcion text, p_cantidad integer, p_precio_base numeric, p_id_empleado integer, OUT p_id_extras_menu integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_extra INTEGER;
    v_subtotal NUMERIC;
BEGIN
    INSERT INTO extras (id_evento, id_empleado)
    VALUES (p_id_evento, p_id_empleado)
    ON CONFLICT (id_evento) DO NOTHING;

    SELECT id_extra INTO v_id_extra
    FROM extras
    WHERE id_evento = p_id_evento;

    v_subtotal := p_cantidad * p_precio_base;

    INSERT INTO extras_menu (
        id_extra, id_menu, descripcion, cantidad, precio_base, subtotal, estado
    ) VALUES (
        v_id_extra, p_id_menu, p_descripcion, p_cantidad, p_precio_base, v_subtotal, 'aprobado'
    )
    RETURNING id_extras_menu INTO p_id_extras_menu;

    UPDATE extras
    SET total = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM extras_servicios
        WHERE id_extra = v_id_extra AND estado != 'cancelado'
    ) + (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM extras_menu
        WHERE id_extra = v_id_extra AND estado != 'cancelado'
    )
    WHERE id_extra = v_id_extra;
END;
$$;


--
-- Name: sp_agregar_extra_servicio(integer, integer, integer, text, integer, numeric, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sp_agregar_extra_servicio(p_id_evento integer, p_id_tipo_cargo_extra integer, p_id_servicio integer, p_descripcion text, p_cantidad integer, p_precio_unitario numeric, p_id_empleado integer, OUT p_id_extras_servicios integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_extra INTEGER;
    v_subtotal NUMERIC;
BEGIN
    INSERT INTO extras (id_evento, id_empleado)
    VALUES (p_id_evento, p_id_empleado)
    ON CONFLICT (id_evento) DO NOTHING;

    SELECT id_extra INTO v_id_extra
    FROM extras
    WHERE id_evento = p_id_evento;

    v_subtotal := p_cantidad * p_precio_unitario;

    INSERT INTO extras_servicios (
        id_extra, id_servicio, id_tipo_cargo_extra,
        descripcion, cantidad, precio_unitario, subtotal, estado
    ) VALUES (
        v_id_extra, p_id_servicio, p_id_tipo_cargo_extra,
        p_descripcion, p_cantidad, p_precio_unitario, v_subtotal, 'aprobado'
    )
    RETURNING id_extras_servicios INTO p_id_extras_servicios;

    -- Recalcula el total del evento sumando servicios + menús no cancelados
    UPDATE extras
    SET total = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM extras_servicios
        WHERE id_extra = v_id_extra AND estado != 'cancelado'
    ) + (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM extras_menu
        WHERE id_extra = v_id_extra AND estado != 'cancelado'
    )
    WHERE id_extra = v_id_extra;
END;
$$;


--
-- Name: sp_agregar_menu_cotizacion(integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_agregar_menu_cotizacion(IN p_id_cotizacion integer, IN p_id_menu integer, IN p_cantidad integer, OUT p_id_cotizacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_precio_base DECIMAL;
    v_tipo_menu   VARCHAR;
    v_id_evento   INTEGER;
    v_activa      BOOLEAN;
    v_cantidad    INTEGER := p_cantidad;
BEGIN
    SELECT id_evento, activa INTO v_id_evento, v_activa FROM cotizacion WHERE id_cotizacion = p_id_cotizacion;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la cotizacion con id = %', p_id_cotizacion;
    END IF;
    IF NOT v_activa THEN
        RAISE EXCEPTION 'Solo se puede editar la version activa de la cotizacion';
    END IF;

    SELECT m.precio_base, tm.descripcion INTO v_precio_base, v_tipo_menu
    FROM menu m JOIN tc_tipo_menu tm ON tm.id_tipo_menu = m.id_tipo_menu
    WHERE m.id_menu = p_id_menu;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el menu con id = %', p_id_menu;
    END IF;

    IF v_cantidad IS NULL THEN
        SELECT CASE WHEN v_tipo_menu = 'individual_infantil' THEN total_menores ELSE total_adultos END
        INTO v_cantidad FROM evento WHERE id_evento = v_id_evento;
        IF v_cantidad IS NULL OR v_cantidad <= 0 THEN
            RAISE EXCEPTION 'La cantidad automatica es 0 (el evento no tiene % registrados). Indica la cantidad manualmente.',
                CASE WHEN v_tipo_menu = 'individual_infantil' THEN 'ninos' ELSE 'adultos' END;
        END IF;
    ELSIF v_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor a cero';
    END IF;

    INSERT INTO cotizacion_menu (id_cotizacion, id_menu, precio_unitario_congelado, cantidad, subtotal)
    VALUES (p_id_cotizacion, p_id_menu, v_precio_base, v_cantidad, v_precio_base * v_cantidad)
    RETURNING id_cotizacion_menu INTO p_id_cotizacion_menu;

    CALL sp_refrescar_totales_cotizacion(p_id_cotizacion);
END;
$$;


--
-- Name: sp_agregar_menu_degustacion(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_agregar_menu_degustacion(IN p_id_degustacion integer, IN p_id_menu integer, OUT p_id_degustacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_cantidad_actual        INTEGER;
    v_es_adicional           BOOLEAN;
    v_id_evento              INTEGER;
    v_id_cotizacion          INTEGER;
    v_precio_menu            DECIMAL;
    v_id_cotizacion_menu     INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_cantidad_actual FROM degustacion_menu WHERE id_degustacion = p_id_degustacion;

    IF v_cantidad_actual >= 4 THEN
        RAISE EXCEPTION 'Ya se alcanzó el máximo de 4 platillos de degustación para este evento';
    END IF;

    v_es_adicional := v_cantidad_actual >= 2;

    INSERT INTO degustacion_menu (id_degustacion, id_menu, resultado, es_adicional)
    VALUES (p_id_degustacion, p_id_menu, 'pendiente', v_es_adicional)
    RETURNING id_degustacion_menu INTO p_id_degustacion_menu;

    IF v_es_adicional THEN
        SELECT id_evento INTO v_id_evento FROM degustacion WHERE id_degustacion = p_id_degustacion;

        SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion WHERE id_evento = v_id_evento AND activa = true;

        IF v_id_cotizacion IS NULL THEN
            RAISE EXCEPTION 'Este evento no tiene ninguna cotización activa todavía — no se puede cobrar el platillo extra hasta que exista una';
        END IF;

        SELECT precio_base INTO v_precio_menu FROM menu WHERE id_menu = p_id_menu;

        INSERT INTO cotizacion_menu (id_cotizacion, id_menu, precio_unitario_congelado, cantidad, subtotal)
        VALUES (v_id_cotizacion, p_id_menu, v_precio_menu, 1, v_precio_menu)
        RETURNING id_cotizacion_menu INTO v_id_cotizacion_menu;

        UPDATE degustacion_menu
        SET id_cotizacion_menu = v_id_cotizacion_menu
        WHERE id_degustacion_menu = p_id_degustacion_menu;

        CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
    END IF;
END;
$$;


--
-- Name: sp_agregar_servicio_cotizacion(integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_agregar_servicio_cotizacion(IN p_id_cotizacion integer, IN p_id_servicio integer, IN p_cantidad integer, OUT p_id_cotizacion_servicios integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_precio_base DECIMAL;
BEGIN
    SELECT precio_base INTO v_precio_base FROM servicios WHERE id_servicio = p_id_servicio;

    INSERT INTO cotizacion_servicios (id_cotizacion, id_servicio, cantidad, precio_unitario_congelado, subtotal)
    VALUES (p_id_cotizacion, p_id_servicio, p_cantidad, v_precio_base, v_precio_base * p_cantidad)
    RETURNING id_cotizacion_servicios INTO p_id_cotizacion_servicios;

    CALL sp_refrescar_totales_cotizacion(p_id_cotizacion);
END;
$$;


--
-- Name: sp_cambiar_estado_cotizacion(integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_cambiar_estado_cotizacion(IN p_id_cotizacion integer, IN p_nuevo_estado character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_actual VARCHAR;
BEGIN
    SELECT ec.descripcion INTO v_estado_actual
    FROM cotizacion c JOIN tc_estado_cotizacion ec ON ec.id_estado_cotizacion = c.id_estado_cotizacion
    WHERE c.id_cotizacion = p_id_cotizacion;

    IF v_estado_actual IS NULL THEN
        RAISE EXCEPTION 'No existe una cotizacion con id_cotizacion = %', p_id_cotizacion;
    END IF;

    IF NOT (
        (v_estado_actual = 'estimada' AND p_nuevo_estado = 'enviada')
        OR (v_estado_actual = 'enviada' AND p_nuevo_estado IN ('aceptada', 'vencida'))
    ) THEN
        RAISE EXCEPTION 'No se puede pasar de % a %', v_estado_actual, p_nuevo_estado;
    END IF;

    UPDATE cotizacion
    SET id_estado_cotizacion = (SELECT id_estado_cotizacion FROM tc_estado_cotizacion WHERE descripcion = p_nuevo_estado)
    WHERE id_cotizacion = p_id_cotizacion;
END;
$$;


--
-- Name: sp_cambiar_estado_degustacion(integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_cambiar_estado_degustacion(IN p_id_degustacion integer, IN p_nuevo_estado character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM degustacion WHERE id_degustacion = p_id_degustacion) THEN
        RAISE EXCEPTION 'No existe una degustacion con id = %', p_id_degustacion;
    END IF;

    IF p_nuevo_estado NOT IN ('agendada', 'realizada', 'cancelada') THEN
        RAISE EXCEPTION 'Estado invalido: %', p_nuevo_estado;
    END IF;

    UPDATE degustacion
    SET estado = p_nuevo_estado
    WHERE id_degustacion = p_id_degustacion;
END;
$$;


--
-- Name: sp_cambiar_estado_evento(integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_cambiar_estado_evento(IN p_id_evento integer, IN p_nuevo_estado character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_actual VARCHAR;
    v_fecha         DATE;
    v_hora_inicio   TIME;
    v_hora_fin      TIME;
    r_salon         RECORD;
BEGIN
    SELECT estado, fecha, hora_inicio, hora_fin
    INTO v_estado_actual, v_fecha, v_hora_inicio, v_hora_fin
    FROM evento WHERE id_evento = p_id_evento;

    IF v_estado_actual IS NULL THEN
        RAISE EXCEPTION 'No existe un evento con id_evento = %', p_id_evento;
    END IF;

    IF p_nuevo_estado NOT IN ('cotizacion', 'confirmado', 'en_curso', 'cerrado', 'cancelado') THEN
        RAISE EXCEPTION 'Estado inválido: %', p_nuevo_estado;
    END IF;

    -- Transiciones válidas: solo hacia adelante en el ciclo normal, o a cancelado desde cualquier estado activo
    IF NOT (
        (v_estado_actual = 'cotizacion' AND p_nuevo_estado IN ('confirmado', 'cancelado'))
        OR (v_estado_actual = 'confirmado' AND p_nuevo_estado IN ('en_curso', 'cancelado'))
        OR (v_estado_actual = 'en_curso' AND p_nuevo_estado = 'cerrado')
    ) THEN
        RAISE EXCEPTION 'No se puede pasar de % a %', v_estado_actual, p_nuevo_estado;
    END IF;

    -- Al confirmar, la disponibilidad se revalida: desde que se cotizó, otro evento pudo quedar
    -- confirmado en el mismo salon y horario, o tomar la fecha tras vencer una reserva temporal.
    IF p_nuevo_estado = 'confirmado' THEN
        FOR r_salon IN
            SELECT s.id_salon, s.nombre
            FROM evento_salon es
            JOIN salon s ON s.id_salon = es.id_salon
            WHERE es.id_evento = p_id_evento
            ORDER BY s.id_salon
        LOOP
            -- Un candado por salon y fecha: si dos personas confirman a la vez, la segunda espera
            -- a que termine la primera y recien ahi valida (si no, las dos podrian pasar).
            -- Se toman en orden de salon para que nunca se bloqueen entre si.
            PERFORM pg_advisory_xact_lock(r_salon.id_salon, (v_fecha - DATE '2000-01-01'));

            IF NOT fn_validar_disponibilidad_salon(r_salon.id_salon, v_fecha, v_hora_inicio, v_hora_fin, p_id_evento) THEN
                RAISE EXCEPTION 'No se puede confirmar: el salón "%" ya está ocupado el % de % a % (otro evento confirmado o una reserva temporal vigente). Revisá el calendario.',
                    r_salon.nombre, to_char(v_fecha, 'DD/MM/YYYY'), to_char(v_hora_inicio, 'HH24:MI'), to_char(v_hora_fin, 'HH24:MI');
            END IF;
        END LOOP;
    END IF;

    UPDATE evento SET estado = p_nuevo_estado WHERE id_evento = p_id_evento;
END;
$$;


--
-- Name: sp_cambiar_estado_fecha_degustacion(integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_cambiar_estado_fecha_degustacion(IN p_id_fecha_degustacion integer, IN p_nuevo_estado character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM fechas_degustacion WHERE id_fecha_degustacion = p_id_fecha_degustacion) THEN
        RAISE EXCEPTION 'No existe una fecha de degustacion con id = %', p_id_fecha_degustacion;
    END IF;

    IF p_nuevo_estado NOT IN ('disponible', 'llena', 'cancelada') THEN
        RAISE EXCEPTION 'Estado invalido: %', p_nuevo_estado;
    END IF;

    UPDATE fechas_degustacion
    SET estado = p_nuevo_estado
    WHERE id_fecha_degustacion = p_id_fecha_degustacion;
END;
$$;


--
-- Name: sp_cambiar_password(integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_cambiar_password(IN p_id_usuario integer, IN p_password_hash character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario) THEN
        RAISE EXCEPTION 'No existe el usuario con id = %', p_id_usuario;
    END IF;
    UPDATE usuario SET password_hash = p_password_hash WHERE id_usuario = p_id_usuario;
END;
$$;


--
-- Name: sp_cancelar_extra(character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sp_cancelar_extra(p_tipo character varying, p_id_linea integer, OUT p_ok boolean) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_extra INTEGER;
BEGIN
    IF p_tipo = 'servicio' THEN
        UPDATE extras_servicios
        SET estado = 'cancelado'
        WHERE id_extras_servicios = p_id_linea AND estado != 'cancelado'
        RETURNING id_extra INTO v_id_extra;
    ELSIF p_tipo = 'menu' THEN
        UPDATE extras_menu
        SET estado = 'cancelado'
        WHERE id_extras_menu = p_id_linea AND estado != 'cancelado'
        RETURNING id_extra INTO v_id_extra;
    ELSE
        RAISE EXCEPTION 'Tipo de extra inválido: %', p_tipo;
    END IF;

    IF v_id_extra IS NULL THEN
        p_ok := FALSE;
        RETURN;
    END IF;

    UPDATE extras
    SET total = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM extras_servicios
        WHERE id_extra = v_id_extra AND estado != 'cancelado'
    ) + (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM extras_menu
        WHERE id_extra = v_id_extra AND estado != 'cancelado'
    )
    WHERE id_extra = v_id_extra;

    p_ok := TRUE;
END;
$$;


--
-- Name: sp_crear_cliente(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_cliente(IN p_primer_nombre character varying, IN p_segundo_nombre character varying, IN p_primer_apellido character varying, IN p_segundo_apellido character varying, IN p_cui character varying, IN p_nit character varying, IN p_telefono character varying, IN p_correo character varying, OUT p_id_cliente integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_persona    INTEGER;
    v_count_correo  INTEGER;
BEGIN
    -- 1. Buscar por CUI primero (ahora es UNIQUE de verdad, sin ambigüedad posible)
    IF p_cui IS NOT NULL THEN
        SELECT id_persona INTO v_id_persona FROM persona WHERE cui = p_cui;
    END IF;

    -- 2. Sin CUI o sin match por CUI: correo como respaldo, contando primero por si hay ambigüedad
    IF v_id_persona IS NULL AND p_correo IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count_correo FROM persona WHERE correo = p_correo;

        IF v_count_correo > 1 THEN
            RAISE EXCEPTION 'Hay más de una persona con el correo %, no se puede determinar automáticamente cuál usar. Revisar manualmente.', p_correo;
        ELSIF v_count_correo = 1 THEN
            SELECT id_persona INTO v_id_persona FROM persona WHERE correo = p_correo;
        END IF;
    END IF;

    -- 3. Si encontramos una persona existente, solo vincularla (no sobreescribir sus datos)
    IF v_id_persona IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM cliente WHERE id_persona = v_id_persona) THEN
            RAISE EXCEPTION 'Ya existe un cliente para esta persona (id_persona = %)', v_id_persona;
        END IF;

        INSERT INTO cliente (id_persona) VALUES (v_id_persona)
        RETURNING id_cliente INTO p_id_cliente;
        RETURN;
    END IF;

    -- 4. No existe la persona todavía: crearla desde cero, como ya hacía
    INSERT INTO persona (
        primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
        cui, nit, telefono, correo
    )
    VALUES (
        p_primer_nombre, p_segundo_nombre, p_primer_apellido, p_segundo_apellido,
        p_cui, p_nit, p_telefono, p_correo
    )
    RETURNING id_persona INTO v_id_persona;

    INSERT INTO cliente (id_persona)
    VALUES (v_id_persona)
    RETURNING id_cliente INTO p_id_cliente;
END;
$$;


--
-- Name: sp_crear_componente_menu(integer, character varying, numeric); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_componente_menu(IN p_id_categoria_componente_menu integer, IN p_nombre character varying, IN p_recargo numeric, OUT p_id_componente integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO componente_menu (id_categoria_componente_menu, nombre, recargo, activo)
    VALUES (p_id_categoria_componente_menu, p_nombre, p_recargo, true)
    RETURNING id_componente INTO p_id_componente;
END;
$$;


--
-- Name: sp_crear_cotizacion(integer, integer, numeric, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_cotizacion(IN p_id_evento integer, IN p_vigencia_dias integer, IN p_deposito_garantia numeric, IN p_id_empleado integer, OUT p_id_cotizacion integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_nueva_version  INTEGER;
    v_id_anterior    INTEGER;
    v_id_nueva_linea INTEGER;
    r_menu           RECORD;
    r_serv           RECORD;
BEGIN
    -- Version activa actual (la que se va a copiar), antes de desactivarla
    SELECT id_cotizacion INTO v_id_anterior
    FROM cotizacion
    WHERE id_evento = p_id_evento AND activa = true
    ORDER BY version DESC
    LIMIT 1;

    -- Desactivar la version activa anterior, si existe
    UPDATE cotizacion
    SET activa = false,
        id_estado_cotizacion = (SELECT id_estado_cotizacion FROM tc_estado_cotizacion WHERE descripcion = 'reemplazada')
    WHERE id_evento = p_id_evento AND activa = true;

    SELECT COALESCE(MAX(version), 0) + 1 INTO v_nueva_version
    FROM cotizacion WHERE id_evento = p_id_evento;

    -- Encabezado: vigencia y deposito vienen de los parametros; los detalles del evento se heredan
    INSERT INTO cotizacion (
        id_evento, version, fecha_cotizacion, vigencia_dias, deposito_garantia, activa, id_estado_cotizacion, id_empleado,
        brindis, cantidad_mesa_principal, cantidad_mesas_reservadas, id_color_mantel, id_color_cubremanteles, observaciones, boquitas
    )
    SELECT
        p_id_evento, v_nueva_version, CURRENT_DATE, p_vigencia_dias, p_deposito_garantia, true,
        (SELECT id_estado_cotizacion FROM tc_estado_cotizacion WHERE descripcion = 'estimada'),
        p_id_empleado,
        COALESCE(a.brindis, false), a.cantidad_mesa_principal, a.cantidad_mesas_reservadas,
        a.id_color_mantel, a.id_color_cubremanteles, a.observaciones, a.boquitas
    FROM (SELECT 1) AS base
    LEFT JOIN cotizacion a ON a.id_cotizacion = v_id_anterior
    RETURNING id_cotizacion INTO p_id_cotizacion;

    IF v_id_anterior IS NOT NULL THEN
        -- Lineas de menu: mismo precio congelado y cantidad. Si una linea es un platillo extra de
        -- degustacion, el vinculo se mueve a la linea nueva (asi seguira cobrandose y se podra quitar).
        FOR r_menu IN
            SELECT * FROM cotizacion_menu WHERE id_cotizacion = v_id_anterior ORDER BY id_cotizacion_menu
        LOOP
            INSERT INTO cotizacion_menu (id_cotizacion, id_menu, precio_unitario_congelado, cantidad, subtotal)
            VALUES (p_id_cotizacion, r_menu.id_menu, r_menu.precio_unitario_congelado, r_menu.cantidad, r_menu.subtotal)
            RETURNING id_cotizacion_menu INTO v_id_nueva_linea;

            UPDATE degustacion_menu
            SET id_cotizacion_menu = v_id_nueva_linea
            WHERE id_cotizacion_menu = r_menu.id_cotizacion_menu;
        END LOOP;

        -- Lineas de servicio, con sus descuentos aprobados y pendientes (los rechazados no se arrastran)
        FOR r_serv IN
            SELECT * FROM cotizacion_servicios WHERE id_cotizacion = v_id_anterior ORDER BY id_cotizacion_servicios
        LOOP
            INSERT INTO cotizacion_servicios (id_cotizacion, id_servicio, cantidad, precio_unitario_congelado, subtotal)
            VALUES (p_id_cotizacion, r_serv.id_servicio, r_serv.cantidad, r_serv.precio_unitario_congelado, r_serv.subtotal)
            RETURNING id_cotizacion_servicios INTO v_id_nueva_linea;

            INSERT INTO cotizacion_servicios_descuento (
                id_cotizacion_servicios, id_tipo_descuento, porcentaje, monto_descontado, motivo, estado,
                id_empleado_solicito, id_empleado_aprobo, fecha_creacion
            )
            SELECT v_id_nueva_linea, id_tipo_descuento, porcentaje, monto_descontado, motivo, estado,
                   id_empleado_solicito, id_empleado_aprobo, fecha_creacion
            FROM cotizacion_servicios_descuento
            WHERE id_cotizacion_servicios = r_serv.id_cotizacion_servicios
              AND estado IN ('aprobado', 'pendiente');
        END LOOP;

        CALL sp_refrescar_totales_cotizacion(p_id_cotizacion);
    END IF;
END;
$$;


--
-- Name: sp_crear_descuento_servicio(integer, integer, numeric, numeric, text, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_descuento_servicio(IN p_id_cotizacion_servicios integer, IN p_id_tipo_descuento integer, IN p_porcentaje numeric, IN p_monto_descontado numeric, IN p_motivo text, IN p_id_empleado_solicito integer, OUT p_id_descuento integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_subtotal_linea DECIMAL;
    v_monto_final    DECIMAL;
BEGIN
    SELECT subtotal INTO v_subtotal_linea FROM cotizacion_servicios WHERE id_cotizacion_servicios = p_id_cotizacion_servicios;

    IF v_subtotal_linea IS NULL THEN
        RAISE EXCEPTION 'No existe una linea de servicio con id_cotizacion_servicios = %', p_id_cotizacion_servicios;
    END IF;

    IF p_porcentaje IS NOT NULL THEN
        v_monto_final := ROUND(v_subtotal_linea * p_porcentaje / 100, 2);
    ELSE
        v_monto_final := p_monto_descontado;
    END IF;

    IF v_monto_final IS NULL OR v_monto_final <= 0 THEN
        RAISE EXCEPTION 'El descuento debe ser un monto o porcentaje mayor a cero';
    END IF;

    INSERT INTO cotizacion_servicios_descuento (
        id_cotizacion_servicios, id_tipo_descuento, porcentaje, monto_descontado, motivo, estado, id_empleado_solicito
    )
    VALUES (
        p_id_cotizacion_servicios, p_id_tipo_descuento, p_porcentaje, v_monto_final, p_motivo, 'pendiente', p_id_empleado_solicito
    )
    RETURNING id_descuento INTO p_id_descuento;
END;
$$;


--
-- Name: sp_crear_evento(integer, integer, date, time without time zone, time without time zone, integer, integer, text, boolean, integer[]); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_evento(IN p_id_cliente integer, IN p_id_tipo_evento integer, IN p_fecha date, IN p_hora_inicio time without time zone, IN p_hora_fin time without time zone, IN p_total_adultos integer, IN p_total_menores integer, IN p_notas text, IN p_reserva_temporal boolean, IN p_salones integer[], OUT p_id_evento integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_salon INTEGER;
BEGIN
    -- Validar disponibilidad de todos los salones ANTES de insertar nada
    FOREACH v_id_salon IN ARRAY p_salones
    LOOP
        IF NOT fn_validar_disponibilidad_salon(v_id_salon, p_fecha, p_hora_inicio, p_hora_fin) THEN
            RAISE EXCEPTION 'El salón % no está disponible en esa fecha y horario', v_id_salon;
        END IF;
    END LOOP;

    INSERT INTO evento (
        id_cliente, id_tipo_evento, fecha, hora_inicio, hora_fin,
        total_adultos, total_menores, notas, reserva_temporal, estado
    )
    VALUES (
        p_id_cliente, p_id_tipo_evento, p_fecha, p_hora_inicio, p_hora_fin,
        p_total_adultos, p_total_menores, p_notas, p_reserva_temporal, 'cotizacion'
    )
    RETURNING id_evento INTO p_id_evento;

    FOREACH v_id_salon IN ARRAY p_salones
    LOOP
        INSERT INTO evento_salon (id_evento, id_salon)
        VALUES (p_id_evento, v_id_salon);
    END LOOP;
END;
$$;


--
-- Name: sp_crear_fecha_degustacion(date, time without time zone); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_fecha_degustacion(IN p_fecha date, IN p_hora time without time zone, OUT p_id_fecha_degustacion integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO fechas_degustacion (fecha, hora, estado)
    VALUES (p_fecha, p_hora, 'disponible')
    RETURNING id_fecha_degustacion INTO p_id_fecha_degustacion;
END;
$$;


--
-- Name: sp_crear_fecha_degustacion(date, time without time zone, time without time zone); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_fecha_degustacion(IN p_fecha date, IN p_hora_inicio time without time zone, IN p_hora_fin time without time zone, OUT p_id_fecha_degustacion integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO fechas_degustacion (fecha, hora_inicio, hora_fin, estado)
    VALUES (p_fecha, p_hora_inicio, p_hora_fin, 'disponible')
    RETURNING id_fecha_degustacion INTO p_id_fecha_degustacion;
END;
$$;


--
-- Name: sp_crear_menu(character varying, integer, numeric, character varying, text, integer[]); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_menu(IN p_nombre character varying, IN p_id_tipo_menu integer, IN p_precio_base numeric, IN p_unidad_medida character varying, IN p_descripcion text, IN p_componentes integer[], OUT p_id_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_componente INTEGER;
BEGIN
    INSERT INTO menu (nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, activo)
    VALUES (p_nombre, p_id_tipo_menu, p_precio_base, p_unidad_medida, p_descripcion, true)
    RETURNING id_menu INTO p_id_menu;

    FOREACH v_id_componente IN ARRAY p_componentes
    LOOP
        INSERT INTO menu_componentes_menu (id_menu, id_componente)
        VALUES (p_id_menu, v_id_componente);
    END LOOP;
END;
$$;


--
-- Name: sp_crear_menu_personalizado(integer, character varying, integer, numeric, text, integer[], integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_menu_personalizado(IN p_id_cotizacion integer, IN p_nombre character varying, IN p_id_tipo_menu integer, IN p_precio numeric, IN p_descripcion text, IN p_componentes integer[], IN p_cantidad integer, OUT p_id_menu integer, OUT p_id_cotizacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_evento  INTEGER;
    v_activa     BOOLEAN;
    v_unidad     VARCHAR;
    v_nombre     VARCHAR := TRIM(p_nombre);
    v_ids        INTEGER[];
    v_validos    INTEGER;
BEGIN
    SELECT id_evento, activa INTO v_id_evento, v_activa FROM cotizacion WHERE id_cotizacion = p_id_cotizacion;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la cotizacion con id = %', p_id_cotizacion;
    END IF;
    IF NOT v_activa THEN
        RAISE EXCEPTION 'Solo se puede agregar un menu a la version activa de la cotizacion';
    END IF;
    IF v_nombre IS NULL OR v_nombre = '' THEN
        RAISE EXCEPTION 'El nombre del menu es obligatorio';
    END IF;
    IF p_precio IS NULL OR p_precio <= 0 THEN
        RAISE EXCEPTION 'El precio debe ser mayor a cero';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tc_tipo_menu WHERE id_tipo_menu = p_id_tipo_menu) THEN
        RAISE EXCEPTION 'Tipo de menu invalido';
    END IF;

    SELECT ARRAY_AGG(DISTINCT t.x) INTO v_ids FROM UNNEST(COALESCE(p_componentes, ARRAY[]::INTEGER[])) AS t(x);
    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'Elegi al menos un componente';
    END IF;

    SELECT COUNT(*) INTO v_validos FROM componente_menu WHERE id_componente = ANY(v_ids) AND activo;
    IF v_validos <> array_length(v_ids, 1) THEN
        RAISE EXCEPTION 'Alguno de los componentes no existe o esta inactivo';
    END IF;

    SELECT unidad_medida INTO v_unidad
    FROM menu WHERE id_tipo_menu = p_id_tipo_menu AND NOT es_personalizado
    ORDER BY id_menu LIMIT 1;
    v_unidad := COALESCE(v_unidad, 'por_persona');

    INSERT INTO menu (nombre, id_tipo_menu, precio_base, unidad_medida, descripcion, activo, es_personalizado, id_evento)
    VALUES (v_nombre, p_id_tipo_menu, p_precio, v_unidad, NULLIF(TRIM(p_descripcion), ''), true, true, v_id_evento)
    RETURNING id_menu INTO p_id_menu;

    INSERT INTO menu_componentes_menu (id_menu, id_componente)
    SELECT p_id_menu, UNNEST(v_ids);

    CALL sp_agregar_menu_cotizacion(p_id_cotizacion, p_id_menu, p_cantidad, p_id_cotizacion_menu);
END;
$$;


--
-- Name: sp_crear_prospecto(character varying, character varying, character varying, integer, integer, date, integer, text, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_prospecto(IN p_nombre character varying, IN p_telefono character varying, IN p_correo character varying, IN p_id_tipo_evento integer, IN p_id_salon integer, IN p_fecha_tentativa date, IN p_invitados integer, IN p_mensaje text, IN p_ip_origen character varying, OUT p_id_prospecto integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        RAISE EXCEPTION 'Falta el nombre';
    END IF;
    IF p_telefono IS NULL OR TRIM(p_telefono) = '' THEN
        RAISE EXCEPTION 'Falta el teléfono';
    END IF;
    IF p_fecha_tentativa IS NOT NULL AND p_fecha_tentativa < CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha tentativa no puede estar en el pasado';
    END IF;

    INSERT INTO prospecto (
        nombre, telefono, correo, id_tipo_evento, id_salon,
        fecha_tentativa, invitados, mensaje, ip_origen
    )
    VALUES (
        TRIM(p_nombre), TRIM(p_telefono), NULLIF(TRIM(p_correo), ''), p_id_tipo_evento, p_id_salon,
        p_fecha_tentativa, p_invitados, NULLIF(TRIM(p_mensaje), ''), p_ip_origen
    )
    RETURNING id_prospecto INTO p_id_prospecto;
END;
$$;


--
-- Name: sp_crear_servicio(integer, character varying, numeric, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_servicio(IN p_id_categoria_servicio integer, IN p_nombre character varying, IN p_precio_base numeric, IN p_unidad_medida character varying, OUT p_id_servicio integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO servicios (id_categoria_servicio, nombre, precio_base, unidad_medida, activo)
    VALUES (p_id_categoria_servicio, p_nombre, p_precio_base, p_unidad_medida, true)
    RETURNING id_servicio INTO p_id_servicio;
END;
$$;


--
-- Name: sp_crear_usuario(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_usuario(IN p_primer_nombre character varying, IN p_segundo_nombre character varying, IN p_primer_apellido character varying, IN p_segundo_apellido character varying, IN p_cui character varying, IN p_telefono character varying, IN p_correo character varying, IN p_username character varying, IN p_password_hash character varying, IN p_id_rol_acceso integer, IN p_id_tipo_empleado integer, OUT p_id_usuario integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_cui             VARCHAR := NULLIF(TRIM(p_cui), '');
    v_correo          VARCHAR := NULLIF(TRIM(p_correo), '');
    v_telefono        VARCHAR := NULLIF(TRIM(p_telefono), '');
    v_username        VARCHAR := TRIM(p_username);
    v_id_persona      INTEGER;
    v_count_correo    INTEGER;
    v_id_empleado     INTEGER;
    v_id_tipo_usuario INTEGER;
BEGIN
    IF v_username IS NULL OR v_username = '' THEN
        RAISE EXCEPTION 'El nombre de usuario es obligatorio';
    END IF;
    IF EXISTS (SELECT 1 FROM usuario WHERE LOWER(username) = LOWER(v_username)) THEN
        RAISE EXCEPTION 'El usuario "%" ya existe', v_username;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tc_rol_acceso WHERE id_rol_acceso = p_id_rol_acceso) THEN
        RAISE EXCEPTION 'Rol invalido';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tc_tipo_empleado WHERE id_tipo_empleado = p_id_tipo_empleado) THEN
        RAISE EXCEPTION 'Tipo de empleado invalido';
    END IF;

    SELECT id_tipo_usuario INTO v_id_tipo_usuario FROM tc_tipo_usuario WHERE descripcion = 'staff';

    -- Buscar persona existente: CUI primero, correo como respaldo
    IF v_cui IS NOT NULL THEN
        SELECT id_persona INTO v_id_persona FROM persona WHERE cui = v_cui;
    END IF;
    IF v_id_persona IS NULL AND v_correo IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count_correo FROM persona WHERE correo = v_correo;
        IF v_count_correo > 1 THEN
            RAISE EXCEPTION 'Hay mas de una persona con el correo %, no se puede determinar cual usar. Revisar manualmente.', v_correo;
        ELSIF v_count_correo = 1 THEN
            SELECT id_persona INTO v_id_persona FROM persona WHERE correo = v_correo;
        END IF;
    END IF;

    IF v_id_persona IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM usuario WHERE id_persona = v_id_persona) THEN
            RAISE EXCEPTION 'Esta persona ya tiene un usuario';
        END IF;
    ELSE
        IF NULLIF(TRIM(p_primer_nombre), '') IS NULL OR NULLIF(TRIM(p_primer_apellido), '') IS NULL THEN
            RAISE EXCEPTION 'Primer nombre y primer apellido son obligatorios';
        END IF;
        INSERT INTO persona (primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cui, telefono, correo)
        VALUES (TRIM(p_primer_nombre), NULLIF(TRIM(p_segundo_nombre), ''), TRIM(p_primer_apellido), NULLIF(TRIM(p_segundo_apellido), ''), v_cui, v_telefono, v_correo)
        RETURNING id_persona INTO v_id_persona;
    END IF;

    -- Empleado: reutilizar si ya existe, crear si no
    SELECT id_empleado INTO v_id_empleado FROM empleado WHERE id_persona = v_id_persona ORDER BY id_empleado LIMIT 1;
    IF v_id_empleado IS NULL THEN
        INSERT INTO empleado (id_persona, id_tipo_empleado, activo, fecha_creacion)
        VALUES (v_id_persona, p_id_tipo_empleado, true, now());
    ELSE
        UPDATE empleado SET activo = true WHERE id_empleado = v_id_empleado;
    END IF;

    INSERT INTO usuario (id_persona, id_tipo_usuario, username, password_hash, confirmacion, id_rol_acceso, fecha_creacion)
    VALUES (v_id_persona, v_id_tipo_usuario, v_username, p_password_hash, true, p_id_rol_acceso, now())
    RETURNING id_usuario INTO p_id_usuario;
END;
$$;


--
-- Name: sp_crear_usuario(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_usuario(IN p_primer_nombre character varying, IN p_segundo_nombre character varying, IN p_primer_apellido character varying, IN p_segundo_apellido character varying, IN p_cui character varying, IN p_nit character varying, IN p_telefono character varying, IN p_correo character varying, IN p_username character varying, IN p_password_hash character varying, IN p_id_tipo_usuario integer, IN p_id_tipo_empleado integer, OUT p_id_usuario integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_persona INTEGER;
BEGIN
    INSERT INTO persona (
        primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
        cui, nit, telefono, correo
    )
    VALUES (
        p_primer_nombre, p_segundo_nombre, p_primer_apellido, p_segundo_apellido,
        p_cui, p_nit, p_telefono, p_correo
    )
    RETURNING id_persona INTO v_id_persona;

    INSERT INTO empleado (id_persona, id_tipo_empleado)
    VALUES (v_id_persona, p_id_tipo_empleado);

    INSERT INTO usuario (id_persona, id_tipo_usuario, username, password_hash, confirmacion)
    VALUES (v_id_persona, p_id_tipo_usuario, p_username, p_password_hash, true)
    RETURNING id_usuario INTO p_id_usuario;
END;
$$;


--
-- Name: sp_editar_cantidad_menu_cotizacion(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_editar_cantidad_menu_cotizacion(IN p_id_cotizacion_menu integer, IN p_cantidad integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_cotizacion INTEGER;
    v_activa        BOOLEAN;
BEGIN
    SELECT cm.id_cotizacion, c.activa INTO v_id_cotizacion, v_activa
    FROM cotizacion_menu cm
    JOIN cotizacion c ON c.id_cotizacion = cm.id_cotizacion
    WHERE cm.id_cotizacion_menu = p_id_cotizacion_menu;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe esa linea de menu';
    END IF;
    IF NOT v_activa THEN
        RAISE EXCEPTION 'Solo se puede editar la version activa de la cotizacion';
    END IF;
    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor a cero';
    END IF;
    IF EXISTS (SELECT 1 FROM degustacion_menu WHERE id_cotizacion_menu = p_id_cotizacion_menu) THEN
        RAISE EXCEPTION 'Esta linea es un platillo extra de degustacion: se cobra de a uno y no se edita. Quitala desde Degustacion.';
    END IF;

    UPDATE cotizacion_menu
    SET cantidad = p_cantidad,
        subtotal = precio_unitario_congelado * p_cantidad
    WHERE id_cotizacion_menu = p_id_cotizacion_menu;

    CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
END;
$$;


--
-- Name: sp_editar_cliente(integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_editar_cliente(IN p_id_cliente integer, IN p_primer_nombre character varying, IN p_segundo_nombre character varying, IN p_primer_apellido character varying, IN p_segundo_apellido character varying, IN p_cui character varying, IN p_nit character varying, IN p_telefono character varying, IN p_correo character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_persona INTEGER;
BEGIN
    SELECT id_persona INTO v_id_persona
    FROM cliente
    WHERE id_cliente = p_id_cliente;

    IF v_id_persona IS NULL THEN
        RAISE EXCEPTION 'No existe un cliente con id_cliente = %', p_id_cliente;
    END IF;

    UPDATE persona
    SET
        primer_nombre = p_primer_nombre,
        segundo_nombre = p_segundo_nombre,
        primer_apellido = p_primer_apellido,
        segundo_apellido = p_segundo_apellido,
        cui = p_cui,
        nit = p_nit,
        telefono = p_telefono,
        correo = p_correo
    WHERE id_persona = v_id_persona;
END;
$$;


--
-- Name: sp_editar_componente_menu(integer, integer, character varying, numeric, boolean); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_editar_componente_menu(IN p_id_componente integer, IN p_id_categoria_componente_menu integer, IN p_nombre character varying, IN p_recargo numeric, IN p_activo boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM componente_menu WHERE id_componente = p_id_componente) THEN
        RAISE EXCEPTION 'No existe un componente con id_componente = %', p_id_componente;
    END IF;

    UPDATE componente_menu
    SET id_categoria_componente_menu = p_id_categoria_componente_menu,
        nombre = p_nombre,
        recargo = p_recargo,
        activo = p_activo
    WHERE id_componente = p_id_componente;
END;
$$;


--
-- Name: sp_editar_cotizacion(integer, boolean, integer, integer, integer, integer, text, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_editar_cotizacion(IN p_id_cotizacion integer, IN p_brindis boolean, IN p_cantidad_mesa_principal integer, IN p_cantidad_mesas_reservadas integer, IN p_id_color_mantel integer, IN p_id_color_cubremanteles integer, IN p_observaciones text, IN p_boquitas text)
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


--
-- Name: sp_editar_evento(integer, integer, date, time without time zone, time without time zone, integer, integer, text, boolean, integer[]); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_editar_evento(IN p_id_evento integer, IN p_id_tipo_evento integer, IN p_fecha date, IN p_hora_inicio time without time zone, IN p_hora_fin time without time zone, IN p_total_adultos integer, IN p_total_menores integer, IN p_notas text, IN p_reserva_temporal boolean, IN p_salones integer[])
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_salon INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM evento WHERE id_evento = p_id_evento) THEN
        RAISE EXCEPTION 'No existe un evento con id_evento = %', p_id_evento;
    END IF;

    -- Validar disponibilidad, excluyendo este mismo evento (para no chocar contra sí mismo)
    FOREACH v_id_salon IN ARRAY p_salones
    LOOP
        IF NOT fn_validar_disponibilidad_salon(v_id_salon, p_fecha, p_hora_inicio, p_hora_fin, p_id_evento) THEN
            RAISE EXCEPTION 'El salón % no está disponible en esa fecha y horario', v_id_salon;
        END IF;
    END LOOP;

    UPDATE evento
    SET
        id_tipo_evento = p_id_tipo_evento,
        fecha = p_fecha,
        hora_inicio = p_hora_inicio,
        hora_fin = p_hora_fin,
        total_adultos = p_total_adultos,
        total_menores = p_total_menores,
        notas = p_notas,
        reserva_temporal = p_reserva_temporal
    WHERE id_evento = p_id_evento;

    DELETE FROM evento_salon WHERE id_evento = p_id_evento;

    FOREACH v_id_salon IN ARRAY p_salones
    LOOP
        INSERT INTO evento_salon (id_evento, id_salon)
        VALUES (p_id_evento, v_id_salon);
    END LOOP;
END;
$$;


--
-- Name: sp_editar_menu(integer, character varying, integer, numeric, character varying, text, boolean, integer[]); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_editar_menu(IN p_id_menu integer, IN p_nombre character varying, IN p_id_tipo_menu integer, IN p_precio_base numeric, IN p_unidad_medida character varying, IN p_descripcion text, IN p_activo boolean, IN p_componentes integer[])
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_componente INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM menu WHERE id_menu = p_id_menu) THEN
        RAISE EXCEPTION 'No existe un menu con id_menu = %', p_id_menu;
    END IF;

    UPDATE menu
    SET nombre = p_nombre, id_tipo_menu = p_id_tipo_menu, precio_base = p_precio_base,
        unidad_medida = p_unidad_medida, descripcion = p_descripcion, activo = p_activo
    WHERE id_menu = p_id_menu;

    DELETE FROM menu_componentes_menu WHERE id_menu = p_id_menu;

    FOREACH v_id_componente IN ARRAY p_componentes
    LOOP
        INSERT INTO menu_componentes_menu (id_menu, id_componente)
        VALUES (p_id_menu, v_id_componente);
    END LOOP;
END;
$$;


--
-- Name: sp_editar_servicio(integer, integer, character varying, numeric, character varying, boolean); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_editar_servicio(IN p_id_servicio integer, IN p_id_categoria_servicio integer, IN p_nombre character varying, IN p_precio_base numeric, IN p_unidad_medida character varying, IN p_activo boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM servicios WHERE id_servicio = p_id_servicio) THEN
        RAISE EXCEPTION 'No existe un servicio con id_servicio = %', p_id_servicio;
    END IF;

    UPDATE servicios
    SET id_categoria_servicio = p_id_categoria_servicio,
        nombre = p_nombre,
        precio_base = p_precio_base,
        unidad_medida = p_unidad_medida,
        activo = p_activo
    WHERE id_servicio = p_id_servicio;
END;
$$;


--
-- Name: sp_editar_usuario(integer, integer, boolean); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_editar_usuario(IN p_id_usuario integer, IN p_id_rol_acceso integer, IN p_activo boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rol_actual            VARCHAR;
    v_activo_actual         BOOLEAN;
    v_rol_nuevo             VARCHAR;
    v_otros_superusuarios   INTEGER;
BEGIN
    IF p_activo IS NULL THEN
        RAISE EXCEPTION 'Falta indicar si el usuario queda activo';
    END IF;

    SELECT tra.descripcion, u.activo INTO v_rol_actual, v_activo_actual
    FROM usuario u
    LEFT JOIN tc_rol_acceso tra ON tra.id_rol_acceso = u.id_rol_acceso
    WHERE u.id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el usuario con id = %', p_id_usuario;
    END IF;

    SELECT descripcion INTO v_rol_nuevo FROM tc_rol_acceso WHERE id_rol_acceso = p_id_rol_acceso;
    IF v_rol_nuevo IS NULL THEN
        RAISE EXCEPTION 'Rol invalido';
    END IF;

    IF v_rol_actual = 'Superusuario' AND v_activo_actual AND (v_rol_nuevo <> 'Superusuario' OR NOT p_activo) THEN
        SELECT COUNT(*) INTO v_otros_superusuarios
        FROM usuario u
        JOIN tc_rol_acceso tra ON tra.id_rol_acceso = u.id_rol_acceso
        WHERE tra.descripcion = 'Superusuario' AND u.activo AND u.id_usuario <> p_id_usuario;

        IF v_otros_superusuarios = 0 THEN
            RAISE EXCEPTION 'No se puede dejar el sistema sin un Superusuario activo';
        END IF;
    END IF;

    UPDATE usuario SET id_rol_acceso = p_id_rol_acceso, activo = p_activo WHERE id_usuario = p_id_usuario;
END;
$$;


--
-- Name: sp_quitar_menu_cotizacion(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_quitar_menu_cotizacion(IN p_id_cotizacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_cotizacion INTEGER;
BEGIN
    SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion_menu WHERE id_cotizacion_menu = p_id_cotizacion_menu;

    DELETE FROM cotizacion_menu WHERE id_cotizacion_menu = p_id_cotizacion_menu;

    CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
END;
$$;


--
-- Name: sp_quitar_menu_degustacion(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_quitar_menu_degustacion(IN p_id_degustacion_menu integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_cotizacion_menu  INTEGER;
    v_id_cotizacion       INTEGER;
BEGIN
    SELECT id_cotizacion_menu INTO v_id_cotizacion_menu
    FROM degustacion_menu WHERE id_degustacion_menu = p_id_degustacion_menu;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe esa línea de degustación';
    END IF;

    -- Borrar primero la fila hija (degustacion_menu), antes de tocar la madre (cotizacion_menu)
    DELETE FROM degustacion_menu WHERE id_degustacion_menu = p_id_degustacion_menu;

    IF v_id_cotizacion_menu IS NOT NULL THEN
        SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion_menu WHERE id_cotizacion_menu = v_id_cotizacion_menu;
        DELETE FROM cotizacion_menu WHERE id_cotizacion_menu = v_id_cotizacion_menu;
        CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
    END IF;
END;
$$;


--
-- Name: sp_quitar_servicio_cotizacion(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_quitar_servicio_cotizacion(IN p_id_cotizacion_servicios integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_cotizacion INTEGER;
BEGIN
    SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion_servicios WHERE id_cotizacion_servicios = p_id_cotizacion_servicios;

    DELETE FROM cotizacion_servicios WHERE id_cotizacion_servicios = p_id_cotizacion_servicios;

    CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
END;
$$;


--
-- Name: sp_refrescar_totales_cotizacion(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_refrescar_totales_cotizacion(IN p_id_cotizacion integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE cotizacion c
    SET subtotal_menus = vc.subtotal_menus,
        subtotal_servicios = vc.subtotal_servicios,
        total_descuento = vc.total_descuento,
        total = vc.total
    FROM v_cotizacion_calculada vc
    WHERE vc.id_cotizacion = c.id_cotizacion AND c.id_cotizacion = p_id_cotizacion;
END;
$$;


--
-- Name: sp_registrar_acceso(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_registrar_acceso(IN p_id_usuario integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE usuario
    SET fecha_ultimo_acceso = now()
    WHERE id_usuario = p_id_usuario;
END;
$$;


--
-- Name: sp_registrar_pago(integer, date, numeric, integer, character varying, character varying, integer, character varying, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_registrar_pago(IN p_id_evento integer, IN p_fecha_pago date, IN p_monto numeric, IN p_id_tipo_pago integer, IN p_concepto character varying, IN p_origen character varying, IN p_id_empleado integer, IN p_path_comprobante character varying, IN p_notas text, OUT p_id_pago integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO pago (
        id_evento, fecha_pago, monto, id_tipo_pago, concepto,
        id_empleado, estado, origen, path_comprobante, notas
    )
    VALUES (
        p_id_evento, p_fecha_pago, p_monto, p_id_tipo_pago, p_concepto,
        p_id_empleado, 'pendiente', p_origen, p_path_comprobante, p_notas
    )
    RETURNING id_pago INTO p_id_pago;
END;
$$;


--
-- Name: sp_registrar_recordatorio_enviado(integer, integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_registrar_recordatorio_enviado(IN p_id_evento integer, IN p_id_tipo_recordatorio integer, IN p_correo_destino character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO recordatorio_enviado (id_evento, id_tipo_recordatorio, correo_destino, fecha_envio)
    VALUES (p_id_evento, p_id_tipo_recordatorio, p_correo_destino, now());
END;
$$;


--
-- Name: sp_resolver_degustacion(integer, character varying, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_resolver_degustacion(IN p_id_degustacion integer, IN p_resultado character varying, IN p_motivo_rechazo text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado VARCHAR;
BEGIN
    SELECT estado INTO v_estado FROM degustacion WHERE id_degustacion = p_id_degustacion;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe una degustacion con id = %', p_id_degustacion;
    END IF;

    IF v_estado <> 'realizada' THEN
        RAISE EXCEPTION 'Solo se puede registrar el resultado de una degustacion ya realizada (estado actual: %)', v_estado;
    END IF;

    IF p_resultado NOT IN ('aprobada', 'rechazada') THEN
        RAISE EXCEPTION 'Resultado invalido: %', p_resultado;
    END IF;

    IF p_resultado = 'rechazada' AND (p_motivo_rechazo IS NULL OR TRIM(p_motivo_rechazo) = '') THEN
        RAISE EXCEPTION 'El motivo de rechazo es obligatorio';
    END IF;

    UPDATE degustacion
    SET resultado = p_resultado,
        motivo_rechazo = CASE WHEN p_resultado = 'rechazada' THEN TRIM(p_motivo_rechazo) ELSE NULL END
    WHERE id_degustacion = p_id_degustacion;
END;
$$;


--
-- Name: sp_resolver_descuento_servicio(integer, character varying, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_resolver_descuento_servicio(IN p_id_descuento integer, IN p_nuevo_estado character varying, IN p_id_empleado_aprobo integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_cotizacion_servicios INTEGER;
    v_id_cotizacion           INTEGER;
    v_estado_actual           VARCHAR;
BEGIN
    SELECT csd.id_cotizacion_servicios, csd.estado INTO v_id_cotizacion_servicios, v_estado_actual
    FROM cotizacion_servicios_descuento csd
    WHERE csd.id_descuento = p_id_descuento;

    IF v_id_cotizacion_servicios IS NULL THEN
        RAISE EXCEPTION 'No existe un descuento con id_descuento = %', p_id_descuento;
    END IF;

    IF v_estado_actual != 'pendiente' THEN
        RAISE EXCEPTION 'Este descuento ya fue % y no se puede modificar', v_estado_actual;
    END IF;

    IF p_nuevo_estado NOT IN ('aprobado', 'rechazado') THEN
        RAISE EXCEPTION 'Estado invalido: %', p_nuevo_estado;
    END IF;

    UPDATE cotizacion_servicios_descuento
    SET estado = p_nuevo_estado,
        id_empleado_aprobo = p_id_empleado_aprobo
    WHERE id_descuento = p_id_descuento;

    SELECT id_cotizacion INTO v_id_cotizacion FROM cotizacion_servicios WHERE id_cotizacion_servicios = v_id_cotizacion_servicios;

    CALL sp_refrescar_totales_cotizacion(v_id_cotizacion);
END;
$$;


--
-- Name: sp_resolver_menu_degustacion(integer, character varying, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_resolver_menu_degustacion(IN p_id_degustacion_menu integer, IN p_resultado character varying, IN p_notas text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM degustacion_menu WHERE id_degustacion_menu = p_id_degustacion_menu) THEN
        RAISE EXCEPTION 'No existe una linea de degustacion_menu con id = %', p_id_degustacion_menu;
    END IF;

    IF p_resultado NOT IN ('pendiente', 'aprobado', 'rechazado') THEN
        RAISE EXCEPTION 'Resultado invalido: %', p_resultado;
    END IF;

    UPDATE degustacion_menu
    SET resultado = p_resultado,
        notas = p_notas
    WHERE id_degustacion_menu = p_id_degustacion_menu;
END;
$$;


--
-- Name: sp_verificar_pago(integer, character varying, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_verificar_pago(IN p_id_pago integer, IN p_nuevo_estado character varying, IN p_id_empleado integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_actual VARCHAR;
BEGIN
    SELECT estado INTO v_estado_actual FROM pago WHERE id_pago = p_id_pago;

    IF v_estado_actual IS NULL THEN
        RAISE EXCEPTION 'No existe un pago con id_pago = %', p_id_pago;
    END IF;

    IF v_estado_actual != 'pendiente' THEN
        RAISE EXCEPTION 'Este pago ya fue % y no se puede modificar', v_estado_actual;
    END IF;

    IF p_nuevo_estado NOT IN ('verificado', 'rechazado') THEN
        RAISE EXCEPTION 'Estado invalido: %', p_nuevo_estado;
    END IF;

    UPDATE pago
    SET estado = p_nuevo_estado,
        id_empleado = p_id_empleado
    WHERE id_pago = p_id_pago;
END;
$$;


--
-- Name: sp_verificar_pago(integer, character varying, integer, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_verificar_pago(IN p_id_pago integer, IN p_nuevo_estado character varying, IN p_id_empleado integer, IN p_motivo_rechazo text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_actual VARCHAR;
BEGIN
    SELECT estado INTO v_estado_actual FROM pago WHERE id_pago = p_id_pago;

    IF v_estado_actual IS NULL THEN
        RAISE EXCEPTION 'No existe un pago con id_pago = %', p_id_pago;
    END IF;

    IF v_estado_actual != 'pendiente' THEN
        RAISE EXCEPTION 'Este pago ya fue % y no se puede modificar', v_estado_actual;
    END IF;

    IF p_nuevo_estado NOT IN ('verificado', 'rechazado') THEN
        RAISE EXCEPTION 'Estado invalido: %', p_nuevo_estado;
    END IF;

    IF p_nuevo_estado = 'rechazado' AND (p_motivo_rechazo IS NULL OR TRIM(p_motivo_rechazo) = '') THEN
        RAISE EXCEPTION 'Hace falta indicar el motivo del rechazo';
    END IF;

    UPDATE pago
    SET estado = p_nuevo_estado,
        id_empleado = p_id_empleado,
        motivo_rechazo = CASE WHEN p_nuevo_estado = 'rechazado' THEN p_motivo_rechazo ELSE NULL END
    WHERE id_pago = p_id_pago;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente (
    id_cliente integer NOT NULL,
    id_persona integer NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.cliente ALTER COLUMN id_cliente ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.cliente_id_cliente_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: componente_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.componente_menu (
    id_componente integer NOT NULL,
    id_categoria_componente_menu integer NOT NULL,
    nombre character varying(150) NOT NULL,
    recargo numeric(10,2) DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


--
-- Name: componente_menu_id_componente_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.componente_menu ALTER COLUMN id_componente ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.componente_menu_id_componente_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cotizacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cotizacion (
    id_cotizacion integer NOT NULL,
    id_evento integer NOT NULL,
    version integer NOT NULL,
    fecha_cotizacion date DEFAULT CURRENT_DATE NOT NULL,
    vigencia_dias integer DEFAULT 8 NOT NULL,
    deposito_garantia numeric(10,2) DEFAULT 0 NOT NULL,
    activa boolean DEFAULT true NOT NULL,
    id_estado_cotizacion integer NOT NULL,
    subtotal_menus numeric(10,2) DEFAULT 0 NOT NULL,
    subtotal_servicios numeric(10,2) DEFAULT 0 NOT NULL,
    total numeric(10,2) DEFAULT 0 NOT NULL,
    id_empleado integer,
    total_descuento numeric(10,2) DEFAULT 0 NOT NULL,
    brindis boolean DEFAULT false NOT NULL,
    cantidad_mesa_principal integer,
    cantidad_mesas_reservadas integer,
    id_color_mantel integer,
    id_color_cubremanteles integer,
    observaciones text,
    boquitas text
);


--
-- Name: cotizacion_id_cotizacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.cotizacion ALTER COLUMN id_cotizacion ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.cotizacion_id_cotizacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cotizacion_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cotizacion_menu (
    id_cotizacion_menu integer NOT NULL,
    id_cotizacion integer NOT NULL,
    id_menu integer NOT NULL,
    precio_unitario_congelado numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    cantidad integer NOT NULL,
    CONSTRAINT chk_cotizacion_menu_cantidad CHECK ((cantidad > 0))
);


--
-- Name: cotizacion_menu_id_cotizacion_menu_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.cotizacion_menu ALTER COLUMN id_cotizacion_menu ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.cotizacion_menu_id_cotizacion_menu_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cotizacion_servicios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cotizacion_servicios (
    id_cotizacion_servicios integer NOT NULL,
    id_cotizacion integer NOT NULL,
    id_servicio integer NOT NULL,
    cantidad integer DEFAULT 1 NOT NULL,
    precio_unitario_congelado numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    CONSTRAINT chk_cotizacion_servicios_cantidad CHECK ((cantidad > 0))
);


--
-- Name: cotizacion_servicios_descuento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cotizacion_servicios_descuento (
    id_descuento integer NOT NULL,
    id_cotizacion_servicios integer NOT NULL,
    id_tipo_descuento integer NOT NULL,
    porcentaje numeric(5,2),
    monto_descontado numeric(10,2) NOT NULL,
    motivo text,
    estado character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    id_empleado_solicito integer,
    id_empleado_aprobo integer,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_descuento_estado CHECK (((estado)::text = ANY ((ARRAY['pendiente'::character varying, 'aprobado'::character varying, 'rechazado'::character varying])::text[]))),
    CONSTRAINT chk_descuento_monto CHECK ((monto_descontado > (0)::numeric))
);


--
-- Name: cotizacion_servicios_descuento_id_descuento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.cotizacion_servicios_descuento ALTER COLUMN id_descuento ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.cotizacion_servicios_descuento_id_descuento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cotizacion_servicios_id_cotizacion_servicios_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.cotizacion_servicios ALTER COLUMN id_cotizacion_servicios ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.cotizacion_servicios_id_cotizacion_servicios_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: degustacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.degustacion (
    id_degustacion integer NOT NULL,
    id_evento integer NOT NULL,
    id_fecha_degustacion integer NOT NULL,
    estado character varying(20) DEFAULT 'agendada'::character varying NOT NULL,
    notas text,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    hora_llegada time without time zone,
    resultado character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    motivo_rechazo text,
    CONSTRAINT chk_degustacion_estado CHECK (((estado)::text = ANY ((ARRAY['agendada'::character varying, 'realizada'::character varying, 'cancelada'::character varying])::text[]))),
    CONSTRAINT chk_degustacion_motivo_rechazo CHECK ((((resultado)::text <> 'rechazada'::text) OR ((motivo_rechazo IS NOT NULL) AND (length(TRIM(BOTH FROM motivo_rechazo)) > 0)))),
    CONSTRAINT chk_degustacion_resultado CHECK (((resultado)::text = ANY ((ARRAY['pendiente'::character varying, 'aprobada'::character varying, 'rechazada'::character varying])::text[])))
);


--
-- Name: degustacion_id_degustacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.degustacion ALTER COLUMN id_degustacion ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.degustacion_id_degustacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: degustacion_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.degustacion_menu (
    id_degustacion_menu integer NOT NULL,
    id_degustacion integer NOT NULL,
    id_menu integer NOT NULL,
    resultado character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    notas text,
    es_adicional boolean DEFAULT false NOT NULL,
    id_cotizacion_menu integer,
    CONSTRAINT chk_degustacion_menu_resultado CHECK (((resultado)::text = ANY ((ARRAY['pendiente'::character varying, 'aprobado'::character varying, 'rechazado'::character varying])::text[])))
);


--
-- Name: degustacion_menu_id_degustacion_menu_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.degustacion_menu ALTER COLUMN id_degustacion_menu ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.degustacion_menu_id_degustacion_menu_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: empleado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.empleado (
    id_empleado integer NOT NULL,
    id_persona integer NOT NULL,
    id_tipo_empleado integer NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: empleado_id_empleado_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.empleado ALTER COLUMN id_empleado ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.empleado_id_empleado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento (
    id_evento integer NOT NULL,
    id_cliente integer NOT NULL,
    id_tipo_evento integer,
    fecha date NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fin time without time zone NOT NULL,
    total_adultos integer DEFAULT 0 NOT NULL,
    total_menores integer DEFAULT 0 NOT NULL,
    estado character varying(20) DEFAULT 'cotizacion'::character varying NOT NULL,
    notas text,
    saldo_pendiente numeric(10,2) DEFAULT 0 NOT NULL,
    porcentaje_pagado numeric(5,4) DEFAULT 0 NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    reserva_temporal boolean DEFAULT false NOT NULL,
    CONSTRAINT chk_evento_estado CHECK (((estado)::text = ANY ((ARRAY['cotizacion'::character varying, 'confirmado'::character varying, 'en_curso'::character varying, 'cerrado'::character varying, 'cancelado'::character varying])::text[]))),
    CONSTRAINT chk_evento_horario CHECK ((hora_fin > hora_inicio))
);


--
-- Name: evento_id_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.evento ALTER COLUMN id_evento ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.evento_id_evento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: evento_salon; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_salon (
    id_evento integer NOT NULL,
    id_salon integer NOT NULL
);


--
-- Name: extras; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.extras (
    id_extra integer NOT NULL,
    id_evento integer NOT NULL,
    total numeric(10,2) DEFAULT 0 NOT NULL,
    id_empleado integer
);


--
-- Name: extras_id_extra_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.extras ALTER COLUMN id_extra ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.extras_id_extra_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: extras_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.extras_menu (
    id_extras_menu integer NOT NULL,
    id_extra integer NOT NULL,
    id_menu integer NOT NULL,
    descripcion text,
    cantidad integer DEFAULT 1 NOT NULL,
    precio_base numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    estado character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    CONSTRAINT chk_extras_menu_cantidad CHECK ((cantidad > 0)),
    CONSTRAINT chk_extras_menu_estado CHECK (((estado)::text = ANY ((ARRAY['pendiente'::character varying, 'aprobado'::character varying, 'pagado'::character varying, 'cancelado'::character varying])::text[])))
);


--
-- Name: extras_menu_id_extras_menu_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.extras_menu ALTER COLUMN id_extras_menu ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.extras_menu_id_extras_menu_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: extras_servicios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.extras_servicios (
    id_extras_servicios integer NOT NULL,
    id_extra integer NOT NULL,
    id_servicio integer,
    id_tipo_cargo_extra integer NOT NULL,
    descripcion text,
    cantidad integer DEFAULT 1 NOT NULL,
    precio_unitario numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    estado character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    CONSTRAINT chk_extras_servicios_cantidad CHECK ((cantidad > 0)),
    CONSTRAINT chk_extras_servicios_estado CHECK (((estado)::text = ANY ((ARRAY['pendiente'::character varying, 'aprobado'::character varying, 'pagado'::character varying, 'cancelado'::character varying])::text[])))
);


--
-- Name: extras_servicios_id_extras_servicios_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.extras_servicios ALTER COLUMN id_extras_servicios ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.extras_servicios_id_extras_servicios_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fechas_degustacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fechas_degustacion (
    id_fecha_degustacion integer NOT NULL,
    fecha date NOT NULL,
    hora_inicio time without time zone,
    estado character varying(20) DEFAULT 'disponible'::character varying NOT NULL,
    hora_fin time without time zone,
    CONSTRAINT chk_fecha_degustacion_estado CHECK (((estado)::text = ANY ((ARRAY['disponible'::character varying, 'llena'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: fechas_degustacion_id_fecha_degustacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.fechas_degustacion ALTER COLUMN id_fecha_degustacion ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.fechas_degustacion_id_fecha_degustacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: locacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locacion (
    id_locacion integer NOT NULL,
    nombre character varying(80) NOT NULL,
    direccion character varying(200)
);


--
-- Name: locacion_id_locacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.locacion ALTER COLUMN id_locacion ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.locacion_id_locacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu (
    id_menu integer NOT NULL,
    nombre character varying(150) NOT NULL,
    id_tipo_menu integer NOT NULL,
    precio_base numeric(10,2) NOT NULL,
    unidad_medida character varying(30) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true NOT NULL,
    es_personalizado boolean DEFAULT false NOT NULL,
    id_evento integer
);


--
-- Name: menu_componentes_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_componentes_menu (
    id_menu integer NOT NULL,
    id_componente integer NOT NULL
);


--
-- Name: menu_id_menu_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.menu ALTER COLUMN id_menu ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.menu_id_menu_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pago; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pago (
    id_pago integer NOT NULL,
    id_evento integer NOT NULL,
    fecha_pago date DEFAULT CURRENT_DATE NOT NULL,
    monto numeric(10,2) NOT NULL,
    id_tipo_pago integer NOT NULL,
    concepto character varying(20) NOT NULL,
    id_empleado integer,
    estado character varying(15) DEFAULT 'verificado'::character varying NOT NULL,
    origen character varying(10) DEFAULT 'staff'::character varying NOT NULL,
    path_comprobante character varying(300),
    notas text,
    fecha_registro timestamp with time zone DEFAULT now() NOT NULL,
    motivo_rechazo text,
    CONSTRAINT chk_pago_concepto CHECK (((concepto)::text = ANY ((ARRAY['reserva'::character varying, 'abono'::character varying, 'saldo'::character varying, 'recargo'::character varying])::text[]))),
    CONSTRAINT chk_pago_empleado_si_verificado CHECK ((((estado)::text <> 'verificado'::text) OR (id_empleado IS NOT NULL))),
    CONSTRAINT chk_pago_estado CHECK (((estado)::text = ANY ((ARRAY['pendiente'::character varying, 'verificado'::character varying, 'rechazado'::character varying])::text[]))),
    CONSTRAINT chk_pago_monto CHECK ((monto > (0)::numeric)),
    CONSTRAINT chk_pago_origen CHECK (((origen)::text = ANY ((ARRAY['staff'::character varying, 'cliente'::character varying])::text[])))
);


--
-- Name: pago_id_pago_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.pago ALTER COLUMN id_pago ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.pago_id_pago_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: persona; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.persona (
    id_persona integer NOT NULL,
    primer_nombre character varying(80) NOT NULL,
    segundo_nombre character varying(80),
    primer_apellido character varying(80) NOT NULL,
    segundo_apellido character varying(80),
    cui character varying(13),
    nit character varying(20),
    telefono character varying(20),
    correo character varying(150),
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: persona_id_persona_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.persona ALTER COLUMN id_persona ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.persona_id_persona_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: prospecto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prospecto (
    id_prospecto integer NOT NULL,
    nombre character varying(150) NOT NULL,
    telefono character varying(30) NOT NULL,
    correo character varying(150),
    id_tipo_evento integer,
    id_salon integer,
    fecha_tentativa date,
    invitados integer,
    mensaje text,
    estado character varying(20) DEFAULT 'nuevo'::character varying NOT NULL,
    notas_internas text,
    id_cliente integer,
    id_evento integer,
    ip_origen character varying(45),
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT prospecto_estado_check CHECK (((estado)::text = ANY ((ARRAY['nuevo'::character varying, 'contactado'::character varying, 'convertido'::character varying, 'descartado'::character varying])::text[]))),
    CONSTRAINT prospecto_invitados_check CHECK (((invitados IS NULL) OR (invitados > 0)))
);


--
-- Name: prospecto_id_prospecto_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prospecto_id_prospecto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prospecto_id_prospecto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prospecto_id_prospecto_seq OWNED BY public.prospecto.id_prospecto;


--
-- Name: recordatorio_enviado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recordatorio_enviado (
    id_recordatorio integer NOT NULL,
    id_evento integer NOT NULL,
    id_tipo_recordatorio integer NOT NULL,
    correo_destino character varying(150) NOT NULL,
    fecha_envio timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: recordatorio_enviado_id_recordatorio_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.recordatorio_enviado ALTER COLUMN id_recordatorio ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.recordatorio_enviado_id_recordatorio_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: salon; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.salon (
    id_salon integer NOT NULL,
    id_locacion integer NOT NULL,
    nombre character varying(100) NOT NULL,
    capacidad integer,
    descripcion text
);


--
-- Name: salon_id_salon_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.salon ALTER COLUMN id_salon ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.salon_id_salon_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: servicios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.servicios (
    id_servicio integer NOT NULL,
    id_categoria_servicio integer NOT NULL,
    nombre character varying(150) NOT NULL,
    precio_base numeric(10,2) NOT NULL,
    unidad_medida character varying(30) NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


--
-- Name: servicios_id_servicio_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.servicios ALTER COLUMN id_servicio ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.servicios_id_servicio_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_categoria_componente_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_categoria_componente_menu (
    id_categoria_componente_menu integer CONSTRAINT tc_categoria_componente_men_id_categoria_componente_me_not_null NOT NULL,
    descripcion character varying(60) NOT NULL
);


--
-- Name: tc_categoria_componente_menu_id_categoria_componente_menu_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_categoria_componente_menu ALTER COLUMN id_categoria_componente_menu ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_categoria_componente_menu_id_categoria_componente_menu_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_categoria_servicio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_categoria_servicio (
    id_categoria_servicio integer NOT NULL,
    descripcion character varying(60) NOT NULL
);


--
-- Name: tc_categoria_servicio_id_categoria_servicio_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_categoria_servicio ALTER COLUMN id_categoria_servicio ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_categoria_servicio_id_categoria_servicio_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_color_cubremanteles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_color_cubremanteles (
    id_color_cubremanteles integer NOT NULL,
    descripcion character varying(50) NOT NULL
);


--
-- Name: tc_color_cubremanteles_id_color_cubremanteles_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_color_cubremanteles ALTER COLUMN id_color_cubremanteles ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_color_cubremanteles_id_color_cubremanteles_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_color_mantel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_color_mantel (
    id_color_mantel integer NOT NULL,
    descripcion character varying(50) NOT NULL
);


--
-- Name: tc_color_mantel_id_color_mantel_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_color_mantel ALTER COLUMN id_color_mantel ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_color_mantel_id_color_mantel_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_estado_cotizacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_estado_cotizacion (
    id_estado_cotizacion integer NOT NULL,
    descripcion character varying(30) NOT NULL
);


--
-- Name: tc_estado_cotizacion_id_estado_cotizacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_estado_cotizacion ALTER COLUMN id_estado_cotizacion ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_estado_cotizacion_id_estado_cotizacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_rol_acceso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_rol_acceso (
    id_rol_acceso integer NOT NULL,
    descripcion character varying(50) NOT NULL
);


--
-- Name: tc_rol_acceso_id_rol_acceso_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_rol_acceso ALTER COLUMN id_rol_acceso ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_rol_acceso_id_rol_acceso_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_tipo_cargo_extra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_tipo_cargo_extra (
    id_tipo_cargo_extra integer NOT NULL,
    descripcion character varying(60) NOT NULL
);


--
-- Name: tc_tipo_cargo_extra_id_tipo_cargo_extra_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_tipo_cargo_extra ALTER COLUMN id_tipo_cargo_extra ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_tipo_cargo_extra_id_tipo_cargo_extra_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_tipo_descuento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_tipo_descuento (
    id_tipo_descuento integer NOT NULL,
    descripcion character varying(60) NOT NULL
);


--
-- Name: tc_tipo_descuento_id_tipo_descuento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_tipo_descuento ALTER COLUMN id_tipo_descuento ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_tipo_descuento_id_tipo_descuento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_tipo_empleado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_tipo_empleado (
    id_tipo_empleado integer NOT NULL,
    descripcion character varying(50) NOT NULL
);


--
-- Name: tc_tipo_empleado_id_tipo_empleado_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_tipo_empleado ALTER COLUMN id_tipo_empleado ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_tipo_empleado_id_tipo_empleado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_tipo_evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_tipo_evento (
    id_tipo_evento integer NOT NULL,
    descripcion character varying(60) NOT NULL
);


--
-- Name: tc_tipo_evento_id_tipo_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_tipo_evento ALTER COLUMN id_tipo_evento ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_tipo_evento_id_tipo_evento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_tipo_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_tipo_menu (
    id_tipo_menu integer NOT NULL,
    descripcion character varying(30) NOT NULL
);


--
-- Name: tc_tipo_menu_id_tipo_menu_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_tipo_menu ALTER COLUMN id_tipo_menu ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_tipo_menu_id_tipo_menu_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_tipo_pago; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_tipo_pago (
    id_tipo_pago integer NOT NULL,
    descripcion character varying(30) NOT NULL
);


--
-- Name: tc_tipo_pago_id_tipo_pago_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_tipo_pago ALTER COLUMN id_tipo_pago ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_tipo_pago_id_tipo_pago_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_tipo_recordatorio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_tipo_recordatorio (
    id_tipo_recordatorio integer NOT NULL,
    descripcion character varying(60) NOT NULL
);


--
-- Name: tc_tipo_recordatorio_id_tipo_recordatorio_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_tipo_recordatorio ALTER COLUMN id_tipo_recordatorio ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_tipo_recordatorio_id_tipo_recordatorio_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tc_tipo_usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tc_tipo_usuario (
    id_tipo_usuario integer NOT NULL,
    descripcion character varying(50) NOT NULL
);


--
-- Name: tc_tipo_usuario_id_tipo_usuario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tc_tipo_usuario ALTER COLUMN id_tipo_usuario ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tc_tipo_usuario_id_tipo_usuario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario (
    id_usuario integer NOT NULL,
    id_persona integer NOT NULL,
    id_tipo_usuario integer NOT NULL,
    username character varying(80) NOT NULL,
    password_hash character varying(255) NOT NULL,
    confirmacion boolean DEFAULT false NOT NULL,
    fecha_ultimo_acceso timestamp with time zone,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    id_rol_acceso integer,
    activo boolean DEFAULT true NOT NULL
);


--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.usuario ALTER COLUMN id_usuario ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.usuario_id_usuario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: v_cotizacion_calculada; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_cotizacion_calculada AS
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


--
-- Name: v_extras_calculado; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_extras_calculado AS
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


--
-- Name: v_evento_saldo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_evento_saldo AS
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


--
-- Name: prospecto id_prospecto; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospecto ALTER COLUMN id_prospecto SET DEFAULT nextval('public.prospecto_id_prospecto_seq'::regclass);


--
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);


--
-- Name: componente_menu componente_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.componente_menu
    ADD CONSTRAINT componente_menu_pkey PRIMARY KEY (id_componente);


--
-- Name: cotizacion cotizacion_id_evento_version_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_id_evento_version_key UNIQUE (id_evento, version);


--
-- Name: cotizacion_menu cotizacion_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion_menu
    ADD CONSTRAINT cotizacion_menu_pkey PRIMARY KEY (id_cotizacion_menu);


--
-- Name: cotizacion cotizacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_pkey PRIMARY KEY (id_cotizacion);


--
-- Name: cotizacion_servicios_descuento cotizacion_servicios_descuento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion_servicios_descuento
    ADD CONSTRAINT cotizacion_servicios_descuento_pkey PRIMARY KEY (id_descuento);


--
-- Name: cotizacion_servicios cotizacion_servicios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion_servicios
    ADD CONSTRAINT cotizacion_servicios_pkey PRIMARY KEY (id_cotizacion_servicios);


--
-- Name: degustacion_menu degustacion_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.degustacion_menu
    ADD CONSTRAINT degustacion_menu_pkey PRIMARY KEY (id_degustacion_menu);


--
-- Name: degustacion degustacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.degustacion
    ADD CONSTRAINT degustacion_pkey PRIMARY KEY (id_degustacion);


--
-- Name: empleado empleado_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT empleado_pkey PRIMARY KEY (id_empleado);


--
-- Name: evento evento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento
    ADD CONSTRAINT evento_pkey PRIMARY KEY (id_evento);


--
-- Name: evento_salon evento_salon_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_salon
    ADD CONSTRAINT evento_salon_pkey PRIMARY KEY (id_evento, id_salon);


--
-- Name: extras extras_id_evento_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extras
    ADD CONSTRAINT extras_id_evento_key UNIQUE (id_evento);


--
-- Name: extras_menu extras_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extras_menu
    ADD CONSTRAINT extras_menu_pkey PRIMARY KEY (id_extras_menu);


--
-- Name: extras extras_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extras
    ADD CONSTRAINT extras_pkey PRIMARY KEY (id_extra);


--
-- Name: extras_servicios extras_servicios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extras_servicios
    ADD CONSTRAINT extras_servicios_pkey PRIMARY KEY (id_extras_servicios);


--
-- Name: fechas_degustacion fechas_degustacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fechas_degustacion
    ADD CONSTRAINT fechas_degustacion_pkey PRIMARY KEY (id_fecha_degustacion);


--
-- Name: locacion locacion_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locacion
    ADD CONSTRAINT locacion_nombre_key UNIQUE (nombre);


--
-- Name: locacion locacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locacion
    ADD CONSTRAINT locacion_pkey PRIMARY KEY (id_locacion);


--
-- Name: menu_componentes_menu menu_componentes_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_componentes_menu
    ADD CONSTRAINT menu_componentes_menu_pkey PRIMARY KEY (id_menu, id_componente);


--
-- Name: menu menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu
    ADD CONSTRAINT menu_pkey PRIMARY KEY (id_menu);


--
-- Name: pago pago_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT pago_pkey PRIMARY KEY (id_pago);


--
-- Name: persona persona_cui_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_cui_key UNIQUE (cui);


--
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (id_persona);


--
-- Name: prospecto prospecto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospecto
    ADD CONSTRAINT prospecto_pkey PRIMARY KEY (id_prospecto);


--
-- Name: recordatorio_enviado recordatorio_enviado_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recordatorio_enviado
    ADD CONSTRAINT recordatorio_enviado_pkey PRIMARY KEY (id_recordatorio);


--
-- Name: salon salon_id_locacion_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salon
    ADD CONSTRAINT salon_id_locacion_nombre_key UNIQUE (id_locacion, nombre);


--
-- Name: salon salon_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salon
    ADD CONSTRAINT salon_pkey PRIMARY KEY (id_salon);


--
-- Name: servicios servicios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicios
    ADD CONSTRAINT servicios_pkey PRIMARY KEY (id_servicio);


--
-- Name: tc_categoria_componente_menu tc_categoria_componente_menu_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_categoria_componente_menu
    ADD CONSTRAINT tc_categoria_componente_menu_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_categoria_componente_menu tc_categoria_componente_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_categoria_componente_menu
    ADD CONSTRAINT tc_categoria_componente_menu_pkey PRIMARY KEY (id_categoria_componente_menu);


--
-- Name: tc_categoria_servicio tc_categoria_servicio_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_categoria_servicio
    ADD CONSTRAINT tc_categoria_servicio_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_categoria_servicio tc_categoria_servicio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_categoria_servicio
    ADD CONSTRAINT tc_categoria_servicio_pkey PRIMARY KEY (id_categoria_servicio);


--
-- Name: tc_color_cubremanteles tc_color_cubremanteles_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_color_cubremanteles
    ADD CONSTRAINT tc_color_cubremanteles_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_color_cubremanteles tc_color_cubremanteles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_color_cubremanteles
    ADD CONSTRAINT tc_color_cubremanteles_pkey PRIMARY KEY (id_color_cubremanteles);


--
-- Name: tc_color_mantel tc_color_mantel_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_color_mantel
    ADD CONSTRAINT tc_color_mantel_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_color_mantel tc_color_mantel_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_color_mantel
    ADD CONSTRAINT tc_color_mantel_pkey PRIMARY KEY (id_color_mantel);


--
-- Name: tc_estado_cotizacion tc_estado_cotizacion_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_estado_cotizacion
    ADD CONSTRAINT tc_estado_cotizacion_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_estado_cotizacion tc_estado_cotizacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_estado_cotizacion
    ADD CONSTRAINT tc_estado_cotizacion_pkey PRIMARY KEY (id_estado_cotizacion);


--
-- Name: tc_rol_acceso tc_rol_acceso_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_rol_acceso
    ADD CONSTRAINT tc_rol_acceso_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_rol_acceso tc_rol_acceso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_rol_acceso
    ADD CONSTRAINT tc_rol_acceso_pkey PRIMARY KEY (id_rol_acceso);


--
-- Name: tc_tipo_cargo_extra tc_tipo_cargo_extra_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_cargo_extra
    ADD CONSTRAINT tc_tipo_cargo_extra_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_tipo_cargo_extra tc_tipo_cargo_extra_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_cargo_extra
    ADD CONSTRAINT tc_tipo_cargo_extra_pkey PRIMARY KEY (id_tipo_cargo_extra);


--
-- Name: tc_tipo_descuento tc_tipo_descuento_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_descuento
    ADD CONSTRAINT tc_tipo_descuento_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_tipo_descuento tc_tipo_descuento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_descuento
    ADD CONSTRAINT tc_tipo_descuento_pkey PRIMARY KEY (id_tipo_descuento);


--
-- Name: tc_tipo_empleado tc_tipo_empleado_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_empleado
    ADD CONSTRAINT tc_tipo_empleado_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_tipo_empleado tc_tipo_empleado_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_empleado
    ADD CONSTRAINT tc_tipo_empleado_pkey PRIMARY KEY (id_tipo_empleado);


--
-- Name: tc_tipo_evento tc_tipo_evento_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_evento
    ADD CONSTRAINT tc_tipo_evento_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_tipo_evento tc_tipo_evento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_evento
    ADD CONSTRAINT tc_tipo_evento_pkey PRIMARY KEY (id_tipo_evento);


--
-- Name: tc_tipo_menu tc_tipo_menu_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_menu
    ADD CONSTRAINT tc_tipo_menu_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_tipo_menu tc_tipo_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_menu
    ADD CONSTRAINT tc_tipo_menu_pkey PRIMARY KEY (id_tipo_menu);


--
-- Name: tc_tipo_pago tc_tipo_pago_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_pago
    ADD CONSTRAINT tc_tipo_pago_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_tipo_pago tc_tipo_pago_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_pago
    ADD CONSTRAINT tc_tipo_pago_pkey PRIMARY KEY (id_tipo_pago);


--
-- Name: tc_tipo_recordatorio tc_tipo_recordatorio_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_recordatorio
    ADD CONSTRAINT tc_tipo_recordatorio_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_tipo_recordatorio tc_tipo_recordatorio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_recordatorio
    ADD CONSTRAINT tc_tipo_recordatorio_pkey PRIMARY KEY (id_tipo_recordatorio);


--
-- Name: tc_tipo_usuario tc_tipo_usuario_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_usuario
    ADD CONSTRAINT tc_tipo_usuario_descripcion_key UNIQUE (descripcion);


--
-- Name: tc_tipo_usuario tc_tipo_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tc_tipo_usuario
    ADD CONSTRAINT tc_tipo_usuario_pkey PRIMARY KEY (id_tipo_usuario);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- Name: usuario usuario_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- Name: idx_cotizacion_evento; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cotizacion_evento ON public.cotizacion USING btree (id_evento);


--
-- Name: idx_cotizacion_menu_cotizacion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cotizacion_menu_cotizacion ON public.cotizacion_menu USING btree (id_cotizacion);


--
-- Name: idx_degustacion_evento; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_degustacion_evento ON public.degustacion USING btree (id_evento);


--
-- Name: idx_evento_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evento_cliente ON public.evento USING btree (id_cliente);


--
-- Name: idx_evento_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evento_fecha ON public.evento USING btree (fecha);


--
-- Name: idx_extras_menu_extra; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_extras_menu_extra ON public.extras_menu USING btree (id_extra);


--
-- Name: idx_extras_servicios_extra; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_extras_servicios_extra ON public.extras_servicios USING btree (id_extra);


--
-- Name: idx_pago_evento; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pago_evento ON public.pago USING btree (id_evento);


--
-- Name: idx_prospecto_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prospecto_estado ON public.prospecto USING btree (estado);


--
-- Name: idx_prospecto_fecha_creacion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prospecto_fecha_creacion ON public.prospecto USING btree (fecha_creacion DESC);


--
-- Name: ux_cotizacion_activa; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_cotizacion_activa ON public.cotizacion USING btree (id_evento) WHERE (activa = true);


--
-- Name: cliente cliente_id_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES public.persona(id_persona);


--
-- Name: componente_menu componente_menu_id_categoria_componente_menu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.componente_menu
    ADD CONSTRAINT componente_menu_id_categoria_componente_menu_fkey FOREIGN KEY (id_categoria_componente_menu) REFERENCES public.tc_categoria_componente_menu(id_categoria_componente_menu);


--
-- Name: cotizacion cotizacion_id_color_cubremanteles_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_id_color_cubremanteles_fkey FOREIGN KEY (id_color_cubremanteles) REFERENCES public.tc_color_cubremanteles(id_color_cubremanteles);


--
-- Name: cotizacion cotizacion_id_color_mantel_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_id_color_mantel_fkey FOREIGN KEY (id_color_mantel) REFERENCES public.tc_color_mantel(id_color_mantel);


--
-- Name: cotizacion cotizacion_id_empleado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_id_empleado_fkey FOREIGN KEY (id_empleado) REFERENCES public.empleado(id_empleado);


--
-- Name: cotizacion cotizacion_id_estado_cotizacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_id_estado_cotizacion_fkey FOREIGN KEY (id_estado_cotizacion) REFERENCES public.tc_estado_cotizacion(id_estado_cotizacion);


--
-- Name: cotizacion cotizacion_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento) ON DELETE CASCADE;


--
-- Name: cotizacion_menu cotizacion_menu_id_cotizacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion_menu
    ADD CONSTRAINT cotizacion_menu_id_cotizacion_fkey FOREIGN KEY (id_cotizacion) REFERENCES public.cotizacion(id_cotizacion) ON DELETE CASCADE;


--
-- Name: cotizacion_menu cotizacion_menu_id_menu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion_menu
    ADD CONSTRAINT cotizacion_menu_id_menu_fkey FOREIGN KEY (id_menu) REFERENCES public.menu(id_menu);


--
-- Name: cotizacion_servicios_descuento cotizacion_servicios_descuento_id_cotizacion_servicios_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion_servicios_descuento
    ADD CONSTRAINT cotizacion_servicios_descuento_id_cotizacion_servicios_fkey FOREIGN KEY (id_cotizacion_servicios) REFERENCES public.cotizacion_servicios(id_cotizacion_servicios) ON DELETE CASCADE;


--
-- Name: cotizacion_servicios_descuento cotizacion_servicios_descuento_id_empleado_aprobo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion_servicios_descuento
    ADD CONSTRAINT cotizacion_servicios_descuento_id_empleado_aprobo_fkey FOREIGN KEY (id_empleado_aprobo) REFERENCES public.empleado(id_empleado);


--
-- Name: cotizacion_servicios_descuento cotizacion_servicios_descuento_id_empleado_solicito_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion_servicios_descuento
    ADD CONSTRAINT cotizacion_servicios_descuento_id_empleado_solicito_fkey FOREIGN KEY (id_empleado_solicito) REFERENCES public.empleado(id_empleado);


--
-- Name: cotizacion_servicios_descuento cotizacion_servicios_descuento_id_tipo_descuento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion_servicios_descuento
    ADD CONSTRAINT cotizacion_servicios_descuento_id_tipo_descuento_fkey FOREIGN KEY (id_tipo_descuento) REFERENCES public.tc_tipo_descuento(id_tipo_descuento);


--
-- Name: cotizacion_servicios cotizacion_servicios_id_cotizacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion_servicios
    ADD CONSTRAINT cotizacion_servicios_id_cotizacion_fkey FOREIGN KEY (id_cotizacion) REFERENCES public.cotizacion(id_cotizacion) ON DELETE CASCADE;


--
-- Name: cotizacion_servicios cotizacion_servicios_id_servicio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion_servicios
    ADD CONSTRAINT cotizacion_servicios_id_servicio_fkey FOREIGN KEY (id_servicio) REFERENCES public.servicios(id_servicio);


--
-- Name: degustacion degustacion_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.degustacion
    ADD CONSTRAINT degustacion_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento) ON DELETE CASCADE;


--
-- Name: degustacion degustacion_id_fecha_degustacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.degustacion
    ADD CONSTRAINT degustacion_id_fecha_degustacion_fkey FOREIGN KEY (id_fecha_degustacion) REFERENCES public.fechas_degustacion(id_fecha_degustacion);


--
-- Name: degustacion_menu degustacion_menu_id_cotizacion_menu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.degustacion_menu
    ADD CONSTRAINT degustacion_menu_id_cotizacion_menu_fkey FOREIGN KEY (id_cotizacion_menu) REFERENCES public.cotizacion_menu(id_cotizacion_menu);


--
-- Name: degustacion_menu degustacion_menu_id_degustacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.degustacion_menu
    ADD CONSTRAINT degustacion_menu_id_degustacion_fkey FOREIGN KEY (id_degustacion) REFERENCES public.degustacion(id_degustacion) ON DELETE CASCADE;


--
-- Name: degustacion_menu degustacion_menu_id_menu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.degustacion_menu
    ADD CONSTRAINT degustacion_menu_id_menu_fkey FOREIGN KEY (id_menu) REFERENCES public.menu(id_menu);


--
-- Name: empleado empleado_id_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT empleado_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES public.persona(id_persona);


--
-- Name: empleado empleado_id_tipo_empleado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT empleado_id_tipo_empleado_fkey FOREIGN KEY (id_tipo_empleado) REFERENCES public.tc_tipo_empleado(id_tipo_empleado);


--
-- Name: evento evento_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento
    ADD CONSTRAINT evento_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente);


--
-- Name: evento evento_id_tipo_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento
    ADD CONSTRAINT evento_id_tipo_evento_fkey FOREIGN KEY (id_tipo_evento) REFERENCES public.tc_tipo_evento(id_tipo_evento);


--
-- Name: evento_salon evento_salon_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_salon
    ADD CONSTRAINT evento_salon_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento) ON DELETE CASCADE;


--
-- Name: evento_salon evento_salon_id_salon_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_salon
    ADD CONSTRAINT evento_salon_id_salon_fkey FOREIGN KEY (id_salon) REFERENCES public.salon(id_salon);


--
-- Name: extras extras_id_empleado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extras
    ADD CONSTRAINT extras_id_empleado_fkey FOREIGN KEY (id_empleado) REFERENCES public.empleado(id_empleado);


--
-- Name: extras extras_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extras
    ADD CONSTRAINT extras_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento) ON DELETE CASCADE;


--
-- Name: extras_menu extras_menu_id_extra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extras_menu
    ADD CONSTRAINT extras_menu_id_extra_fkey FOREIGN KEY (id_extra) REFERENCES public.extras(id_extra) ON DELETE CASCADE;


--
-- Name: extras_menu extras_menu_id_menu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extras_menu
    ADD CONSTRAINT extras_menu_id_menu_fkey FOREIGN KEY (id_menu) REFERENCES public.menu(id_menu);


--
-- Name: extras_servicios extras_servicios_id_extra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extras_servicios
    ADD CONSTRAINT extras_servicios_id_extra_fkey FOREIGN KEY (id_extra) REFERENCES public.extras(id_extra) ON DELETE CASCADE;


--
-- Name: extras_servicios extras_servicios_id_servicio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extras_servicios
    ADD CONSTRAINT extras_servicios_id_servicio_fkey FOREIGN KEY (id_servicio) REFERENCES public.servicios(id_servicio);


--
-- Name: extras_servicios extras_servicios_id_tipo_cargo_extra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extras_servicios
    ADD CONSTRAINT extras_servicios_id_tipo_cargo_extra_fkey FOREIGN KEY (id_tipo_cargo_extra) REFERENCES public.tc_tipo_cargo_extra(id_tipo_cargo_extra);


--
-- Name: menu_componentes_menu menu_componentes_menu_id_componente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_componentes_menu
    ADD CONSTRAINT menu_componentes_menu_id_componente_fkey FOREIGN KEY (id_componente) REFERENCES public.componente_menu(id_componente);


--
-- Name: menu_componentes_menu menu_componentes_menu_id_menu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_componentes_menu
    ADD CONSTRAINT menu_componentes_menu_id_menu_fkey FOREIGN KEY (id_menu) REFERENCES public.menu(id_menu) ON DELETE CASCADE;


--
-- Name: menu menu_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu
    ADD CONSTRAINT menu_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento);


--
-- Name: menu menu_id_tipo_menu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu
    ADD CONSTRAINT menu_id_tipo_menu_fkey FOREIGN KEY (id_tipo_menu) REFERENCES public.tc_tipo_menu(id_tipo_menu);


--
-- Name: pago pago_id_empleado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT pago_id_empleado_fkey FOREIGN KEY (id_empleado) REFERENCES public.empleado(id_empleado);


--
-- Name: pago pago_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT pago_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento);


--
-- Name: pago pago_id_tipo_pago_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT pago_id_tipo_pago_fkey FOREIGN KEY (id_tipo_pago) REFERENCES public.tc_tipo_pago(id_tipo_pago);


--
-- Name: prospecto prospecto_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospecto
    ADD CONSTRAINT prospecto_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente);


--
-- Name: prospecto prospecto_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospecto
    ADD CONSTRAINT prospecto_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento);


--
-- Name: prospecto prospecto_id_salon_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospecto
    ADD CONSTRAINT prospecto_id_salon_fkey FOREIGN KEY (id_salon) REFERENCES public.salon(id_salon);


--
-- Name: prospecto prospecto_id_tipo_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospecto
    ADD CONSTRAINT prospecto_id_tipo_evento_fkey FOREIGN KEY (id_tipo_evento) REFERENCES public.tc_tipo_evento(id_tipo_evento);


--
-- Name: recordatorio_enviado recordatorio_enviado_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recordatorio_enviado
    ADD CONSTRAINT recordatorio_enviado_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento);


--
-- Name: recordatorio_enviado recordatorio_enviado_id_tipo_recordatorio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recordatorio_enviado
    ADD CONSTRAINT recordatorio_enviado_id_tipo_recordatorio_fkey FOREIGN KEY (id_tipo_recordatorio) REFERENCES public.tc_tipo_recordatorio(id_tipo_recordatorio);


--
-- Name: salon salon_id_locacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salon
    ADD CONSTRAINT salon_id_locacion_fkey FOREIGN KEY (id_locacion) REFERENCES public.locacion(id_locacion);


--
-- Name: servicios servicios_id_categoria_servicio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicios
    ADD CONSTRAINT servicios_id_categoria_servicio_fkey FOREIGN KEY (id_categoria_servicio) REFERENCES public.tc_categoria_servicio(id_categoria_servicio);


--
-- Name: usuario usuario_id_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES public.persona(id_persona);


--
-- Name: usuario usuario_id_rol_acceso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_id_rol_acceso_fkey FOREIGN KEY (id_rol_acceso) REFERENCES public.tc_rol_acceso(id_rol_acceso);


--
-- Name: usuario usuario_id_tipo_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_id_tipo_usuario_fkey FOREIGN KEY (id_tipo_usuario) REFERENCES public.tc_tipo_usuario(id_tipo_usuario);


--
-- PostgreSQL database dump complete
--

\unrestrict ABHD4iIad3gmiXh08UVU73E5T7EkP69JveP7DVMSv5QG1ZzE4cNPhgyKJYoyPLH

