CREATE SCHEMA oltp_pedidos;
CREATE SCHEMA oltp_clientes;
CREATE SCHEMA oltp_catalogo;
CREATE SCHEMA oltp_envios;
CREATE SCHEMA oltp_pagos;

-- Clientes
CREATE TABLE oltp_clientes.clientes (
cliente_id SERIAL PRIMARY KEY,
nombre VARCHAR(100) NOT NULL,
email VARCHAR(100) UNIQUE NOT NULL,
telefono VARCHAR(20),
fecha_registro DATE
);

CREATE TABLE oltp_clientes.direcciones (
direccion_id SERIAL PRIMARY KEY,
cliente_id INT REFERENCES oltp_clientes.clientes(cliente_id),
direccion VARCHAR(150),
ciudad VARCHAR(50),
region VARCHAR(50),
pais VARCHAR(50)
);

CREATE TABLE oltp_clientes.segmentos (
segmento_id SERIAL PRIMARY KEY,
nombre VARCHAR(50)
);

CREATE TABLE oltp_clientes.historial_clientes (
historial_id SERIAL PRIMARY KEY,
cliente_id INT REFERENCES oltp_clientes.clientes(cliente_id),
segmento_id INT REFERENCES oltp_clientes.segmentos(segmento_id),
fecha_inicio DATE,
fecha_fin DATE
);

CREATE INDEX idx_cliente_email ON oltp_clientes.clientes(email);

-- Catalogo
CREATE TABLE oltp_catalogo.categorias (
categoria_id SERIAL PRIMARY KEY,
nombre VARCHAR(100)
);

CREATE TABLE oltp_catalogo.proveedores (
proveedor_id SERIAL PRIMARY KEY,
nombre VARCHAR(100),
contacto VARCHAR(100)
);

CREATE TABLE oltp_catalogo.productos (
producto_id SERIAL PRIMARY KEY,
nombre VARCHAR(100),
categoria_id INT REFERENCES oltp_catalogo.categorias(categoria_id),
proveedor_id INT REFERENCES oltp_catalogo.proveedores(proveedor_id),
precio NUMERIC(10,2) CHECK (precio > 0)
);

CREATE TABLE oltp_catalogo.stock (
stock_id SERIAL PRIMARY KEY,
producto_id INT REFERENCES oltp_catalogo.productos(producto_id),
cantidad INT CHECK (cantidad >= 0)
);

CREATE INDEX idx_producto_categoria ON oltp_catalogo.productos(categoria_id);

-- Pedidos
CREATE TABLE oltp_pedidos.estados_pedido (
estado_id SERIAL PRIMARY KEY,
nombre VARCHAR(50)
);

CREATE TABLE oltp_pedidos.pedidos (
pedido_id SERIAL PRIMARY KEY,
cliente_id INT REFERENCES oltp_clientes.clientes(cliente_id),
fecha_pedido DATE NOT NULL,
estado_id INT REFERENCES oltp_pedidos.estados_pedido(estado_id)
);

CREATE TABLE oltp_pedidos.lineas_pedido (
linea_id SERIAL PRIMARY KEY,
pedido_id INT REFERENCES oltp_pedidos.pedidos(pedido_id) ON DELETE CASCADE,
producto_id INT REFERENCES oltp_catalogo.productos(producto_id),
cantidad INT CHECK (cantidad > 0),
precio_unitario NUMERIC(10,2)
);

CREATE TABLE oltp_pedidos.devoluciones (
devolucion_id SERIAL PRIMARY KEY,
linea_id INT REFERENCES oltp_pedidos.lineas_pedido(linea_id),
cantidad INT,
fecha DATE
);

CREATE INDEX idx_pedido_cliente ON oltp_pedidos.pedidos(cliente_id);
CREATE INDEX idx_linea_producto ON oltp_pedidos.lineas_pedido(producto_id);

-- Envios
CREATE TABLE oltp_envios.transportistas (
transportista_id SERIAL PRIMARY KEY,
nombre VARCHAR(100),
zona VARCHAR(50)
);

CREATE TABLE oltp_envios.envios (
envio_id SERIAL PRIMARY KEY,
pedido_id INT REFERENCES oltp_pedidos.pedidos(pedido_id),
transportista_id INT REFERENCES oltp_envios.transportistas(transportista_id),
fecha_envio DATE,
fecha_entrega DATE,
coste NUMERIC(10,2)
);

CREATE TABLE oltp_envios.incidencias (
incidencia_id SERIAL PRIMARY KEY,
envio_id INT REFERENCES oltp_envios.envios(envio_id),
descripcion TEXT,
fecha DATE
);

CREATE TABLE oltp_envios.rutas (
ruta_id SERIAL PRIMARY KEY,
origen VARCHAR(100),
destino VARCHAR(100)
);

CREATE INDEX idx_envio_pedido ON oltp_envios.envios(pedido_id);

-- Pagos
CREATE TABLE oltp_pagos.metodos_pago (
metodo_id SERIAL PRIMARY KEY,
nombre VARCHAR(50)
);

CREATE TABLE oltp_pagos.facturas (
factura_id SERIAL PRIMARY KEY,
pedido_id INT REFERENCES oltp_pedidos.pedidos(pedido_id),
total NUMERIC(10,2),
fecha DATE
);

CREATE TABLE oltp_pagos.pagos (
pago_id SERIAL PRIMARY KEY,
factura_id INT REFERENCES oltp_pagos.facturas(factura_id),
metodo_id INT REFERENCES oltp_pagos.metodos_pago(metodo_id),
fecha DATE,
cantidad NUMERIC(10,2)
);

CREATE TABLE oltp_pagos.transacciones (
transaccion_id SERIAL PRIMARY KEY,
pago_id INT REFERENCES oltp_pagos.pagos(pago_id),
estado VARCHAR(50)
);

CREATE INDEX idx_pago_factura ON oltp_pagos.pagos(factura_id);

-- DATOS FINALES

-- =========================
-- CLIENTES (200)
-- =========================
INSERT INTO oltp_clientes.clientes (nombre, email, telefono, fecha_registro)
SELECT
    CASE
        WHEN i % 5 = 0 THEN 'Carlos'
        WHEN i % 5 = 1 THEN 'Lucia'
        WHEN i % 5 = 2 THEN 'Miguel'
        WHEN i % 5 = 3 THEN 'Sara'
        ELSE 'David'
    END || '_' || i,
    'cliente' || i || '@mail.com',
    '+34-6' || LPAD((60000000 + i)::text,8,'0'),
    DATE '2021-01-01' + ((random() * 1500)::INT)
FROM generate_series(1,200) i;

-- =========================
-- DIRECCIONES
-- =========================
INSERT INTO oltp_clientes.direcciones (cliente_id, direccion, ciudad, region, pais)
SELECT
    i,
    CASE
        WHEN i % 4 = 0 THEN 'Avenida'
        WHEN i % 4 = 1 THEN 'Calle'
        WHEN i % 4 = 2 THEN 'Plaza'
        ELSE 'Paseo'
    END || ' ' ||
    CASE
        WHEN i % 6 = 0 THEN 'del Sol'
        WHEN i % 6 = 1 THEN 'de la Paz'
        WHEN i % 6 = 2 THEN 'Real'
        WHEN i % 6 = 3 THEN 'Gran Via'
        WHEN i % 6 = 4 THEN 'de Andalucia'
        ELSE 'de Castilla'
    END || ' ' || i,

    CASE
        WHEN i % 10 = 0 THEN 'Madrid'
        WHEN i % 10 = 1 THEN 'Barcelona'
        WHEN i % 10 = 2 THEN 'Sevilla'
        WHEN i % 10 = 3 THEN 'Valencia'
        WHEN i % 10 = 4 THEN 'Bilbao'
        WHEN i % 10 = 5 THEN 'Malaga'
        WHEN i % 10 = 6 THEN 'Granada'
        WHEN i % 10 = 7 THEN 'Zaragoza'
        WHEN i % 10 = 8 THEN 'Murcia'
        ELSE 'A Coruña'
    END,

    CASE
        WHEN i % 5 = 0 THEN 'Andalucia'
        WHEN i % 5 = 1 THEN 'Cataluña'
        WHEN i % 5 = 2 THEN 'Madrid'
        WHEN i % 5 = 3 THEN 'Comunidad Valenciana'
        ELSE 'Pais Vasco'
    END,

    'España'
FROM generate_series(1,200) i;

-- =========================
-- SEGMENTOS
-- =========================
INSERT INTO oltp_clientes.segmentos (nombre)
VALUES
('Premium'),
('Estandar'),
('Ocasional'),
('Empresa'),
('VIP');

-- =========================
-- HISTORIAL CLIENTES
-- =========================
INSERT INTO oltp_clientes.historial_clientes (cliente_id, segmento_id, fecha_inicio)
SELECT
    i,
    (i % 5) + 1,
    DATE '2021-01-01' + ((random() * 1500)::INT)
FROM generate_series(1,200) i;

-- =========================
-- CATEGORIAS
-- =========================
INSERT INTO oltp_catalogo.categorias (nombre)
VALUES
('Electrónica'),
('Ropa'),
('Hogar'),
('Deporte'),
('Videojuegos'),
('Juguetes'),
('Libros'),
('Belleza'),
('Alimentación'),
('Automoción');

-- =========================
-- PROVEEDORES (40)
-- =========================
INSERT INTO oltp_catalogo.proveedores (nombre, contacto)
SELECT
    CASE
        WHEN i % 5 = 0 THEN 'TechSupplier'
        WHEN i % 5 = 1 THEN 'GlobalMarket'
        WHEN i % 5 = 2 THEN 'DistribucionesPlus'
        WHEN i % 5 = 3 THEN 'EuroTrade'
        ELSE 'MegaStore'
    END || '_' || i,

    'contacto' || i || '@proveedor.com'
FROM generate_series(1,40) i;

-- =========================
-- PRODUCTOS (300)
-- =========================
INSERT INTO oltp_catalogo.productos (nombre, categoria_id, proveedor_id, precio)
SELECT
    CASE
        WHEN i % 10 = 0 THEN 'Smartphone'
        WHEN i % 10 = 1 THEN 'Camiseta'
        WHEN i % 10 = 2 THEN 'Silla'
        WHEN i % 10 = 3 THEN 'Bicicleta'
        WHEN i % 10 = 4 THEN 'Consola'
        WHEN i % 10 = 5 THEN 'Libro'
        WHEN i % 10 = 6 THEN 'Perfume'
        WHEN i % 10 = 7 THEN 'Chocolate'
        WHEN i % 10 = 8 THEN 'Neumatico'
        ELSE 'Auriculares'
    END || '_' || i,

    (i % 10) + 1,
    (i % 40) + 1,

    CASE
        WHEN i % 10 = 0 THEN (random() * 900 + 100)::NUMERIC(10,2)
        WHEN i % 10 = 1 THEN (random() * 40 + 5)::NUMERIC(10,2)
        WHEN i % 10 = 2 THEN (random() * 300 + 50)::NUMERIC(10,2)
        WHEN i % 10 = 3 THEN (random() * 1000 + 150)::NUMERIC(10,2)
        WHEN i % 10 = 4 THEN (random() * 500 + 200)::NUMERIC(10,2)
        ELSE (random() * 150 + 10)::NUMERIC(10,2)
    END
FROM generate_series(1,300) i;

-- =========================
-- STOCK
-- =========================
INSERT INTO oltp_catalogo.stock (producto_id, cantidad)
SELECT
    i,
    (random() * 500)::INT
FROM generate_series(1,300) i;

-- =========================
-- ESTADOS PEDIDO
-- =========================
INSERT INTO oltp_pedidos.estados_pedido (nombre)
VALUES
('Pendiente'),
('Preparando'),
('Enviado'),
('Entregado'),
('Cancelado'),
('Devuelto');

-- =========================
-- PEDIDOS (500)
-- =========================
INSERT INTO oltp_pedidos.pedidos (cliente_id, fecha_pedido, estado_id)
SELECT
    (random() * 199 + 1)::INT,

    TIMESTAMP '2022-01-01 00:00:00'
    + ((random() * 1400)::INT || ' days')::INTERVAL
    + ((random() * 23)::INT || ' hours')::INTERVAL,

    (random() * 5 + 1)::INT
FROM generate_series(1,500);

-- =========================
-- LINEAS PEDIDO (1500)
-- =========================
INSERT INTO oltp_pedidos.lineas_pedido
(pedido_id, producto_id, cantidad, precio_unitario)
SELECT
    (random() * 499 + 1)::INT,
    (random() * 299 + 1)::INT,

    CASE
        WHEN random() < 0.7 THEN (random() * 3 + 1)::INT
        ELSE (random() * 10 + 1)::INT
    END,

    (random() * 1000 + 5)::NUMERIC(10,2)
FROM generate_series(1,1500);

-- =========================
-- DEVOLUCIONES (120)
-- =========================
INSERT INTO oltp_pedidos.devoluciones (linea_id, cantidad, fecha)
SELECT
    (random() * 1499 + 1)::INT,
    (random() * 3 + 1)::INT,

    DATE '2022-01-01' + ((random() * 1400)::INT)
FROM generate_series(1,120);

-- =========================
-- TRANSPORTISTAS
-- =========================
INSERT INTO oltp_envios.transportistas (nombre, zona)
VALUES
('Correos','España'),
('SEUR','Europa'),
('DHL','Internacional'),
('UPS','Internacional'),
('MRW','España'),
('FedEx','Global');

-- =========================
-- ENVIOS
-- =========================
INSERT INTO oltp_envios.envios
(pedido_id, transportista_id, fecha_envio, fecha_entrega, coste)
SELECT
    pedido_id,

    (random() * 5 + 1)::INT,

    fecha_pedido + ((random() * 3)::INT || ' days')::INTERVAL,

    fecha_pedido + ((random() * 10 + 2)::INT || ' days')::INTERVAL,

    CASE
        WHEN random() < 0.5 THEN (random() * 10 + 3)::NUMERIC(10,2)
        ELSE (random() * 50 + 10)::NUMERIC(10,2)
    END
FROM oltp_pedidos.pedidos;

-- =========================
-- INCIDENCIAS
-- =========================
INSERT INTO oltp_envios.incidencias (envio_id, descripcion, fecha)
SELECT
    (random() * 499 + 1)::INT,

    CASE
        WHEN i % 5 = 0 THEN 'Retraso en entrega'
        WHEN i % 5 = 1 THEN 'Paquete dañado'
        WHEN i % 5 = 2 THEN 'Direccion incorrecta'
        WHEN i % 5 = 3 THEN 'Cliente ausente'
        ELSE 'Problema logistico'
    END,

    DATE '2022-01-01' + ((random() * 1400)::INT)
FROM generate_series(1,150) i;

-- =========================
-- RUTAS
-- =========================
INSERT INTO oltp_envios.rutas (origen, destino)
VALUES
('Madrid','Barcelona'),
('Sevilla','Valencia'),
('Bilbao','Madrid'),
('Granada','Malaga'),
('Murcia','Zaragoza'),
('A Coruña','Bilbao'),
('Valencia','Barcelona');

-- =========================
-- METODOS PAGO
-- =========================
INSERT INTO oltp_pagos.metodos_pago (nombre)
VALUES
('Tarjeta'),
('PayPal'),
('Transferencia'),
('Bizum'),
('Apple Pay'),
('Google Pay');

-- =========================
-- FACTURAS
-- =========================
INSERT INTO oltp_pagos.facturas (pedido_id, total, fecha)
SELECT
    pedido_id,

    CASE
        WHEN random() < 0.6 THEN (random() * 150 + 20)::NUMERIC(10,2)
        WHEN random() < 0.9 THEN (random() * 600 + 150)::NUMERIC(10,2)
        ELSE (random() * 3000 + 1000)::NUMERIC(10,2)
    END,

    fecha_pedido
FROM oltp_pedidos.pedidos;

-- =========================
-- PAGOS
-- =========================
INSERT INTO oltp_pagos.pagos (factura_id, metodo_id, fecha, cantidad)
SELECT
    factura_id,
    (random() * 5 + 1)::INT,

    fecha + ((random() * 5)::INT || ' days')::INTERVAL,

    total
FROM oltp_pagos.facturas;

-- =========================
-- TRANSACCIONES
-- =========================
INSERT INTO oltp_pagos.transacciones (pago_id, estado)
SELECT
    pago_id,

    CASE
        WHEN random() > 0.92 THEN 'Fallido'
        WHEN random() > 0.85 THEN 'Pendiente'
        ELSE 'Completado'
    END
FROM oltp_pagos.pagos;

-- DATA WAREHOUSE

CREATE SCHEMA datawarehouse;

CREATE TABLE datawarehouse.dim_fecha (
    fecha_id SERIAL PRIMARY KEY,
    fecha DATE,
    dia INT,
    mes INT,
    anio INT
);

CREATE TABLE datawarehouse.dim_cliente (
    cliente_id INT PRIMARY KEY,
    nombre VARCHAR(100),
    ciudad VARCHAR(50),
    pais VARCHAR(50),
    email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE datawarehouse.dim_producto (
    producto_id INT PRIMARY KEY,
    nombre VARCHAR(100),
    categoria VARCHAR(100),
    proveedor VARCHAR(100),
    precio NUMERIC(10,2) CHECK (precio > 0)
);

CREATE TABLE datawarehouse.dim_estado_pedido (
    estado_id INT PRIMARY KEY,
    nombre VARCHAR(50)
);

CREATE TABLE datawarehouse.dim_transportista (
    transportista_id INT PRIMARY KEY,
    nombre VARCHAR(100),
    zona VARCHAR(50)
);

CREATE TABLE datawarehouse.hechos_ventas (
    hecho_id SERIAL PRIMARY KEY,
    
    cliente_id INT,
    producto_id INT,
    fecha_id INT,
    estado_id INT,
    transportista_id INT,
    
    cantidad INT,
    importe NUMERIC(10,2),

    FOREIGN KEY (cliente_id) REFERENCES datawarehouse.dim_cliente(cliente_id),
    FOREIGN KEY (producto_id) REFERENCES datawarehouse.dim_producto(producto_id),
    FOREIGN KEY (fecha_id) REFERENCES datawarehouse.dim_fecha(fecha_id),
    FOREIGN KEY (estado_id) REFERENCES datawarehouse.dim_estado_pedido(estado_id),
    FOREIGN KEY (transportista_id) REFERENCES datawarehouse.dim_transportista(transportista_id)
);

-- Insertar datos en dimensiones

INSERT INTO datawarehouse.dim_cliente
SELECT DISTINCT
    c.cliente_id,
    c.nombre,
    d.ciudad,
    d.pais,
    c.email
FROM oltp_clientes.clientes c
LEFT JOIN oltp_clientes.direcciones d
ON c.cliente_id = d.cliente_id;

INSERT INTO datawarehouse.dim_producto
SELECT
    p.producto_id,
    p.nombre,
    c.nombre,
    pr.nombre
FROM oltp_catalogo.productos p
JOIN oltp_catalogo.categorias c ON p.categoria_id = c.categoria_id
JOIN oltp_catalogo.proveedores pr ON p.proveedor_id = pr.proveedor_id;

INSERT INTO datawarehouse.dim_estado_pedido
SELECT * FROM oltp_pedidos.estados_pedido;

INSERT INTO datawarehouse.dim_transportista
SELECT * FROM oltp_envios.transportistas;

INSERT INTO datawarehouse.dim_fecha (fecha, dia, mes, anio)
SELECT DISTINCT
    fecha_pedido,
    EXTRACT(DAY FROM fecha_pedido),
    EXTRACT(MONTH FROM fecha_pedido),
    EXTRACT(YEAR FROM fecha_pedido)
FROM oltp_pedidos.pedidos;

INSERT INTO datawarehouse.hechos_ventas (
    cliente_id,
    producto_id,
    fecha_id,
    estado_id,
    transportista_id,
    cantidad,
    importe
)
SELECT
    p.cliente_id,
    lp.producto_id,
    f.fecha_id,
    p.estado_id,
    e.transportista_id,
    lp.cantidad,
    lp.cantidad * lp.precio_unitario
FROM oltp_pedidos.pedidos p
JOIN oltp_pedidos.lineas_pedido lp ON p.pedido_id = lp.pedido_id
JOIN datawarehouse.dim_fecha f ON f.fecha = p.fecha_pedido
LEFT JOIN oltp_envios.envios e ON p.pedido_id = e.pedido_id;

-- Consultas OLTP

-- 1. Evolución de ingresos por categoría a lo largo del tiempo (mes/año)
-- Pregunta analítica 1
SELECT 
    EXTRACT(YEAR FROM p.fecha_pedido) AS anio,
    EXTRACT(MONTH FROM p.fecha_pedido) AS mes,
    cat.nombre AS categoria,
    SUM(lp.cantidad * lp.precio_unitario) AS ingresos_totales
FROM oltp_pedidos.pedidos p
JOIN oltp_pedidos.lineas_pedido lp ON p.pedido_id = lp.pedido_id
JOIN oltp_catalogo.productos prod ON lp.producto_id = prod.producto_id
JOIN oltp_catalogo.categorias cat ON prod.categoria_id = cat.categoria_id
GROUP BY anio, mes, cat.nombre
ORDER BY anio, mes, cat.nombre;

-- 2. Top clientes por ingresos y su región (país/ciudad)
-- Pregunta analítica 2
SELECT 
    c.nombre,
    d.pais,
    d.ciudad,
    SUM(lp.cantidad * lp.precio_unitario) AS total_ingresos,
    COUNT(DISTINCT p.pedido_id) AS numero_pedidos
FROM oltp_clientes.clientes c
JOIN oltp_clientes.direcciones d ON c.cliente_id = d.cliente_id
JOIN oltp_pedidos.pedidos p ON c.cliente_id = p.cliente_id
JOIN oltp_pedidos.lineas_pedido lp ON p.pedido_id = lp.pedido_id
GROUP BY c.cliente_id, c.nombre, d.pais, d.ciudad
ORDER BY total_ingresos DESC
LIMIT 20;

-- 3. Relación transportista - valor medio de pedido
-- Pregunta analítica 3
SELECT 
    t.nombre AS transportista,
    AVG(lp.cantidad * lp.precio_unitario) AS valor_medio_pedido,
    SUM(lp.cantidad * lp.precio_unitario) AS ingresos_totales,
    COUNT(DISTINCT p.pedido_id) AS num_pedidos
FROM oltp_envios.envios e
JOIN oltp_envios.transportistas t ON e.transportista_id = t.transportista_id
JOIN oltp_pedidos.pedidos p ON e.pedido_id = p.pedido_id
JOIN oltp_pedidos.lineas_pedido lp ON p.pedido_id = lp.pedido_id
GROUP BY t.transportista_id, t.nombre
ORDER BY valor_medio_pedido DESC;

-- 4. Volumen de ventas (ingresos y cantidad) por estado del pedido
-- Pregunta analítica 4
SELECT 
    ep.nombre AS estado_pedido,
    SUM(lp.cantidad * lp.precio_unitario) AS ingresos_totales,
    SUM(lp.cantidad) AS unidades_vendidas,
    COUNT(lp.linea_id) AS numero_lineas_pedido
FROM oltp_pedidos.pedidos p
JOIN oltp_pedidos.estados_pedido ep ON p.estado_id = ep.estado_id
JOIN oltp_pedidos.lineas_pedido lp ON p.pedido_id = lp.pedido_id
GROUP BY ep.estado_id, ep.nombre
ORDER BY ingresos_totales DESC;

-- 5. Top productos más vendidos (ingresos y unidades) por categoría
-- Pregunta analítica 5
SELECT 
    cat.nombre AS categoria,
    prod.nombre AS producto,
    SUM(lp.cantidad * lp.precio_unitario) AS ingresos_totales,
    SUM(lp.cantidad) AS unidades_vendidas
FROM oltp_pedidos.lineas_pedido lp
JOIN oltp_catalogo.productos prod ON lp.producto_id = prod.producto_id
JOIN oltp_catalogo.categorias cat ON prod.categoria_id = cat.categoria_id
GROUP BY cat.nombre, prod.producto_id, prod.nombre
ORDER BY cat.nombre, ingresos_totales DESC;


-- Consultas OLAP

-- 1. Evolución de ingresos por categoría a lo largo del tiempo (mes/año)
-- Pregunta analítica 1

SELECT 
    df.anio,
    df.mes,
    dp.categoria,
    SUM(hv.importe) AS ingresos_totales
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_fecha df ON hv.fecha_id = df.fecha_id
JOIN datawarehouse.dim_producto dp ON hv.producto_id = dp.producto_id
GROUP BY df.anio, df.mes, dp.categoria
ORDER BY df.anio, df.mes, dp.categoria;


-- 2. Top clientes por ingresos y su región (país/ciudad)
-- Pregunta analítica 2
SELECT 
    dc.nombre,
    dc.pais,
    dc.ciudad,
    SUM(hv.importe) AS total_ingresos,
    COUNT(DISTINCT hv.hecho_id) AS numero_transacciones   -- opcional
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_cliente dc ON hv.cliente_id = dc.cliente_id
GROUP BY dc.cliente_id, dc.nombre, dc.pais, dc.ciudad
ORDER BY total_ingresos DESC
LIMIT 20;   -- Top 20 clientes


-- 3. Relación transportista - valor medio de pedido
-- Pregunta analítica 3

SELECT 
    dt.nombre AS transportista,
    AVG(hv.importe) AS valor_medio_pedido,
    SUM(hv.importe) AS ingresos_totales,
    COUNT(hv.hecho_id) AS num_pedidos
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_transportista dt ON hv.transportista_id = dt.transportista_id
GROUP BY dt.transportista_id, dt.nombre
ORDER BY valor_medio_pedido DESC;


-- 4. Volumen de ventas (ingresos y cantidad) por estado del pedido
-- Pregunta analítica 4

SELECT 
    de.nombre AS estado_pedido,
    SUM(hv.importe) AS ingresos_totales,
    SUM(hv.cantidad) AS unidades_vendidas,
    COUNT(hv.hecho_id) AS numero_lineas_pedido
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_estado_pedido de ON hv.estado_id = de.estado_id
GROUP BY de.estado_id, de.nombre
ORDER BY ingresos_totales DESC;


-- 5. Top productos más vendidos (ingresos y unidades) por categoría
-- Pregunta analítica 5

SELECT 
    dp.categoria,
    dp.nombre AS producto,
    SUM(hv.importe) AS ingresos_totales,
    SUM(hv.cantidad) AS unidades_vendidas
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_producto dp ON hv.producto_id = dp.producto_id
GROUP BY dp.categoria, dp.producto_id, dp.nombre
ORDER BY dp.categoria, ingresos_totales DESC;

