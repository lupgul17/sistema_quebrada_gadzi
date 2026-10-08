-- Áreas de cada usuario (y logo de cada locación). Ver db/migraciones/2026-10-09_usuarios_por_area.sql
ALTER TABLE locacion ADD COLUMN IF NOT EXISTS logo VARCHAR(100);

CREATE TABLE IF NOT EXISTS usuario_area (
    id_usuario_area SERIAL PRIMARY KEY,
    id_usuario   INTEGER NOT NULL REFERENCES usuario (id_usuario) ON DELETE CASCADE,
    id_locacion  INTEGER REFERENCES locacion (id_locacion),
    id_salon     INTEGER REFERENCES salon (id_salon),
    -- Cada fila es UNA locación completa o UN salón
    CONSTRAINT chk_usuario_area_una CHECK ((id_locacion IS NULL) <> (id_salon IS NULL))
);
CREATE INDEX IF NOT EXISTS idx_usuario_area_usuario ON usuario_area (id_usuario);
CREATE UNIQUE INDEX IF NOT EXISTS uq_usuario_area_locacion ON usuario_area (id_usuario, id_locacion) WHERE id_locacion IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_usuario_area_salon ON usuario_area (id_usuario, id_salon) WHERE id_salon IS NOT NULL;
