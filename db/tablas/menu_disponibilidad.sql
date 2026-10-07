-- Áreas donde se ofrece cada menú: una fila = una locación completa o un salón.
-- Un menú SIN filas se ofrece en todos lados. Ver db/migraciones/2026-10-06_menu_disponibilidad.sql
CREATE TABLE IF NOT EXISTS menu_disponibilidad (
    id_menu_disponibilidad SERIAL PRIMARY KEY,
    id_menu      INTEGER NOT NULL REFERENCES menu (id_menu) ON DELETE CASCADE,
    id_locacion  INTEGER REFERENCES locacion (id_locacion),
    id_salon     INTEGER REFERENCES salon (id_salon),
    -- Cada fila es UNA locación completa o UN salón, nunca las dos cosas ni ninguna
    CONSTRAINT chk_menu_disp_un_area CHECK ((id_locacion IS NULL) <> (id_salon IS NULL))
);
CREATE INDEX IF NOT EXISTS idx_menu_disp_menu ON menu_disponibilidad (id_menu);
CREATE UNIQUE INDEX IF NOT EXISTS uq_menu_disp_locacion ON menu_disponibilidad (id_menu, id_locacion) WHERE id_locacion IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_menu_disp_salon ON menu_disponibilidad (id_menu, id_salon) WHERE id_salon IS NOT NULL;
