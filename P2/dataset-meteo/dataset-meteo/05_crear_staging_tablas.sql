-- =====================================================================
-- STAGING – Tablas auxiliares necesarias para ambas transformaciones
-- Ejecutar UNA VEZ antes de abrir los .ktr en Spoon
-- BD: practicassm
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS staging;

-- ─── Para limpieza_meteo_completo.ktr ────────────────────────────────

CREATE TABLE IF NOT EXISTS staging.observaciones_clean (
    observacion_id       INT,
    fecha                DATE         NOT NULL,
    ciudad               VARCHAR(80)  NOT NULL,
    estacion_id          INT,
    temp_max             DECIMAL(5,1),
    temp_min             DECIMAL(5,1),
    temp_media           DECIMAL(5,1),
    precipitacion_mm     DECIMAL(6,1),
    humedad_pct          INT,
    velocidad_viento_kmh DECIMAL(5,1),
    condicion_climatica  VARCHAR(50),
    CONSTRAINT uq_stg_obs_clean UNIQUE (fecha, ciudad)
);

CREATE TABLE IF NOT EXISTS staging.etl_log_fk_huerfanas (
    id               SERIAL PRIMARY KEY,
    observacion_id   INT,
    fecha            DATE,
    ciudad           VARCHAR(80),
    estacion_id      INT,
    lkp_estacion     VARCHAR(100),
    ts_carga         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─── dim_clima en olap_snow (si no existe) ────────────────────────────
CREATE SCHEMA IF NOT EXISTS olap_snow;

CREATE TABLE IF NOT EXISTS olap_snow.dim_clima (
    clima_sk              SERIAL PRIMARY KEY,
    fecha                 DATE         NOT NULL,
    ciudad                VARCHAR(80)  NOT NULL,
    anio                  INT,
    mes                   INT,
    dia_del_anio          INT,
    temp_max              DECIMAL(5,1),
    temp_min              DECIMAL(5,1),
    temp_media            DECIMAL(5,1),
    precipitacion_mm      DECIMAL(6,1),
    humedad_pct           INT,
    velocidad_viento_kmh  DECIMAL(5,1),
    condicion_climatica   VARCHAR(50),
    es_dia_lluvia         BOOLEAN,
    categoria_temperatura VARCHAR(20),
    fecha_carga           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_dim_clima_fc UNIQUE (fecha, ciudad)
);

SELECT 'Staging y tablas auxiliares creados correctamente' AS resultado;
