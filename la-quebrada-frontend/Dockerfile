# Frontend de La Quebrada para Railway: compila Angular y lo sirve con Caddy.
# Caddy también reenvía /api al backend por la red privada de Railway (mismo dominio, sin CORS).

# ---- 1. Compilar ----
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- 2. Servir ----
FROM caddy:2-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/dist/la-quebrada-frontend/browser /srv
# Railway define PORT; BACKEND_URL se configura como variable del servicio
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
