-- =====================================================================
-- DATASET METEOROLÓGICO – Sistemas Multidimensionales UGR 2025/2026
-- Profesor: José Ángel Díaz García
-- Uso: Caso práctico de Data Profiling en el Hito P2.1
--
-- INSTRUCCIONES:
--   1. Crear la base de datos si no existe:
--      createdb sistemas_multidimensionales
--   2. Ejecutar este script:
--      psql -d sistemas_multidimensionales -f 00_crear_tablas_meteo.sql
--   3. Cargar los CSV con el script 01_cargar_datos_meteo.sql
-- =====================================================================

-- Crear schema dedicado
CREATE SCHEMA IF NOT EXISTS meteo;
SET search_path TO meteo;

-- ─────────────────────────────────────────────────────────────────────
-- Tabla 1: Estaciones meteorológicas
-- ─────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS observaciones_diarias;
DROP TABLE IF EXISTS estaciones_meteorologicas;

CREATE TABLE estaciones_meteorologicas (
    estacion_id        SERIAL PRIMARY KEY,
    nombre_estacion    VARCHAR(100) NOT NULL,
    ciudad             VARCHAR(80)  NOT NULL,
    latitud            DECIMAL(9,6),
    longitud           DECIMAL(9,6),
    altitud_metros     INT,
    activa             BOOLEAN DEFAULT TRUE,
    fecha_instalacion  DATE
);

-- ─────────────────────────────────────────────────────────────────────
-- Tabla 2: Observaciones diarias
-- (Sin FK intencionadamente: permite cargar registros huérfanos)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE observaciones_diarias (
    observacion_id          SERIAL PRIMARY KEY,
    fecha                   DATE,
    ciudad                  VARCHAR(80),
    estacion_id             INT,          -- ⚠️ Sin FK: permite anomalía A6
    temp_max                DECIMAL(5,1),
    temp_min                DECIMAL(5,1),
    temp_media              DECIMAL(5,1),
    precipitacion_mm        DECIMAL(6,1),
    humedad_pct             INT,
    velocidad_viento_kmh    DECIMAL(5,1),
    condicion_climatica     VARCHAR(50)
);

-- Índices básicos
CREATE INDEX idx_obs_fecha    ON observaciones_diarias(fecha);
CREATE INDEX idx_obs_ciudad   ON observaciones_diarias(ciudad);
CREATE INDEX idx_obs_estacion ON observaciones_diarias(estacion_id);

COMMENT ON TABLE observaciones_diarias IS
    'Dataset meteorológico con anomalías intencionadas para práctica de Data Profiling. '
    'Contiene errores de sensor, duplicados, valores imposibles, FKs huérfanas y '
    'nombres de ciudad inconsistentes. Ver README_anomalias.md para el catálogo completo.';
