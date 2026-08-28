# La Quebrada — Backend

Backend en Node.js + TypeScript + Express, con acceso directo a Postgres vía `pg` (sin ORM).

## Arranque

1. `npm install`
2. Copiar `.env.example` a `.env` y pegar tu `DATABASE_URL` real de Neon.
3. `npm run dev` — levanta el servidor con recarga automática en `http://localhost:3000`.

## Probar que la conexión funciona

- `GET /api/health` — confirma que el servidor y la base de datos responden.
- `GET /api/salones` — lista los 6 salones de La Quebrada con su locación (join real contra la base).

## Estructura

```
src/
  db/
    pool.ts          # conexión a Postgres (pg.Pool)
  routes/
    salones.routes.ts
  index.ts           # arma la app Express y monta las rutas
```

Cada módulo nuevo (evento, cotización, pago, etc.) sigue el mismo patrón: un archivo de rutas en `src/routes/`, montado en `index.ts`.
