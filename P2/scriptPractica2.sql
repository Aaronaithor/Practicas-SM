-- Los primero de todo será introducir datos erróneos en clientes, productos, pedidos y lineas pedidos
-- para luego ejecutar las transformaciones y comprobar que se han limpiado correctamente 

-- Clientes
INSERT INTO oltp_clientes.clientes
(cliente_id, nombre, email, telefono, fecha_registro)
VALUES
(9001, 'JUAN PEREZ', 'JUAN@MAIL.COM   ', '600111111', CURRENT_DATE), -- Email y nombre con mayúsculas
(9002, 'maria lopez', 'EMAIL_INVALIDO', '600222222', CURRENT_DATE), -- Email no válido
(9003, '  carlos   garcia ', '   CaRlOs@GMAIL.COM', '600333333', CURRENT_DATE); -- Nombre con espacios y email con mayúsculas

-- Productos
INSERT INTO oltp_catalogo.productos
(producto_id, nombre, categoria_id, proveedor_id, precio)
VALUES
(1001, 'Producto Roto', 1, 1, NULL); -- Precio nulo

-- Pedidos
INSERT INTO oltp_pedidos.pedidos
(pedido_id, cliente_id, fecha_pedido, estado_id)
VALUES
(7003, NULL, CURRENT_DATE, 1); -- Cliente nulo


-- Ahora creamos el esquema y las tablas para la transformación de pedidos
CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.pedidos_clean (
    hecho_id SERIAL PRIMARY KEY,
    pedido_id INT,
    cliente_id INT,
    producto_id INT,
    transportista_id INT,
    estado_id INT,
    fecha_id INT,
    cantidad INT,
    precio NUMERIC(10,2),
    importe NUMERIC(10,2)
);

CREATE TABLE staging.clientes_clean (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100),
    ciudad VARCHAR(50),
    pais VARCHAR(50)
);

CREATE TABLE staging.productos_clean (
    producto_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    categoria VARCHAR(100),
    proveedor VARCHAR(100),
    precio NUMERIC(10,2)
);

CREATE TABLE staging.fechas_clean (
    fecha_id SERIAL PRIMARY KEY,
    fecha DATE,
    dia INT,
    mes INT,
    anio INT
);
