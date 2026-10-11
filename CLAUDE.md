# Sistema La Quebrada / GADZI — contexto para Claude

Sistema de gestión de eventos para el negocio familiar de Luis (sus papás): **La Quebrada** (salón de eventos
campestre en La Esperanza, Quetzaltenango) y **GADZI** (segunda locación, por ahora un solo salón).
Reemplaza un proceso que se llevaba en papel y Excel; el flujo del negocio fue llegando por partes.
Está **en producción** (Railway + Neon) y lo usan de verdad.

## Cómo trabajar con Luis (importante)
- **Nunca hacer commits ni push.** Luis hace todos los commits. Solo cambios locales.
- **No tocar la base de producción (Neon).** Los cambios de base van como archivo en `db/migraciones/`
  y Luis los corre en el SQL Editor de Neon. Siempre decirle qué migración correr y en qué orden.
- **Si pide solo explicar o planear** ("explicame cómo haríamos…"), no tocar código aunque después responda
  las preguntas de diseño: esperar a que diga que arranquemos.
- No matar procesos suyos (su backend de desarrollo suele correr en el puerto 3000).
- Responder en español con voseo guatemalteco ("podés", "corré"); Luis escribe informal.
- Probar de verdad antes de decir que algo funciona (ver "Cómo probar").

## Stack y estructura
```
la-quebrada-backend/   Express + TypeScript (ESM, tsx), pg Pool. Rutas en src/routes, middleware en src/middleware
la-quebrada-frontend/  Angular 20 standalone + signals + PrimeNG 20 (preset propio en core/quebrada-preset.ts)
la-quebrada-landing/   Landing pública estática (sitio/index.html) servida con Caddy
                       (la carpeta machote/ es una copia vieja duplicada: se puede borrar)
db/                    esquema_completo.sql (DESACTUALIZADO, del 5-oct), migraciones/, y un archivo por
                       objeto en funciones/, procedures/, tablas/
```
- **Lógica en la base**: funciones `fn_*` y procedimientos `sp_*` en PostgreSQL. Un `RAISE EXCEPTION`
  (código P0001) llega al navegador como 400 con ese mensaje (`utils/errores.ts`, que también traduce
  CHECK/UNIQUE a mensajes claros).
- **Permisos**: tabla central en `backend/src/middleware/permisos.ts` (escrituras cerradas por defecto) y su
  espejo en `frontend/src/app/core/permisos.ts` con `auth.puede('capacidad')`.
- **Alcance por área**: `backend/src/middleware/alcance.ts`. Cada usuario tiene áreas (locación completa o
  salones); solo ve eventos de esos salones. Toda ruta nueva con id de evento/cotización/pago/etc. debe
  usar `router.param(..., guardiaAlcance('tipo'))` o `exigirAlcance`, y los listados `filtrarPorAlcance`.
  Responde 404 (no 403) a lo que no es de su área. Superusuario y usuarios sin áreas ven todo.
- **Roles**: Superusuario, Administrador, Administrador2 (reportes), Vendedor, Secretaria, Revisor (verifica pagos).
- **Frontend**: errores HTTP muestran un toast global (`auth.interceptor.ts`); los formularios que muestran el
  error en línea usan `ERROR_EN_LINEA`. Validaciones compartidas en `core/validaciones.ts` +
  `<app-error-campo>`; buscador de tablas `<app-buscador-tabla>`; hora rápida `horaRapida` (directiva).
- Los diálogos de PrimeNG van con `appendTo="body"`: sus estilos NO pueden ir anidados dentro del selector
  de la página (quedan fuera del DOM de la página).

## Módulos (resumen)
Inicio (calendario; eventos de otras áreas salen como "Ocupado") · Solicitudes web (prospectos de la landing,
convertir a cliente + evento) · Clientes (compartidos entre áreas) · Eventos (detalle con pestañas Cotización,
Degustación, Extras, Pagos; las 3 últimas solo en confirmado/en curso/cerrado) · Pagos (bandeja de verificación)
· Servicios · Menú (menús armados, **paquetes**, componentes) · Degustaciones (fechas) · Reportes (PDF) ·
Usuarios (rol, áreas, datos). Recordatorios de pago por correo (job interno con Gmail).

Reglas clave ya implementadas:
- **Cotización** con versiones; descuentos por línea con aprobación; PDF con logo de la locación del evento.
- **Paquetes**: precio fijo por persona, mínimo de personas (bajo el mínimo pide autorización de un admin de
  esa área), grupos de elección (menús del catálogo, componentes, cortesías), "incluye" (servicio con cantidad
  fija o 1 por cada N personas, o texto), extras con precio de paquete, horas incluidas.
- **Confirmar evento exige abono de reserva** ≥ Q10,000 (o el total de la cotización si es menor). Modal que
  registra el pago (queda pendiente de revisión) y confirma en una sola transacción.
- **Disponibilidad de salones** con candado contra dobles reservas; la base NO acepta eventos que terminen
  después de medianoche (hora_fin > hora_inicio el mismo día) — pregunta abierta, ver pendientes.

## Despliegue (Railway Pro, un proyecto con 3 servicios + Neon)
- **backend**: Dockerfile (node 22 + chromium para PDF), `PORT=3000`, `TRUST_PROXY=2`, volumen en `/data`
  con `UPLOADS_DIR=/data/comprobantes`, variables de Neon, JWT y Gmail (ver `.env.example`).
- **frontend**: Angular compilado + Caddy; Caddy reenvía `/api/*` al backend por la red privada
  (`BACKEND_URL=http://${{backend.RAILWAY_PRIVATE_DOMAIN}}:3000`).
- **landing**: Caddy sirve `la-quebrada-landing/sitio`; reenvía solo `/api/publico/*` al backend
  (`BACKEND_URL`) y `/sistema` redirige a `{SISTEMA_URL}/login`. `www` → sin www; rutas viejas → `/`.
- Root Directory de cada servicio = su carpeta; config en `<carpeta>/railway.json`.

## Base de datos y migraciones
Migraciones en `db/migraciones/` (cada una en transacción, se pueden volver a correr):
`2026-10-06_menu_disponibilidad` · `2026-10-08_paquetes` · `2026-10-09_usuarios_por_area` ·
`2026-10-10_editar_datos_usuario` · `2026-10-10_landing` · `2026-10-11_confirmar_con_abono`.
Al 10-oct Luis dijo que ya corrió las de áreas y landing y creó el salón de GADZI; **confirmar con él** si ya
corrió `confirmar_con_abono` (está commiteada). No hay tabla de control de migraciones todavía.
Al cambiar una función/procedimiento: migración nueva + actualizar su archivo en `db/funciones|procedures`.
Si cambia el tipo de retorno de una función o los parámetros de un procedimiento, la migración necesita
`DROP ... IF EXISTS` antes del `CREATE`.

## Cómo probar (sin tocar Neon)
- Backend: `cd la-quebrada-backend && npx tsc --noEmit -p . && npm test` (31 pruebas con node:test).
- Frontend: `cd la-quebrada-frontend && npx ng build` (el aviso de tamaño del bundle ya existía).
- Pruebas de punta a punta: Postgres desechable con `initdb` en otro puerto (ej. 5499, auth trust) →
  cargar `db/esquema_completo.sql` + todas las migraciones + datos de prueba → backend con
  `DATABASE_URL=postgresql://...@localhost:5499/... PORT=3010` → frontend compilado servido con Caddy en otro
  puerto con `BACKEND_URL=http://localhost:3010` → Puppeteer (está en node_modules del backend).
  Apagar todo al terminar. Escribir datos con acentos desde archivo .sql (desde la terminal se rompe la ñ).

## Dominio (pendiente)
`eventoslaquebrada.com`: DNS en **Register.com**, sitio viejo en **Weebly**, correo `@eventoslaquebrada.com`
en **Google Workspace**. Al apuntarlo a Railway: `@` y `www` → landing, `sistema` → frontend; **no tocar los
registros MX ni TXT del correo**; capturar la zona DNS antes. Luis iba a conseguir el acceso con quien
administraba el sitio. El correo que muestra la landing (`contacto@laquebrada.com.gt`) es de un dominio que
NO existe: reemplazarlo por el correo real cuando Luis lo confirme.

## Pendientes por prioridad
1. Dominio (arriba) y borrar `la-quebrada-landing/machote/`.
2. **Respaldos** automáticos de la base (pg_dump programado) y de los comprobantes del volumen; probar una
   restauración. **Alertas** de Railway y monitoreo de errores (Sentry); aviso si fallan los recordatorios.
3. Esquema actualizado desde Neon + control de migraciones; rama de desarrollo en Neon; pruebas permanentes
   del alcance por área y de confirmar/aplicar paquete; CI en GitHub Actions; pruebas del frontend.
4. Eventos después de medianoche (decidir con Luis); aviso cuando se rechaza el abono de un evento
   confirmado; pantalla de Salones; áreas al crear usuario; bitácora de auditoría; pantalla de catálogos
   base; abono mínimo configurable.
5. Sesión en cookie httpOnly; recordatorios como cron de Railway; reducir bundle; limpiar código viejo
   (ej. `comoponentes-menu.routes.ts`); accesibilidad.
6. Landing: SEO (sitemap, robots, metadatos para WhatsApp), Search Console / Google Business, imágenes WebP.
7. Manual de uso para el personal y README técnico.
