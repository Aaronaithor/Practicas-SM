-- =====================================================================
-- SCRIPT DE LIMPIEZA – Dataset Meteorológico
--
-- Aplica las reglas de limpieza sobre staging.stg_observaciones
-- y deja los datos listos para cargar en dim_clima del DW
-- =====================================================================

SET search_path TO staging;

-- ─────────────────────────────────────────────────────────────────────
-- Paso 1: Copiar datos crudos a staging
-- ─────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS stg_observaciones_raw;
CREATE TABLE stg_observaciones_raw AS
SELECT * FROM meteo.observaciones_diarias;

-- ─────────────────────────────────────────────────────────────────────
-- Paso 2: Crear tabla de staging limpia
-- ─────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS stg_observaciones_clean;
CREATE TABLE stg_observaciones_clean AS
SELECT
    observacion_id,
    fecha,
    -- R01: Normalizar nombre de ciudad
    CASE
        WHEN LOWER(TRIM(ciudad)) IN ('granada','grañada','granada ') THEN 'Granada'
        WHEN LOWER(TRIM(ciudad)) IN ('sevilla','sevila')             THEN 'Sevilla'
        WHEN LOWER(TRIM(ciudad)) IN ('málaga','malaga','malaga')     THEN 'Málaga'
        WHEN LOWER(TRIM(ciudad)) IN ('madrid','madríd')              THEN 'Madrid'
        WHEN LOWER(TRIM(ciudad)) IN ('barcelona','barceloña')        THEN 'Barcelona'
        ELSE INITCAP(TRIM(ciudad))
    END AS ciudad,
    estacion_id,

    -- R02: Corregir errores de sensor (-99 → NULL)
    CASE WHEN temp_max = -99.0 THEN NULL ELSE temp_max END AS temp_max,
    CASE WHEN temp_min = -99.0 THEN NULL ELSE temp_min END AS temp_min,
    CASE WHEN temp_media = -99.0 THEN NULL ELSE temp_media END AS temp_media,

    -- R03: Precipitación negativa → 0
    CASE WHEN precipitacion_mm < 0 THEN 0.0 ELSE precipitacion_mm END AS precipitacion_mm,

    -- R04: Humedad fuera de rango → NULL
    CASE WHEN humedad_pct < 0 OR humedad_pct > 100 THEN NULL ELSE humedad_pct END AS humedad_pct,

    velocidad_viento_kmh,

    -- R05: Condición climática inválida → 'Desconocido'
    CASE
        WHEN condicion_climatica IN ('N/A','999','DESCONOCIDO','--','error','null')
            OR condicion_climatica IS NULL
        THEN 'Desconocido'
        ELSE condicion_climatica
    END AS condicion_climatica,

    -- R06: Marcar registros con temp_min > temp_max (invertidas) para revisión
    CASE WHEN temp_min > temp_max AND temp_max <> -99.0 THEN TRUE ELSE FALSE END AS flag_temp_invertida

FROM stg_observaciones_raw
WHERE
    -- R07: Eliminar registros completamente vacíos
    NOT (temp_max IS NULL AND temp_min IS NULL AND precipitacion_mm IS NULL)
    -- R08: Eliminar duplicados (conservar el de menor observacion_id)
    AND observacion_id IN (
        SELECT MIN(observacion_id)
        FROM stg_observaciones_raw
        WHERE temp_max IS NOT NULL
        GROUP BY fecha, ciudad
    );

-- ─────────────────────────────────────────────────────────────────────
-- Paso 3: Registrar anomalías rechazadas en etl_errores
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO staging.etl_errores (tabla_origen, registro_id, campo_error, valor_problematico, descripcion_error)
SELECT
    'meteo.observaciones_diarias',
    observacion_id,
    'estacion_id',
    estacion_id::TEXT,
    'estacion_id no existe en estaciones_meteorologicas (FK huérfana)'
FROM stg_observaciones_raw o
WHERE NOT EXISTS (
    SELECT 1 FROM meteo.estaciones_meteorologicas e WHERE e.estacion_id = o.estacion_id
);

-- ─────────────────────────────────────────────────────────────────────
-- Paso 4: Validar resultado de la limpieza
-- ─────────────────────────────────────────────────────────────────────
SELECT
    'Registros originales'    AS concepto, COUNT(*) AS cantidad FROM stg_observaciones_raw
UNION ALL
SELECT 'Registros limpios',    COUNT(*) FROM stg_observaciones_clean
UNION ALL
SELECT 'Registros eliminados', COUNT(*) FROM stg_observaciones_raw
    WHERE observacion_id NOT IN (SELECT observacion_id FROM stg_observaciones_clean);
