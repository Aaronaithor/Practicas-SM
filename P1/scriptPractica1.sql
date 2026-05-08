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

-- Datos de prueba

INSERT INTO oltp_clientes.clientes (nombre,email,telefono,fecha_registro) VALUES
('Juan Perez','[juan@test.com](mailto:juan@test.com)','+34-600000001','2023-01-01'),
('Maria Lopez','[maria@test.com](mailto:maria@test.com)','+34-600000002','2023-02-01');

INSERT INTO oltp_catalogo.categorias (nombre) VALUES ('Electrónica'),('Ropa');

INSERT INTO oltp_catalogo.proveedores (nombre,contacto) VALUES
('Proveedor1','[prov1@test.com](mailto:prov1@test.com)'),
('Proveedor2','[prov2@test.com](mailto:prov2@test.com)');

INSERT INTO oltp_catalogo.productos (nombre,categoria_id,proveedor_id,precio) VALUES
('Laptop',1,1,1000),
('Camiseta',2,2,20);

INSERT INTO oltp_pedidos.estados_pedido (nombre) VALUES ('Pendiente'),('Enviado');

INSERT INTO oltp_pedidos.pedidos (cliente_id,fecha_pedido,estado_id) VALUES
(1,'2024-01-01',1);

INSERT INTO oltp_pedidos.lineas_pedido (pedido_id,producto_id,cantidad,precio_unitario) VALUES
(1,1,1,1000);

INSERT INTO oltp_envios.transportistas (nombre,zona) VALUES
('Correos','España');

INSERT INTO oltp_envios.envios (pedido_id,transportista_id,fecha_envio,coste) VALUES
(1,1,'2024-01-02',10);

INSERT INTO oltp_pagos.metodos_pago (nombre) VALUES ('Tarjeta');

INSERT INTO oltp_pagos.facturas (pedido_id,total,fecha) VALUES
(1,1010,'2024-01-01');

INSERT INTO oltp_pagos.pagos (factura_id,metodo_id,fecha,cantidad) VALUES
(1,1,'2024-01-01',1010);

-- DATOS FINALES

-- CLIENTES (100)
INSERT INTO oltp_clientes.clientes (nombre, email, telefono, fecha_registro)
SELECT
'Cliente_' || i,
'cliente' || i || '@mail.com',
'+34-600' || LPAD(i::text,6,'0'),
DATE '2023-01-01' + (i % 365)
FROM generate_series(1,100) i;

-- DIRECCIONES (100)
INSERT INTO oltp_clientes.direcciones (cliente_id, direccion, ciudad, region, pais)
SELECT
i,
'Calle Falsa ' || i,
CASE WHEN i % 5 = 0 THEN 'Madrid'
WHEN i % 5 = 1 THEN 'Barcelona'
WHEN i % 5 = 2 THEN 'Sevilla'
WHEN i % 5 = 3 THEN 'Valencia'
ELSE 'Bilbao' END,
'España',
'España'
FROM generate_series(1,100) i;

-- SEGMENTOS
INSERT INTO oltp_clientes.segmentos (nombre)
VALUES ('Premium'), ('Estandar'), ('Ocasional');

-- HISTORIAL CLIENTES
INSERT INTO oltp_clientes.historial_clientes (cliente_id, segmento_id, fecha_inicio)
SELECT
i,
(i % 3) + 1,
DATE '2023-01-01' + (i % 365)
FROM generate_series(1,100) i;

-- CATEGORIAS
INSERT INTO oltp_catalogo.categorias (nombre)
VALUES ('Electrónica'), ('Ropa'), ('Hogar'), ('Deporte');

-- PROVEEDORES (20)
INSERT INTO oltp_catalogo.proveedores (nombre, contacto)
SELECT
'Proveedor_' || i,
'proveedor' || i || '@mail.com'
FROM generate_series(1,20) i;

-- PRODUCTOS (100)
INSERT INTO oltp_catalogo.productos (nombre, categoria_id, proveedor_id, precio)
SELECT
'Producto_' || i,
(i % 4) + 1,
(i % 20) + 1,
(random() * 100 + 5)::NUMERIC(10,2)
FROM generate_series(1,100) i;

-- STOCK (100)
INSERT INTO oltp_catalogo.stock (producto_id, cantidad)
SELECT
i,
(random() * 100)::INT
FROM generate_series(1,100) i;

-- ESTADOS PEDIDO
INSERT INTO oltp_pedidos.estados_pedido (nombre)
VALUES ('Pendiente'), ('Enviado'), ('Entregado'), ('Cancelado');

-- PEDIDOS (100)
INSERT INTO oltp_pedidos.pedidos (cliente_id, fecha_pedido, estado_id)
SELECT
(random() * 99 + 1)::INT,
DATE '2024-01-01' + (i % 365),
(random() * 3 + 1)::INT
FROM generate_series(1,100) i;

-- LINEAS PEDIDO (300)
INSERT INTO oltp_pedidos.lineas_pedido (pedido_id, producto_id, cantidad, precio_unitario)
SELECT
(random() * 99 + 1)::INT,
(random() * 99 + 1)::INT,
(random() * 5 + 1)::INT,
(random() * 100 + 5)::NUMERIC(10,2)
FROM generate_series(1,300);

-- DEVOLUCIONES (50)
INSERT INTO oltp_pedidos.devoluciones (linea_id, cantidad, fecha)
SELECT
(random() * 299 + 1)::INT,
1,
DATE '2024-06-01' + (i % 30)
FROM generate_series(1,50) i;

-- TRANSPORTISTAS
INSERT INTO oltp_envios.transportistas (nombre, zona)
VALUES
('Correos','España'),
('SEUR','Europa'),
('DHL','Internacional');

-- ENVIOS (100)
INSERT INTO oltp_envios.envios (pedido_id, transportista_id, fecha_envio, fecha_entrega, coste)
SELECT
pedido_id,
(random() * 2 + 1)::INT,
fecha_pedido + 1,
fecha_pedido + ((random() * 5)::INT + 2),
(random() * 20 + 5)::NUMERIC(10,2)
FROM oltp_pedidos.pedidos;

-- INCIDENCIAS (30)
INSERT INTO oltp_envios.incidencias (envio_id, descripcion, fecha)
SELECT
(random() * 99 + 1)::INT,
'Retraso en entrega',
DATE '2024-06-01' + (i % 30)
FROM generate_series(1,30) i;

-- RUTAS
INSERT INTO oltp_envios.rutas (origen, destino)
VALUES
('Madrid','Barcelona'),
('Sevilla','Valencia'),
('Bilbao','Madrid');

-- METODOS PAGO
INSERT INTO oltp_pagos.metodos_pago (nombre)
VALUES ('Tarjeta'), ('PayPal'), ('Transferencia');

-- FACTURAS (100)
INSERT INTO oltp_pagos.facturas (pedido_id, total, fecha)
SELECT
pedido_id,
(random() * 200 + 20)::NUMERIC(10,2),
fecha_pedido
FROM oltp_pedidos.pedidos;

-- PAGOS (100)
INSERT INTO oltp_pagos.pagos (factura_id, metodo_id, fecha, cantidad)
SELECT
factura_id,
(random() * 2 + 1)::INT,
fecha,
total
FROM oltp_pagos.facturas;

-- TRANSACCIONES (100)
INSERT INTO oltp_pagos.transacciones (pago_id, estado)
SELECT
pago_id,
CASE WHEN random() > 0.1 THEN 'Completado' ELSE 'Fallido' END
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
    pais VARCHAR(50)
);

CREATE TABLE datawarehouse.dim_producto (
    producto_id INT PRIMARY KEY,
    nombre VARCHAR(100),
    categoria VARCHAR(100),
    proveedor VARCHAR(100)
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
    d.pais
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

-- Ventas totales por cliente
SELECT 
    c.nombre,
    SUM(lp.cantidad * lp.precio_unitario) AS total_ventas
FROM oltp_clientes.clientes c
JOIN oltp_pedidos.pedidos p ON c.cliente_id = p.cliente_id
JOIN oltp_pedidos.lineas_pedido lp ON p.pedido_id = lp.pedido_id
GROUP BY c.nombre
ORDER BY total_ventas DESC;

-- Ventas por categoría
SELECT 
    cat.nombre,
    SUM(lp.cantidad * lp.precio_unitario) AS total
FROM oltp_pedidos.lineas_pedido lp
JOIN oltp_catalogo.productos p ON lp.producto_id = p.producto_id
JOIN oltp_catalogo.categorias cat ON p.categoria_id = cat.categoria_id
GROUP BY cat.nombre;

-- Ventas por mes
SELECT 
    DATE_TRUNC('month', p.fecha_pedido) AS mes,
    SUM(lp.cantidad * lp.precio_unitario) AS total
FROM oltp_pedidos.pedidos p
JOIN oltp_pedidos.lineas_pedido lp ON p.pedido_id = lp.pedido_id
GROUP BY mes
ORDER BY mes;

-- Consultas OLAP
-- Ventas por cliente
SELECT 
    dc.nombre,
    SUM(hv.importe) AS total
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_cliente dc ON hv.cliente_id = dc.cliente_id
GROUP BY dc.nombre
ORDER BY total DESC;

-- Ventas por categoría
SELECT 
    dp.categoria,
    SUM(hv.importe) AS total
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_producto dp ON hv.producto_id = dp.producto_id
GROUP BY dp.categoria;

-- Ventas por mes
SELECT 
    df.mes,
    df.anio,
    SUM(hv.importe) AS total
FROM datawarehouse.hechos_ventas hv
JOIN datawarehouse.dim_fecha df ON hv.fecha_id = df.fecha_id
GROUP BY df.mes, df.anio
ORDER BY df.anio, df.mes;

