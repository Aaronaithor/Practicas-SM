SET search_path TO meteo;

-- 2. Limpieza previa (opcional, para evitar errores de duplicados si re-ejecutas)
TRUNCATE TABLE meteo.estaciones_meteorologicas RESTART IDENTITY CASCADE;
TRUNCATE TABLE meteo.observaciones_diarias RESTART IDENTITY CASCADE;

-- 3. Carga de Estaciones Meteorológicas
-- Usamos la ruta absoluta directa para evitar fallos de psql con variables
\copy meteo.estaciones_meteorologicas(estacion_id, nombre_estacion, ciudad, latitud, longitud, altitud_metros, activa, fecha_instalacion) FROM 'TURUTA/estaciones_meteorologicas.csv' WITH (FORMAT CSV, HEADER true, DELIMITER ',');

-- 4. Carga de Observaciones Diarias
-- Asegúrate de que la ruta sea exactamente esta
\copy meteo.observaciones_diarias(observacion_id, fecha, ciudad, estacion_id, temp_max, temp_min, temp_media, precipitacion_mm, humedad_pct, velocidad_viento_kmh, condicion_climatica) FROM 'TURUTA/observaciones_diarias.csv' WITH (FORMAT CSV, HEADER true, DELIMITER ',', NULL '');

-- 5. Verificación de resultados
SELECT 'estaciones_meteorologicas' AS tabla, COUNT(*) AS registros FROM meteo.estaciones_meteorologicas
UNION ALL
SELECT 'observaciones_diarias', COUNT(*) FROM meteo.observaciones_diarias;
