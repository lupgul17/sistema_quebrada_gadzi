-- Paquetes (cotizaciones predefinidas). Ver db/migraciones/2026-10-08_paquetes.sql
CREATE TABLE IF NOT EXISTS paquete (
    id_paquete          SERIAL PRIMARY KEY,
    nombre              VARCHAR(150) NOT NULL,
    descripcion         TEXT,
    precio_por_persona  NUMERIC(10,2) NOT NULL CHECK (precio_por_persona > 0),
    minimo_personas     INTEGER NOT NULL DEFAULT 1 CHECK (minimo_personas > 0),
    id_tipo_menu        INTEGER NOT NULL REFERENCES tc_tipo_menu (id_tipo_menu),
    activo              BOOLEAN NOT NULL DEFAULT true,
    fecha_creacion      TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Horas de uso de instalaciones incluidas; si el evento dura más se sugiere la hora extra
ALTER TABLE paquete ADD COLUMN IF NOT EXISTS horas_incluidas INTEGER CHECK (horas_incluidas > 0);

-- Grupo de elección: 'menu' (menús del catálogo, ej. plato fuerte), 'componente' (ej. bebida fría:
-- naranjada/jamaica/gaseosa) o 'cortesia' (servicios a Q0, ej. discoteca/brindis/pastel)
CREATE TABLE IF NOT EXISTS paquete_grupo (
    id_paquete_grupo   SERIAL PRIMARY KEY,
    id_paquete         INTEGER NOT NULL REFERENCES paquete (id_paquete) ON DELETE CASCADE,
    tipo               VARCHAR(10) NOT NULL,
    nombre             VARCHAR(100) NOT NULL,
    cantidad_a_elegir  INTEGER NOT NULL DEFAULT 1 CHECK (cantidad_a_elegir > 0),
    orden              INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_paquete_grupo_paquete ON paquete_grupo (id_paquete);
ALTER TABLE paquete_grupo DROP CONSTRAINT IF EXISTS paquete_grupo_tipo_check;
ALTER TABLE paquete_grupo ADD CONSTRAINT paquete_grupo_tipo_check CHECK (tipo IN ('menu', 'componente', 'cortesia'));

-- Opción de un grupo: un menú, un componente o un servicio (según el tipo del grupo)
CREATE TABLE IF NOT EXISTS paquete_grupo_opcion (
    id_paquete_grupo_opcion SERIAL PRIMARY KEY,
    id_paquete_grupo  INTEGER NOT NULL REFERENCES paquete_grupo (id_paquete_grupo) ON DELETE CASCADE,
    id_menu           INTEGER REFERENCES menu (id_menu),
    id_componente     INTEGER REFERENCES componente_menu (id_componente),
    id_servicio       INTEGER REFERENCES servicios (id_servicio)
);
ALTER TABLE paquete_grupo_opcion ADD COLUMN IF NOT EXISTS id_componente INTEGER REFERENCES componente_menu (id_componente);
ALTER TABLE paquete_grupo_opcion DROP CONSTRAINT IF EXISTS chk_paquete_opcion_una;
ALTER TABLE paquete_grupo_opcion ADD CONSTRAINT chk_paquete_opcion_una CHECK (num_nonnulls(id_menu, id_componente, id_servicio) = 1);
CREATE INDEX IF NOT EXISTS idx_paquete_opcion_grupo ON paquete_grupo_opcion (id_paquete_grupo);

-- Lo que incluye el paquete (a Q0): un servicio (cantidad fija, o "1 por cada N personas" como
-- los meseros) o solo un texto que se muestra en la cotización (ej. "Cristalería: plato, tenedor...")
CREATE TABLE IF NOT EXISTS paquete_incluido (
    id_paquete_incluido  SERIAL PRIMARY KEY,
    id_paquete           INTEGER NOT NULL REFERENCES paquete (id_paquete) ON DELETE CASCADE,
    id_servicio          INTEGER REFERENCES servicios (id_servicio),
    texto                VARCHAR(250),
    cantidad             INTEGER NOT NULL DEFAULT 1 CHECK (cantidad > 0),
    por_cada_personas    INTEGER CHECK (por_cada_personas > 0),
    orden                INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT chk_paquete_incluido_uno CHECK (num_nonnulls(id_servicio, texto) = 1)
);
CREATE INDEX IF NOT EXISTS idx_paquete_incluido_paquete ON paquete_incluido (id_paquete);

-- Extras opcionales con precio especial del paquete. calculo = cómo se sugiere la cantidad:
-- 'fijo' (la escribe el vendedor), 'por_persona' (los invitados), 'hora_extra' (horas sobre las incluidas)
CREATE TABLE IF NOT EXISTS paquete_extra (
    id_paquete   INTEGER NOT NULL REFERENCES paquete (id_paquete) ON DELETE CASCADE,
    id_servicio  INTEGER NOT NULL REFERENCES servicios (id_servicio),
    precio       NUMERIC(10,2) NOT NULL CHECK (precio >= 0),
    calculo      VARCHAR(12) NOT NULL DEFAULT 'fijo' CHECK (calculo IN ('fijo', 'por_persona', 'hora_extra')),
    orden        INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (id_paquete, id_servicio)
);

CREATE TABLE IF NOT EXISTS paquete_disponibilidad (
    id_paquete_disponibilidad SERIAL PRIMARY KEY,
    id_paquete   INTEGER NOT NULL REFERENCES paquete (id_paquete) ON DELETE CASCADE,
    id_locacion  INTEGER REFERENCES locacion (id_locacion),
    id_salon     INTEGER REFERENCES salon (id_salon),
    CONSTRAINT chk_paquete_disp_un_area CHECK ((id_locacion IS NULL) <> (id_salon IS NULL))
);
CREATE INDEX IF NOT EXISTS idx_paquete_disp_paquete ON paquete_disponibilidad (id_paquete);

-- De qué paquete salió una cotización y quién autorizó aplicarlo bajo el mínimo
ALTER TABLE cotizacion ADD COLUMN IF NOT EXISTS id_paquete INTEGER REFERENCES paquete (id_paquete);
ALTER TABLE cotizacion ADD COLUMN IF NOT EXISTS id_usuario_autoriza_minimo INTEGER REFERENCES usuario (id_usuario);

-- Lo que se eligió e incluye, congelado al aplicar. Va ligado al menú de la línea del paquete
-- (no a la cotización) para que siga ahí cuando se hace una versión nueva, que copia las líneas.
CREATE TABLE IF NOT EXISTS paquete_aplicado (
    id_menu          INTEGER PRIMARY KEY REFERENCES menu (id_menu) ON DELETE CASCADE,
    id_paquete       INTEGER NOT NULL REFERENCES paquete (id_paquete),
    elecciones       TEXT,              -- "Milanesa de pollo · Jamaica · 3 tortillas"
    incluye          JSONB NOT NULL DEFAULT '[]'::jsonb,  -- textos de "incluye"
    horas_incluidas  INTEGER
);
