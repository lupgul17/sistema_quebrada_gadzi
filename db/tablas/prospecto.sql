-- Solicitudes que llegan desde la landing page pública.
-- No son clientes ni eventos todavía: no bloquean fechas ni aparecen en reportes.
-- Al convertirse, se enlazan con el cliente y el evento creados desde el sistema.
CREATE TABLE IF NOT EXISTS prospecto (
    id_prospecto     SERIAL PRIMARY KEY,
    nombre           VARCHAR(150) NOT NULL,
    telefono         VARCHAR(30)  NOT NULL,
    correo           VARCHAR(150),
    id_tipo_evento   INTEGER REFERENCES tc_tipo_evento (id_tipo_evento),
    id_salon         INTEGER REFERENCES salon (id_salon),
    fecha_tentativa  DATE,
    invitados        INTEGER CHECK (invitados IS NULL OR invitados > 0),
    mensaje          TEXT,
    estado           VARCHAR(20) NOT NULL DEFAULT 'nuevo'
                     CHECK (estado IN ('nuevo', 'contactado', 'convertido', 'descartado')),
    notas_internas   TEXT,
    id_cliente       INTEGER REFERENCES cliente (id_cliente),
    id_evento        INTEGER REFERENCES evento (id_evento),
    ip_origen        VARCHAR(45),
    fecha_creacion   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_prospecto_estado ON prospecto (estado);
CREATE INDEX IF NOT EXISTS idx_prospecto_fecha_creacion ON prospecto (fecha_creacion DESC);
