# Backend de La Quebrada para Railway (o cualquier servicio que corra contenedores).
# Incluye Chromium del sistema para los PDF (Puppeteer) y la zona horaria de Guatemala.
FROM node:22-bookworm-slim

ENV NODE_ENV=production \
    TZ=America/Guatemala \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Chromium + fuentes (tildes, ñ y símbolos en los PDF) + zona horaria
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       chromium fonts-liberation fonts-dejavu-core fonts-noto-color-emoji tzdata ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Dependencias primero (se cachean si package*.json no cambia)
COPY package*.json ./
RUN npm ci --include=dev

COPY . .
RUN npm run build && npm prune --omit=dev

EXPOSE 3000
CMD ["node", "dist/index.js"]
