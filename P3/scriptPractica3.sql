-------------------------------------------------------
-- 2.1  EVOLUCIÓN DE INGRESOS POR CATEGORÍA Y TIEMPO --
-------------------------------------------------------

-- Consulta analítica
SELECT df.anio, df.mes, dp.categoria,
       SUM(hv.importe) AS ingresos_totales
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_fecha df    ON hv.fecha_id    = df.fecha_id
JOIN datawarehouse.dim_producto dp ON hv.producto_id = dp.producto_id
GROUP BY df.anio, df.mes, dp.categoria
ORDER BY df.anio, df.mes, dp.categoria;

-- Plan de ejecución
EXPLAIN ANALYZE
SELECT df.anio, df.mes, dp.categoria,
       SUM(hv.importe) AS ingresos_totales
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_fecha df    ON hv.fecha_id    = df.fecha_id
JOIN datawarehouse.dim_producto dp ON hv.producto_id = dp.producto_id
GROUP BY df.anio, df.mes, dp.categoria
ORDER BY df.anio, df.mes, dp.categoria;

-- Optimización 1: índices sobre las claves de unión de la tabla de hechos
CREATE INDEX IF NOT EXISTS idx_hechos_ventas_fecha    ON datawarehouse.hechos_ventas(fecha_id);
CREATE INDEX IF NOT EXISTS idx_hechos_ventas_producto ON datawarehouse.hechos_ventas(producto_id);

-- Optimización 2: vista materializada (consulta recurrente de dashboard)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_ingresos_categoria_mes AS
SELECT df.anio, df.mes, dp.categoria,
       SUM(hv.importe) AS ingresos_totales
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_fecha df    ON hv.fecha_id    = df.fecha_id
JOIN datawarehouse.dim_producto dp ON hv.producto_id = dp.producto_id
GROUP BY df.anio, df.mes, dp.categoria;

-- Consulta optimizada (lee la vista) + plan de ejecución 
EXPLAIN ANALYZE
SELECT * FROM mv_ingresos_categoria_mes
ORDER BY anio, mes, categoria;


---------------------------------------------
-- 2.2  TOP CLIENTES POR INGRESOS Y REGIÓN --
---------------------------------------------

-- Consulta analítica original
SELECT dc.nombre, dc.pais, dc.ciudad,
       SUM(hv.importe) AS total_ingresos,
       COUNT(DISTINCT hv.hecho_id) AS numero_transacciones
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_cliente dc ON hv.cliente_id = dc.cliente_id
GROUP BY dc.cliente_id, dc.nombre, dc.pais, dc.ciudad
ORDER BY total_ingresos DESC
LIMIT 20;

-- Plan de ejecución
EXPLAIN ANALYZE
SELECT dc.nombre, dc.pais, dc.ciudad,
       SUM(hv.importe) AS total_ingresos,
       COUNT(DISTINCT hv.hecho_id) AS numero_transacciones
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_cliente dc ON hv.cliente_id = dc.cliente_id
GROUP BY dc.cliente_id, dc.nombre, dc.pais, dc.ciudad
ORDER BY total_ingresos DESC
LIMIT 20;

-- Optimización 1: reescritura (COUNT(DISTINCT) -> COUNT(*), elimina la ordenación intermedia)
-- Optimización 2: índice sobre la clave de unión
CREATE INDEX IF NOT EXISTS idx_hechos_ventas_cliente ON datawarehouse.hechos_ventas(cliente_id);

-- Consulta optimizada (reescrita) + plan de ejecución
EXPLAIN ANALYZE
SELECT dc.nombre, dc.pais, dc.ciudad,
       SUM(hv.importe) AS total_ingresos,
       COUNT(*) AS numero_transacciones
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_cliente dc ON hv.cliente_id = dc.cliente_id
GROUP BY dc.cliente_id, dc.nombre, dc.pais, dc.ciudad
ORDER BY total_ingresos DESC
LIMIT 20;


---------------------------------------------------
-- 2.3  TRANSPORTISTAS POR VALOR MEDIO DE PEDIDO --
---------------------------------------------------

-- Consulta analítica
SELECT dt.nombre,
       ROUND(AVG(hv.importe),2) AS valor_medio_pedido,
       COUNT(*) AS total_pedidos
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_transportista dt ON hv.transportista_id = dt.transportista_id
GROUP BY dt.transportista_id, dt.nombre
ORDER BY valor_medio_pedido DESC;

-- Plan de ejecución
EXPLAIN ANALYZE
SELECT dt.nombre,
       ROUND(AVG(hv.importe),2) AS valor_medio_pedido,
       COUNT(*) AS total_pedidos
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_transportista dt ON hv.transportista_id = dt.transportista_id
GROUP BY dt.transportista_id, dt.nombre
ORDER BY valor_medio_pedido DESC;

-- Optimización: índice sobre la clave de unión
CREATE INDEX IF NOT EXISTS idx_hechos_ventas_transportista ON datawarehouse.hechos_ventas(transportista_id);

-- Plan de ejecución (a este volumen el plan no cambia)
EXPLAIN ANALYZE
SELECT dt.nombre,
       ROUND(AVG(hv.importe),2) AS valor_medio_pedido,
       COUNT(*) AS total_pedidos
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_transportista dt ON hv.transportista_id = dt.transportista_id
GROUP BY dt.transportista_id, dt.nombre
ORDER BY valor_medio_pedido DESC;

-------------------------------------------------
-- 2.4  VOLUMEN DE VENTAS POR ESTADO DE PEDIDO --
-------------------------------------------------

-- Consulta analítica
SELECT dep.nombre,
       COUNT(*) AS numero_ventas,
       SUM(hv.importe) AS importe_total,
       ROUND(AVG(hv.importe),2) AS importe_medio
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_estado_pedido dep ON hv.estado_id = dep.estado_id
GROUP BY dep.nombre
ORDER BY importe_total DESC;

-- Plan de ejecución
EXPLAIN ANALYZE
SELECT dep.nombre,
       COUNT(*) AS numero_ventas,
       SUM(hv.importe) AS importe_total,
       ROUND(AVG(hv.importe),2) AS importe_medio
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_estado_pedido dep ON hv.estado_id = dep.estado_id
GROUP BY dep.nombre
ORDER BY importe_total DESC;

-- Optimización: índice sobre la clave de unión
CREATE INDEX IF NOT EXISTS idx_hechos_ventas_estado ON datawarehouse.hechos_ventas(estado_id);

-- Plan de ejecución (a este volumen el plan no cambia)
EXPLAIN ANALYZE
SELECT dep.nombre,
       COUNT(*) AS numero_ventas,
       SUM(hv.importe) AS importe_total,
       ROUND(AVG(hv.importe),2) AS importe_medio
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_estado_pedido dep ON hv.estado_id = dep.estado_id
GROUP BY dep.nombre
ORDER BY importe_total DESC;

---------------------------------
-- 2.5  PRODUCTOS MÁS VENDIDOS --
---------------------------------

-- Consulta analítica
SELECT dp.nombre, dp.categoria,
       SUM(hv.cantidad) AS unidades_vendidas,
       SUM(hv.importe)  AS ingresos_generados
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_producto dp ON hv.producto_id = dp.producto_id
GROUP BY dp.producto_id, dp.nombre, dp.categoria
ORDER BY unidades_vendidas DESC
LIMIT 20;

-- Plan de ejecución
EXPLAIN ANALYZE
SELECT dp.nombre, dp.categoria,
       SUM(hv.cantidad) AS unidades_vendidas,
       SUM(hv.importe)  AS ingresos_generados
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_producto dp ON hv.producto_id = dp.producto_id
GROUP BY dp.producto_id, dp.nombre, dp.categoria
ORDER BY unidades_vendidas DESC
LIMIT 20;

-- Optimización 1: índice sobre producto_id (ya creado en el apartado 2.1)
-- Optimización 2: vista materializada (ranking recurrente de dashboard)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_top_productos AS
SELECT dp.producto_id, dp.nombre, dp.categoria,
       SUM(hv.cantidad) AS unidades_vendidas,
       SUM(hv.importe)  AS ingresos_generados
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_producto dp ON hv.producto_id = dp.producto_id
GROUP BY dp.producto_id, dp.nombre, dp.categoria;

-- Consulta optimizada (lee la vista) + plan de ejecución
EXPLAIN ANALYZE
SELECT nombre, categoria, unidades_vendidas, ingresos_generados
FROM mv_top_productos
ORDER BY unidades_vendidas DESC
LIMIT 20;

-- Refresh de las vistas materializadas
REFRESH MATERIALIZED VIEW mv_ingresos_categoria_mes;
REFRESH MATERIALIZED VIEW mv_top_productos;