-- ============================================================
-- COLMENA — Esquema de base de datos (PostgreSQL + PostGIS)
-- Sin ORM — SQL directo, ejecutado vía sqlx migrate
-- ============================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- para gen_random_uuid()

-- ============================================================
-- 1. CATÁLOGOS (entidades fuertes de valores fijos)
-- ============================================================

CREATE TABLE roles (
    codigo TEXT PRIMARY KEY,
    nombre TEXT NOT NULL
);

CREATE TABLE tamanos_draga (
    codigo TEXT PRIMARY KEY,
    nombre TEXT NOT NULL
);

CREATE TABLE tiempos_operacion (
    codigo TEXT PRIMARY KEY,
    nombre TEXT NOT NULL
);

CREATE TABLE estados_reporte (
    codigo TEXT PRIMARY KEY,
    nombre TEXT NOT NULL
);

CREATE TABLE niveles_riesgo (
    codigo TEXT PRIMARY KEY,
    nombre TEXT NOT NULL
);

CREATE TABLE tipos_zona (
    codigo TEXT PRIMARY KEY,
    nombre TEXT NOT NULL
);

CREATE TABLE herramientas_mcp (
    codigo TEXT PRIMARY KEY,
    nombre TEXT NOT NULL
);

CREATE TABLE tipos_accion (
    codigo TEXT PRIMARY KEY,
    nombre TEXT NOT NULL
    -- ej: CREAR, ACTUALIZAR, ELIMINAR, LOGIN, CAMBIO_ESTADO
);

CREATE TABLE entidades_auditables (
    codigo TEXT PRIMARY KEY,
    nombre TEXT NOT NULL
    -- ej: REPORTE, USUARIO, EVALUACION
);

-- ============================================================
-- 2. ENTIDADES FUERTES PRINCIPALES
-- ============================================================

CREATE TABLE usuarios (
    codigo UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    correo TEXT UNIQUE NOT NULL,
    contrasena_hash TEXT NOT NULL,
    rol_codigo TEXT NOT NULL REFERENCES roles(codigo),
    fecha_creacion DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_creacion TIME NOT NULL DEFAULT CURRENT_TIME
);

CREATE TABLE reportes (
    codigo UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ubicacion GEOGRAPHY(POINT, 4326) NOT NULL,
    tamano_draga_codigo TEXT NOT NULL REFERENCES tamanos_draga(codigo),
    tiempo_operacion_codigo TEXT NOT NULL REFERENCES tiempos_operacion(codigo),
    personas_visibles BOOLEAN NOT NULL DEFAULT false,
    motobombas_visibles BOOLEAN NOT NULL DEFAULT false,
    estado_codigo TEXT NOT NULL REFERENCES estados_reporte(codigo) DEFAULT 'nuevo',
    fecha_creacion DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_creacion TIME NOT NULL DEFAULT CURRENT_TIME
);
CREATE INDEX idx_reportes_ubicacion ON reportes USING GIST (ubicacion);
CREATE INDEX idx_reportes_estado ON reportes (estado_codigo);

CREATE TABLE zonas_protegidas (
    codigo UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    tipo_zona_codigo TEXT NOT NULL REFERENCES tipos_zona(codigo),
    geom GEOGRAPHY(POLYGON, 4326) NOT NULL
);
CREATE INDEX idx_zonas_geom ON zonas_protegidas USING GIST (geom);

CREATE TABLE normativa (
    codigo UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titulo TEXT NOT NULL,
    texto_resumen TEXT NOT NULL
);

-- Trazabilidad técnica: qué tool del MCP se invocó y con qué datos
CREATE TABLE trazabilidad_mcp (
    codigo UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    herramienta_codigo TEXT NOT NULL REFERENCES herramientas_mcp(codigo),
    reporte_codigo UUID REFERENCES reportes(codigo) ON DELETE SET NULL,
    parametros JSONB,
    resultado JSONB,
    fecha_creacion DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_creacion TIME NOT NULL DEFAULT CURRENT_TIME
);

-- Auditoría general: quién hizo qué acción sobre qué entidad de negocio
-- Nota: entidad_afectada_codigo no lleva FK real (referencia "polimórfica"
-- según entidad_codigo) — la integridad la valida el código Rust del api,
-- no la base de datos. Sin ON DELETE CASCADE a propósito: el log debe
-- sobrevivir aunque se borre lo que audita.
CREATE TABLE logs_auditoria (
    codigo UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_codigo UUID REFERENCES usuarios(codigo),
    tipo_accion_codigo TEXT NOT NULL REFERENCES tipos_accion(codigo),
    entidad_codigo TEXT NOT NULL REFERENCES entidades_auditables(codigo),
    entidad_afectada_codigo UUID NOT NULL,
    detalle JSONB,
    fecha_creacion DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_creacion TIME NOT NULL DEFAULT CURRENT_TIME
);

-- ============================================================
-- 3. ENTIDADES DÉBILES (la PK de la entidad fuerte se propaga)
-- ============================================================

-- 1 a 1 con reportes: dato de contacto opcional del informante
CREATE TABLE contacto_informante (
    reporte_codigo UUID PRIMARY KEY REFERENCES reportes(codigo) ON DELETE CASCADE,
    alias TEXT,
    celular TEXT
);

-- 1 a 1 con reportes: nota libre opcional
CREATE TABLE notas_reporte (
    reporte_codigo UUID PRIMARY KEY REFERENCES reportes(codigo) ON DELETE CASCADE,
    texto TEXT NOT NULL
);

-- 1 a 1 con reportes: momento real de sincronización (si ya ocurrió)
CREATE TABLE sincronizacion_reporte (
    reporte_codigo UUID PRIMARY KEY REFERENCES reportes(codigo) ON DELETE CASCADE,
    fecha_sincronizacion DATE NOT NULL,
    hora_sincronizacion TIME NOT NULL
);

-- 1 a N con reportes: evidencia fotográfica (débil multivaluada)
CREATE TABLE fotos (
    reporte_codigo UUID NOT NULL REFERENCES reportes(codigo) ON DELETE CASCADE,
    secuencia INT NOT NULL,
    ruta_archivo TEXT NOT NULL,
    fecha_creacion DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_creacion TIME NOT NULL DEFAULT CURRENT_TIME,
    PRIMARY KEY (reporte_codigo, secuencia)
);

-- Débil de una débil: metadato EXIF de cada foto (puede no existir)
CREATE TABLE exif_foto (
    reporte_codigo UUID NOT NULL,
    secuencia INT NOT NULL,
    fecha_exif DATE,
    hora_exif TIME,
    PRIMARY KEY (reporte_codigo, secuencia),
    FOREIGN KEY (reporte_codigo, secuencia)
        REFERENCES fotos(reporte_codigo, secuencia) ON DELETE CASCADE
);

-- 1 a 1 con reportes: resultado del análisis del agente
CREATE TABLE evaluaciones (
    reporte_codigo UUID PRIMARY KEY REFERENCES reportes(codigo) ON DELETE CASCADE,
    factor_mercurio NUMERIC NOT NULL,
    mercurio_estimado_kg NUMERIC NOT NULL,
    zona_codigo UUID REFERENCES zonas_protegidas(codigo),
    normativa_codigo UUID REFERENCES normativa(codigo),
    nivel_riesgo_codigo TEXT NOT NULL REFERENCES niveles_riesgo(codigo),
    fecha_creacion DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_creacion TIME NOT NULL DEFAULT CURRENT_TIME
);

-- 1 a 1 con evaluaciones: estimación económica del daño (opcional)
CREATE TABLE estimacion_economica (
    reporte_codigo UUID PRIMARY KEY REFERENCES evaluaciones(reporte_codigo) ON DELETE CASCADE,
    valor_bs NUMERIC NOT NULL
);

-- 1 a 1 con evaluaciones: referencia al PDF generado (opcional)
CREATE TABLE documento_pdf (
    reporte_codigo UUID PRIMARY KEY REFERENCES evaluaciones(reporte_codigo) ON DELETE CASCADE,
    ruta_archivo TEXT NOT NULL
);

-- 1 a 1 con normativa: detalle de artículo/fuente (opcional)
CREATE TABLE referencia_normativa (
    normativa_codigo UUID PRIMARY KEY REFERENCES normativa(codigo) ON DELETE CASCADE,
    articulo TEXT,
    url_fuente TEXT NOT NULL
);

-- ============================================================
-- 4. DATOS INICIALES DE CATÁLOGOS
-- ============================================================

INSERT INTO roles (codigo, nombre) VALUES
    ('ANALISTA', 'Analista'),
    ('ADMIN', 'Administrador');

INSERT INTO tamanos_draga (codigo, nombre) VALUES
    ('PEQUENA', 'Pequeña'),
    ('MEDIANA', 'Mediana'),
    ('GRANDE', 'Grande');

INSERT INTO tiempos_operacion (codigo, nombre) VALUES
    ('MENOS_1_DIA', 'Menos de 1 día'),
    ('VARIOS_DIAS', 'Varios días'),
    ('MAS_1_SEMANA', 'Más de una semana');

INSERT INTO estados_reporte (codigo, nombre) VALUES
    ('nuevo', 'Nuevo'),
    ('revisado', 'Revisado'),
    ('escalado', 'Escalado');

INSERT INTO niveles_riesgo (codigo, nombre) VALUES
    ('BAJO', 'Bajo'),
    ('MEDIO', 'Medio'),
    ('ALTO', 'Alto');

INSERT INTO tipos_zona (codigo, nombre) VALUES
    ('AREA_PROTEGIDA', 'Área protegida'),
    ('TERRITORIO_INDIGENA', 'Territorio indígena');

INSERT INTO herramientas_mcp (codigo, nombre) VALUES
    ('NORMATIVA', 'Consulta de normativa'),
    ('ESTIMACION_ECONOMICA', 'Estimación económica del daño'),
    ('UBICACION', 'Verificación de ubicación/jurisdicción'),
    ('REPORTE_PDF', 'Generación de reporte PDF');

INSERT INTO tipos_accion (codigo, nombre) VALUES
    ('CREAR', 'Crear'),
    ('ACTUALIZAR', 'Actualizar'),
    ('ELIMINAR', 'Eliminar'),
    ('LOGIN', 'Inicio de sesión'),
    ('CAMBIO_ESTADO', 'Cambio de estado');

INSERT INTO entidades_auditables (codigo, nombre) VALUES
    ('REPORTE', 'Reporte'),
    ('USUARIO', 'Usuario'),
    ('EVALUACION', 'Evaluación');
