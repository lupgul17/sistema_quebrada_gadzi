# Landing pública de La Quebrada para Railway: página estática servida con Caddy.
# Caddy también reenvía /api/publico al backend por la red privada de Railway (mismo dominio, sin CORS).
FROM caddy:2-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY sitio /srv
# Railway define PORT; BACKEND_URL se configura como variable del servicio
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
