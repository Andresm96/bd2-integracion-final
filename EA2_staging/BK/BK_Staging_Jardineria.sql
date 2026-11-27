/* =====================================================================
   BK_Staging_Jardineria.sql
   Copia de seguridad en formato script (estructura + datos) de la base
   Staging_Jardineria, equivalente a "Generar scripts > Esquema y datos"
   de SQL Server Management Studio. Ejecutarlo en una instancia vacía
   reconstruye la base con las mismas filas.
   La copia binaria (.bak) se genera con 04_Backup_Jardineria_y_Staging.sql.
   ===================================================================== */
USE master;
GO

IF DB_ID('Staging_Jardineria') IS NOT NULL
BEGIN
    ALTER DATABASE Staging_Jardineria SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Staging_Jardineria;
END
GO

CREATE DATABASE Staging_Jardineria;
GO

USE Staging_Jardineria;
GO

-- Sedes de la empresa (origen: jardineria.dbo.oficina) -> Dim_Oficina
CREATE TABLE dbo.stg_oficina (
    ID_oficina     INT          NOT NULL,
    Descripcion    VARCHAR(10)  NOT NULL,   -- código de la sede, p. ej. BCN-ES
    Ciudad         VARCHAR(30)  NOT NULL,
    Pais           VARCHAR(50)  NOT NULL,   -- nombre de país normalizado
    Region         VARCHAR(50)  NULL,
    Codigo_Postal  VARCHAR(10)  NOT NULL,
    Fecha_Carga    DATETIME     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_stg_oficina PRIMARY KEY (ID_oficina)
);
GO

-- Empleados (origen: jardineria.dbo.empleado) -> Dim_Empleado
CREATE TABLE dbo.stg_empleado (
    ID_empleado    INT          NOT NULL,
    Nombre         VARCHAR(50)  NOT NULL,
    Apellido1      VARCHAR(50)  NOT NULL,
    Apellido2      VARCHAR(50)  NULL,       -- '' en el origen se guarda como NULL
    Email          VARCHAR(100) NOT NULL,
    Puesto         VARCHAR(50)  NULL,
    ID_oficina     INT          NOT NULL,
    Fecha_Carga    DATETIME     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_stg_empleado PRIMARY KEY (ID_empleado)
);
GO

-- Categorías de producto (origen: jardineria.dbo.Categoria_producto) -> Dim_Producto
CREATE TABLE dbo.stg_categoria_producto (
    ID_categoria   INT          NOT NULL,
    Desc_Categoria VARCHAR(50)  NOT NULL,
    Fecha_Carga    DATETIME     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_stg_categoria_producto PRIMARY KEY (ID_categoria)
);
GO

-- Clientes (origen: jardineria.dbo.cliente) -> Dim_Cliente
CREATE TABLE dbo.stg_cliente (
    ID_cliente             INT           NOT NULL,
    Nombre_Cliente         VARCHAR(50)   NOT NULL,
    Ciudad                 VARCHAR(50)   NOT NULL,
    Region                 VARCHAR(50)   NULL,
    Pais                   VARCHAR(50)   NULL,      -- nombre de país normalizado
    Limite_Credito         NUMERIC(15,2) NULL,
    ID_empleado_rep_ventas INT           NULL,      -- ruta hacia Dim_Empleado y Dim_Oficina
    Fecha_Carga            DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_stg_cliente PRIMARY KEY (ID_cliente)
);
GO

-- Cabecera de pedidos (origen: jardineria.dbo.pedido) -> Dim_Pedido y Dim_Tiempo
CREATE TABLE dbo.stg_pedido (
    ID_pedido      INT          NOT NULL,
    Fecha_Pedido   DATE         NOT NULL,
    Fecha_Esperada DATE         NOT NULL,
    Fecha_Entrega  DATE         NULL,
    Estado         VARCHAR(15)  NOT NULL,
    ID_cliente     INT          NOT NULL,
    Observacion    VARCHAR(60)  NULL,       -- inconsistencia de fechas detectada en la carga
    Fecha_Carga    DATETIME     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_stg_pedido PRIMARY KEY (ID_pedido)
);
GO

-- Productos (origen: jardineria.dbo.producto) -> Dim_Producto
CREATE TABLE dbo.stg_producto (
    ID_producto      VARCHAR(15)   NOT NULL,
    Nombre           VARCHAR(70)   NOT NULL,
    ID_categoria     INT           NOT NULL,
    Dimensiones      VARCHAR(25)   NULL,    -- '' en el origen se guarda como NULL
    Proveedor        VARCHAR(50)   NULL,
    Precio_Venta     NUMERIC(15,2) NOT NULL,
    Precio_Proveedor NUMERIC(15,2) NULL,
    Fecha_Carga      DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_stg_producto PRIMARY KEY (ID_producto)
);
GO

-- Líneas de pedido (origen: jardineria.dbo.detalle_pedido) -> Hechos_Ventas
CREATE TABLE dbo.stg_detalle_pedido (
    ID_pedido      INT           NOT NULL,
    ID_producto    VARCHAR(15)   NOT NULL,
    Numero_Linea   SMALLINT      NOT NULL,
    Cantidad       INT           NOT NULL,
    Precio_Unidad  NUMERIC(15,2) NOT NULL,  -- precio histórico de la venta
    Fecha_Carga    DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_stg_detalle_pedido PRIMARY KEY (ID_pedido, ID_producto)
);
GO

-- Bitácora de cada carga: filas en origen contra filas en Staging
CREATE TABLE dbo.stg_control_carga (
    ID_control     INT IDENTITY(1,1) NOT NULL,
    Tabla_Origen   VARCHAR(30)  NOT NULL,
    Tabla_Staging  VARCHAR(30)  NOT NULL,
    Filas_Origen   INT          NOT NULL,
    Filas_Staging  INT          NOT NULL,
    Resultado      VARCHAR(10)  NOT NULL,   -- OK o REVISAR
    Fecha_Carga    DATETIME     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_stg_control_carga PRIMARY KEY (ID_control)
);
GO

-- stg_oficina: 9 filas
INSERT INTO dbo.stg_oficina (ID_oficina, Descripcion, Ciudad, Pais, Region, Codigo_Postal) VALUES (1, 'BCN-ES', 'Barcelona', 'España', 'Barcelona', '08019');
INSERT INTO dbo.stg_oficina (ID_oficina, Descripcion, Ciudad, Pais, Region, Codigo_Postal) VALUES (2, 'BOS-USA', 'Boston', 'Estados Unidos', 'MA', '02108');
INSERT INTO dbo.stg_oficina (ID_oficina, Descripcion, Ciudad, Pais, Region, Codigo_Postal) VALUES (3, 'LON-UK', 'Londres', 'Reino Unido', 'EMEA', 'EC2N 1H');
INSERT INTO dbo.stg_oficina (ID_oficina, Descripcion, Ciudad, Pais, Region, Codigo_Postal) VALUES (4, 'MAD-ES', 'Madrid', 'España', 'Madrid', '28032');
INSERT INTO dbo.stg_oficina (ID_oficina, Descripcion, Ciudad, Pais, Region, Codigo_Postal) VALUES (5, 'PAR-FR', 'Paris', 'Francia', 'EMEA', '75017');
INSERT INTO dbo.stg_oficina (ID_oficina, Descripcion, Ciudad, Pais, Region, Codigo_Postal) VALUES (6, 'SFC-USA', 'San Francisco', 'Estados Unidos', 'CA', '94080');
INSERT INTO dbo.stg_oficina (ID_oficina, Descripcion, Ciudad, Pais, Region, Codigo_Postal) VALUES (7, 'SYD-AU', 'Sydney', 'Australia', 'APAC', 'NSW 2010');
INSERT INTO dbo.stg_oficina (ID_oficina, Descripcion, Ciudad, Pais, Region, Codigo_Postal) VALUES (8, 'TAL-ES', 'Talavera de la Reina', 'España', 'Castilla-LaMancha', '45632');
INSERT INTO dbo.stg_oficina (ID_oficina, Descripcion, Ciudad, Pais, Region, Codigo_Postal) VALUES (9, 'TOK-JP', 'Tokyo', 'Japón', 'Chiyoda-Ku', '102-8578');
GO

-- stg_empleado: 31 filas
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (1, 'Marcos', 'Magaña', 'Perez', 'marcos@jardineria.es', 'Director General', 8);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (2, 'Ruben', 'López', 'Martinez', 'rlopez@jardineria.es', 'Subdirector Marketing', 8);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (3, 'Alberto', 'Soria', 'Carrasco', 'asoria@jardineria.es', 'Subdirector Ventas', 8);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (4, 'Maria', 'Solís', 'Jerez', 'msolis@jardineria.es', 'Secretaria', 8);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (5, 'Felipe', 'Rosas', 'Marquez', 'frosas@jardineria.es', 'Representante Ventas', 8);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (6, 'Juan Carlos', 'Ortiz', 'Serrano', 'cortiz@jardineria.es', 'Representante Ventas', 8);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (7, 'Carlos', 'Soria', 'Jimenez', 'csoria@jardineria.es', 'Director Oficina', 4);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (8, 'Mariano', 'López', 'Murcia', 'mlopez@jardineria.es', 'Representante Ventas', 4);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (9, 'Lucio', 'Campoamor', 'Martín', 'lcampoamor@jardineria.es', 'Representante Ventas', 4);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (10, 'Hilario', 'Rodriguez', 'Huertas', 'hrodriguez@jardineria.es', 'Representante Ventas', 4);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (11, 'Emmanuel', 'Magaña', 'Perez', 'manu@jardineria.es', 'Director Oficina', 1);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (12, 'José Manuel', 'Martinez', 'De la Osa', 'jmmart@hotmail.es', 'Representante Ventas', 1);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (13, 'David', 'Palma', 'Aceituno', 'dpalma@jardineria.es', 'Representante Ventas', 1);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (14, 'Oscar', 'Palma', 'Aceituno', 'opalma@jardineria.es', 'Representante Ventas', 1);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (15, 'Francois', 'Fignon', NULL, 'ffignon@gardening.com', 'Director Oficina', 5);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (16, 'Lionel', 'Narvaez', NULL, 'lnarvaez@gardening.com', 'Representante Ventas', 5);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (17, 'Laurent', 'Serra', NULL, 'lserra@gardening.com', 'Representante Ventas', 5);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (18, 'Michael', 'Bolton', NULL, 'mbolton@gardening.com', 'Director Oficina', 6);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (19, 'Walter Santiago', 'Sanchez', 'Lopez', 'wssanchez@gardening.com', 'Representante Ventas', 6);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (20, 'Hilary', 'Washington', NULL, 'hwashington@gardening.com', 'Director Oficina', 2);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (21, 'Marcus', 'Paxton', NULL, 'mpaxton@gardening.com', 'Representante Ventas', 2);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (22, 'Lorena', 'Paxton', NULL, 'lpaxton@gardening.com', 'Representante Ventas', 2);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (23, 'Nei', 'Nishikori', NULL, 'nnishikori@gardening.com', 'Director Oficina', 9);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (24, 'Narumi', 'Riko', NULL, 'nriko@gardening.com', 'Representante Ventas', 9);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (25, 'Takuma', 'Nomura', NULL, 'tnomura@gardening.com', 'Representante Ventas', 9);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (26, 'Amy', 'Johnson', NULL, 'ajohnson@gardening.com', 'Director Oficina', 3);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (27, 'Larry', 'Westfalls', NULL, 'lwestfalls@gardening.com', 'Representante Ventas', 3);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (28, 'John', 'Walton', NULL, 'jwalton@gardening.com', 'Representante Ventas', 3);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (29, 'Kevin', 'Fallmer', NULL, 'kfalmer@gardening.com', 'Director Oficina', 7);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (30, 'Julian', 'Bellinelli', NULL, 'jbellinelli@gardening.com', 'Representante Ventas', 7);
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina) VALUES (31, 'Mariko', 'Kishi', NULL, 'mkishi@gardening.com', 'Representante Ventas', 7);
GO

-- stg_categoria_producto: 5 filas
INSERT INTO dbo.stg_categoria_producto (ID_categoria, Desc_Categoria) VALUES (1, 'Herbaceas');
INSERT INTO dbo.stg_categoria_producto (ID_categoria, Desc_Categoria) VALUES (2, 'Herramientas');
INSERT INTO dbo.stg_categoria_producto (ID_categoria, Desc_Categoria) VALUES (3, 'Aromáticas');
INSERT INTO dbo.stg_categoria_producto (ID_categoria, Desc_Categoria) VALUES (4, 'Frutales');
INSERT INTO dbo.stg_categoria_producto (ID_categoria, Desc_Categoria) VALUES (5, 'Ornamentales');
GO

-- stg_cliente: 36 filas
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (1, 'GoldFish Garden', 'San Francisco', NULL, 'Estados Unidos', 3000.00, 19);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (3, 'Gardening Associates', 'Miami', 'Miami', 'Estados Unidos', 6000.00, 19);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (4, 'Gerudo Valley', 'New York', NULL, 'Estados Unidos', 12000.00, 22);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (5, 'Tendo Garden', 'Miami', NULL, 'Estados Unidos', 600000.00, 22);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (6, 'Lasas S.A.', 'Fuenlabrada', 'Madrid', 'España', 154310.00, 8);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (7, 'Beragua', 'Madrid', 'Madrid', 'España', 20000.00, 11);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (8, 'Club Golf Puerta del hierro', 'Madrid', 'Madrid', 'España', 40000.00, 11);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (9, 'Naturagua', 'Madrid', 'Madrid', 'España', 32000.00, 11);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (10, 'DaraDistribuciones', 'Madrid', 'Madrid', 'España', 50000.00, 11);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (11, 'Madrileña de riegos', 'Madrid', 'Madrid', 'España', 20000.00, 11);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (12, 'Lasas S.A.', 'Fuenlabrada', 'Madrid', 'España', 154310.00, 8);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (13, 'Camunas Jardines S.L.', 'San Lorenzo del Escorial', 'Madrid', 'España', 16481.00, 8);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (14, 'Dardena S.A.', 'Madrid', 'Madrid', 'España', 321000.00, 8);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (15, 'Jardin de Flores', 'Madrid', 'Madrid', 'España', 40000.00, 30);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (16, 'Flores Marivi', 'Fuenlabrada', 'Madrid', 'España', 1500.00, 5);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (17, 'Flowers, S.A', 'Montornes del valles', 'Barcelona', 'España', 3500.00, 5);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (18, 'Naturajardin', 'Madrid', 'Madrid', 'España', 5050.00, 30);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (19, 'Golf S.A.', 'Santa cruz de Tenerife', 'Islas Canarias', 'España', 30000.00, 12);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (20, 'Americh Golf Management SL', 'Barcelona', 'Cataluña', 'España', 20000.00, 12);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (21, 'Aloha', 'Canarias', 'Canarias', 'España', 50000.00, 12);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (22, 'El Prat', 'Barcelona', 'Cataluña', 'España', 30000.00, 12);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (23, 'Sotogrande', 'Sotogrande', 'Cadiz', 'España', 60000.00, 12);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (24, 'Vivero Humanes', 'Humanes', 'Madrid', 'España', 7430.00, 30);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (25, 'Fuenla City', 'Fuenlabrada', 'Madrid', 'España', 4500.00, 5);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (26, 'Jardines y Mansiones Cactus SL', 'Madrid', 'Madrid', 'España', 76000.00, 9);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (27, 'Jardinerías Matías SL', 'Madrid', 'Madrid', 'España', 100500.00, 9);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (28, 'Agrojardin', 'Getafe', 'Madrid', 'España', 8040.00, 30);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (29, 'Top Campo', 'Humanes', 'Madrid', 'España', 5500.00, 5);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (30, 'Jardineria Sara', 'Fuenlabrada', 'Madrid', 'España', 7500.00, 5);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (31, 'Campohermoso', 'Fuenlabrada', 'Madrid', 'España', 3250.00, 30);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (32, 'france telecom', 'Paris', NULL, 'Francia', 10000.00, 16);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (33, 'Musée du Louvre', 'Paris', NULL, 'Francia', 30000.00, 16);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (35, 'Tutifruti S.A', 'Sydney', 'Nueva Gales del Sur', 'Australia', 10000.00, 31);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (36, 'Flores S.L.', 'Madrid', 'Fuenlabrada', 'España', 6000.00, 18);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (37, 'The Magic Garden', 'London', 'London', 'Reino Unido', 10000.00, 18);
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito, ID_empleado_rep_ventas) VALUES (38, 'El Jardin Viviente S.L', 'Sydney', 'Nueva Gales del Sur', 'Australia', 8000.00, 31);
GO

-- stg_pedido: 115 filas
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (1, '2006-01-17', '2006-01-19', '2006-01-19', 'Entregado', 5, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (2, '2007-10-23', '2007-10-28', '2007-10-26', 'Entregado', 5, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (3, '2008-06-20', '2008-06-25', NULL, 'Rechazado', 5, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (4, '2009-01-20', '2009-01-26', NULL, 'Pendiente', 5, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (8, '2008-11-09', '2008-11-14', '2008-11-14', 'Entregado', 1, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (9, '2008-12-22', '2008-12-27', '2008-12-28', 'Entregado', 1, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (10, '2009-01-15', '2009-01-20', NULL, 'Pendiente', 3, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (11, '2009-01-20', '2009-01-27', NULL, 'Pendiente', 1, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (12, '2009-01-22', '2009-01-27', NULL, 'Pendiente', 1, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (13, '2009-01-12', '2009-01-14', '2009-01-15', 'Entregado', 7, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (14, '2009-01-02', '2009-01-02', NULL, 'Rechazado', 7, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (15, '2009-01-09', '2009-01-12', '2009-01-11', 'Entregado', 7, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (16, '2009-01-06', '2009-01-07', '2009-01-15', 'Entregado', 7, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (17, '2009-01-08', '2009-01-09', '2009-01-11', 'Entregado', 7, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (18, '2009-01-05', '2009-01-06', '2009-01-07', 'Entregado', 9, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (19, '2009-01-18', '2009-02-12', NULL, 'Pendiente', 9, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (20, '2009-01-20', '2009-02-15', NULL, 'Pendiente', 9, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (21, '2009-01-09', '2009-01-09', '2009-01-09', 'Rechazado', 9, 'Tiene fecha de entrega y estado Rechazado');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (22, '2009-01-11', '2009-01-11', '2009-01-13', 'Entregado', 9, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (23, '2008-12-30', '2009-01-10', NULL, 'Rechazado', 5, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (24, '2008-07-14', '2008-07-31', '2008-07-25', 'Entregado', 14, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (25, '2009-02-02', '2009-02-08', NULL, 'Rechazado', 1, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (26, '2009-02-06', '2009-02-12', NULL, 'Rechazado', 3, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (27, '2009-02-07', '2009-02-13', NULL, 'Entregado', 3, 'Entregado sin fecha de entrega');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (28, '2009-02-10', '2009-02-17', '2009-02-20', 'Entregado', 3, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (29, '2008-08-01', '2008-09-01', '2008-09-01', 'Rechazado', 14, 'Tiene fecha de entrega y estado Rechazado');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (30, '2008-08-03', '2008-09-03', '2008-08-31', 'Entregado', 13, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (31, '2008-09-04', '2008-09-30', '2008-10-04', 'Rechazado', 13, 'Tiene fecha de entrega y estado Rechazado');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (32, '2007-01-07', '2007-01-19', '2007-01-27', 'Entregado', 4, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (33, '2007-05-20', '2007-05-28', NULL, 'Rechazado', 4, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (34, '2007-06-20', '2008-06-28', '2008-06-28', 'Entregado', 4, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (35, '2008-03-10', '2009-03-20', NULL, 'Rechazado', 4, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (36, '2008-10-15', '2008-12-15', '2008-12-10', 'Entregado', 14, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (37, '2008-11-03', '2009-11-13', NULL, 'Pendiente', 4, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (38, '2009-03-05', '2009-03-06', '2009-03-07', 'Entregado', 19, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (39, '2009-03-06', '2009-03-07', '2009-03-09', 'Pendiente', 19, 'Tiene fecha de entrega y estado Pendiente');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (40, '2009-03-09', '2009-03-10', '2009-03-13', 'Rechazado', 19, 'Tiene fecha de entrega y estado Rechazado');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (41, '2009-03-12', '2009-03-13', '2009-03-13', 'Entregado', 19, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (42, '2009-03-22', '2009-03-23', '2009-03-27', 'Entregado', 19, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (43, '2009-03-25', '2009-03-26', '2009-03-28', 'Pendiente', 23, 'Tiene fecha de entrega y estado Pendiente');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (44, '2009-03-26', '2009-03-27', '2009-03-30', 'Pendiente', 23, 'Tiene fecha de entrega y estado Pendiente');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (45, '2009-04-01', '2009-03-04', '2009-03-07', 'Entregado', 23, 'Fecha de entrega anterior al pedido');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (46, '2009-04-03', '2009-03-04', '2009-03-05', 'Rechazado', 23, 'Fecha de entrega anterior al pedido');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (47, '2009-04-15', '2009-03-17', '2009-03-17', 'Entregado', 23, 'Fecha de entrega anterior al pedido');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (48, '2008-03-17', '2008-03-30', '2008-03-29', 'Entregado', 26, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (49, '2008-07-12', '2008-07-22', '2008-07-30', 'Entregado', 26, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (50, '2008-03-17', '2008-08-09', NULL, 'Pendiente', 26, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (51, '2008-10-01', '2008-10-14', '2008-10-14', 'Entregado', 26, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (52, '2008-12-07', '2008-12-21', NULL, 'Pendiente', 26, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (53, '2008-10-15', '2008-11-15', '2008-11-09', 'Entregado', 13, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (54, '2009-01-11', '2009-02-11', NULL, 'Pendiente', 14, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (55, '2008-12-10', '2009-01-10', '2009-01-11', 'Entregado', 14, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (56, '2008-12-19', '2009-01-20', NULL, 'Rechazado', 13, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (57, '2009-01-05', '2009-02-05', NULL, 'Pendiente', 13, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (58, '2009-01-24', '2009-01-31', '2009-01-30', 'Entregado', 3, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (59, '2008-11-09', '2008-11-14', '2008-11-14', 'Entregado', 1, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (60, '2008-12-22', '2008-12-27', '2008-12-28', 'Entregado', 1, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (61, '2009-01-15', '2009-01-20', NULL, 'Pendiente', 3, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (62, '2009-01-20', '2009-01-27', NULL, 'Pendiente', 1, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (63, '2009-01-22', '2009-01-27', NULL, 'Pendiente', 1, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (64, '2009-01-24', '2009-01-31', '2009-01-30', 'Entregado', 1, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (65, '2009-02-02', '2009-02-08', NULL, 'Rechazado', 1, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (66, '2009-02-06', '2009-02-12', NULL, 'Rechazado', 3, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (67, '2009-02-07', '2009-02-13', NULL, 'Entregado', 3, 'Entregado sin fecha de entrega');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (68, '2009-02-10', '2009-02-17', '2009-02-20', 'Entregado', 3, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (74, '2009-01-14', '2009-01-22', NULL, 'Rechazado', 15, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (75, '2009-01-11', '2009-01-13', '2009-01-13', 'Entregado', 15, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (76, '2008-11-15', '2008-11-23', '2008-11-23', 'Entregado', 15, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (77, '2009-01-03', '2009-01-08', NULL, 'Pendiente', 15, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (78, '2008-12-15', '2008-12-17', '2008-12-17', 'Entregado', 15, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (79, '2009-01-12', '2009-01-13', '2009-01-13', 'Entregado', 28, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (80, '2009-01-25', '2009-01-26', NULL, 'Pendiente', 28, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (81, '2009-01-18', '2009-01-24', NULL, 'Rechazado', 28, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (82, '2009-01-20', '2009-01-29', '2009-01-29', 'Entregado', 28, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (83, '2009-01-24', '2009-01-28', NULL, 'Entregado', 28, 'Entregado sin fecha de entrega');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (89, '2007-10-05', '2007-12-13', '2007-12-10', 'Entregado', 35, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (90, '2009-02-07', '2008-02-17', NULL, 'Pendiente', 27, 'Fecha esperada anterior al pedido');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (91, '2009-03-18', '2009-03-29', '2009-03-27', 'Entregado', 27, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (92, '2009-04-19', '2009-04-30', '2009-05-03', 'Entregado', 27, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (93, '2009-05-03', '2009-05-30', '2009-05-17', 'Entregado', 27, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (94, '2009-10-18', '2009-11-01', NULL, 'Pendiente', 27, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (95, '2008-01-04', '2008-01-19', '2008-01-19', 'Entregado', 35, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (96, '2008-03-20', '2008-04-12', '2008-04-13', 'Entregado', 35, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (97, '2008-10-08', '2008-11-25', '2008-11-25', 'Entregado', 35, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (98, '2009-01-08', '2009-02-13', NULL, 'Pendiente', 35, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (99, '2009-02-15', '2009-02-27', NULL, 'Pendiente', 16, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (100, '2009-01-10', '2009-01-15', '2009-01-15', 'Entregado', 16, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (101, '2009-03-07', '2009-03-27', NULL, 'Rechazado', 16, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (102, '2008-12-28', '2009-01-08', '2009-01-08', 'Entregado', 16, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (103, '2009-01-15', '2009-01-20', '2009-01-24', 'Pendiente', 30, 'Tiene fecha de entrega y estado Pendiente');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (104, '2009-03-02', '2009-03-06', '2009-03-06', 'Entregado', 30, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (105, '2009-02-14', '2009-02-20', NULL, 'Rechazado', 30, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (106, '2009-05-13', '2009-05-15', '2009-05-20', 'Pendiente', 30, 'Tiene fecha de entrega y estado Pendiente');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (107, '2009-04-06', '2009-04-10', '2009-04-10', 'Entregado', 30, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (108, '2009-04-09', '2009-04-15', '2009-04-15', 'Entregado', 16, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (109, '2006-05-25', '2006-07-28', '2006-07-28', 'Entregado', 38, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (110, '2007-03-19', '2007-04-24', '2007-04-24', 'Entregado', 38, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (111, '2008-03-05', '2008-03-30', '2008-03-30', 'Entregado', 36, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (112, '2009-03-05', '2009-04-06', '2009-05-07', 'Pendiente', 36, 'Tiene fecha de entrega y estado Pendiente');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (113, '2008-10-28', '2008-11-09', '2009-01-09', 'Rechazado', 36, 'Tiene fecha de entrega y estado Rechazado');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (114, '2009-01-15', '2009-01-29', '2009-01-31', 'Entregado', 36, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (115, '2008-11-29', '2009-01-26', '2009-02-27', 'Pendiente', 36, 'Tiene fecha de entrega y estado Pendiente');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (116, '2008-06-28', '2008-08-01', '2008-08-01', 'Entregado', 38, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (117, '2008-08-25', '2008-10-01', NULL, 'Rechazado', 38, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (118, '2009-02-15', '2009-02-27', NULL, 'Pendiente', 16, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (119, '2009-01-10', '2009-01-15', '2009-01-15', 'Entregado', 16, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (120, '2009-03-07', '2009-03-27', NULL, 'Rechazado', 16, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (121, '2008-12-28', '2009-01-08', '2009-01-08', 'Entregado', 16, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (122, '2009-04-09', '2009-04-15', '2009-04-15', 'Entregado', 16, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (123, '2009-01-15', '2009-01-20', '2009-01-24', 'Pendiente', 30, 'Tiene fecha de entrega y estado Pendiente');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (124, '2009-03-02', '2009-03-06', '2009-03-06', 'Entregado', 30, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (125, '2009-02-14', '2009-02-20', NULL, 'Rechazado', 30, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (126, '2009-05-13', '2009-05-15', '2009-05-20', 'Pendiente', 30, 'Tiene fecha de entrega y estado Pendiente');
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (127, '2009-04-06', '2009-04-10', '2009-04-10', 'Entregado', 30, NULL);
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega, Estado, ID_cliente, Observacion) VALUES (128, '2008-11-10', '2008-12-10', '2008-12-29', 'Rechazado', 38, 'Tiene fecha de entrega y estado Rechazado');
GO

-- stg_producto: 276 filas
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('11679', 'Sierra de Poda 400MM', 2, '0,258', 'HiperGarden Tools', 14.00, 11.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('21636', 'Pala', 2, '0,156', 'HiperGarden Tools', 14.00, 13.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('22225', 'Rastrillo de Jardín', 2, '1,064', 'HiperGarden Tools', 12.00, 11.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('30310', 'Azadón', 2, '0,168', 'HiperGarden Tools', 12.00, 11.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('AR-001', 'Ajedrea', 3, '15-20', 'Murcia Seasons', 1.00, 0.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('AR-002', 'Lavándula Dentata', 3, '15-20', 'Murcia Seasons', 1.00, 0.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('AR-003', 'Mejorana', 3, '15-20', 'Murcia Seasons', 1.00, 0.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('AR-004', 'Melissa', 3, '15-20', 'Murcia Seasons', 1.00, 0.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('AR-005', 'Mentha Sativa', 3, '15-20', 'Murcia Seasons', 1.00, 0.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('AR-006', 'Petrosilium Hortense (Peregil)', 3, '15-20', 'Murcia Seasons', 1.00, 0.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('AR-007', 'Salvia Mix', 3, '15-20', 'Murcia Seasons', 1.00, 0.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('AR-008', 'Thymus Citriodra (Tomillo limón)', 3, '15-20', 'Murcia Seasons', 1.00, 0.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('AR-009', 'Thymus Vulgaris', 3, '15-20', 'Murcia Seasons', 1.00, 0.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('AR-010', 'Santolina Chamaecyparys', 3, '15-20', 'Murcia Seasons', 1.00, 0.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-1', 'Expositor Cítricos Mix', 4, '100-120', 'Frutales Talavera S.A', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-10', 'Limonero 2 años injerto', 4, NULL, 'NaranjasValencianas.com', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-100', 'Nectarina', 4, '8/10', 'Frutales Talavera S.A', 11.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-101', 'Nogal', 4, '8/10', 'Frutales Talavera S.A', 13.00, 10.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-102', 'Olea-Olivos', 4, '8/10', 'Frutales Talavera S.A', 18.00, 14.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-103', 'Olea-Olivos', 4, '10/12', 'Frutales Talavera S.A', 25.00, 20.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-104', 'Olea-Olivos', 4, '12/4', 'Frutales Talavera S.A', 49.00, 39.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-105', 'Olea-Olivos', 4, '14/16', 'Frutales Talavera S.A', 70.00, 56.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-106', 'Peral', 4, '8/10', 'Frutales Talavera S.A', 11.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-107', 'Peral', 4, '10/12', 'Frutales Talavera S.A', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-108', 'Peral', 4, '12/14', 'Frutales Talavera S.A', 32.00, 25.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-11', 'Limonero 30/40', 4, NULL, 'NaranjasValencianas.com', 100.00, 80.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-12', 'Kunquat', 4, NULL, 'NaranjasValencianas.com', 21.00, 16.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-13', 'Kunquat  EXTRA con FRUTA', 4, '150-170', 'NaranjasValencianas.com', 57.00, 45.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-14', 'Calamondin Mini', 4, NULL, 'Frutales Talavera S.A', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-15', 'Calamondin Copa', 4, NULL, 'Frutales Talavera S.A', 25.00, 20.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-16', 'Calamondin Copa EXTRA Con FRUTA', 4, '100-120', 'Frutales Talavera S.A', 45.00, 36.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-17', 'Rosal bajo 1ª -En maceta-inicio brotación', 4, NULL, 'Frutales Talavera S.A', 2.00, 1.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-18', 'ROSAL TREPADOR', 4, NULL, 'Frutales Talavera S.A', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-19', 'Camelia Blanco, Chrysler Rojo, Soraya Naranja,', 4, NULL, 'NaranjasValencianas.com', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-2', 'Naranjo -Plantón joven 1 año injerto', 4, NULL, 'NaranjasValencianas.com', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-20', 'Landora Amarillo, Rose Gaujard bicolor blanco-rojo', 4, NULL, 'Frutales Talavera S.A', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-21', 'Kordes Perfect bicolor rojo-amarillo, Roundelay rojo fuerte', 4, NULL, 'Frutales Talavera S.A', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-22', 'Pitimini rojo', 4, NULL, 'Frutales Talavera S.A', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-23', 'Rosal copa', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-24', 'Albaricoquero Corbato', 4, NULL, 'Melocotones de Cieza S.A.', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-25', 'Albaricoquero Moniqui', 4, NULL, 'Melocotones de Cieza S.A.', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-26', 'Albaricoquero Kurrot', 4, NULL, 'Melocotones de Cieza S.A.', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-27', 'Cerezo Burlat', 4, NULL, 'Jerte Distribuciones S.L.', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-28', 'Cerezo Picota', 4, NULL, 'Jerte Distribuciones S.L.', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-29', 'Cerezo Napoleón', 4, NULL, 'Jerte Distribuciones S.L.', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-3', 'Naranjo 2 años injerto', 4, NULL, 'NaranjasValencianas.com', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-30', 'Ciruelo R. Claudia Verde', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-31', 'Ciruelo Santa Rosa', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-32', 'Ciruelo Golden Japan', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-33', 'Ciruelo Friar', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-34', 'Ciruelo Reina C. De Ollins', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-35', 'Ciruelo Claudia Negra', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-36', 'Granado Mollar de Elche', 4, NULL, 'Frutales Talavera S.A', 9.00, 7.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-37', 'Higuera Napolitana', 4, NULL, 'Frutales Talavera S.A', 9.00, 7.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-38', 'Higuera Verdal', 4, NULL, 'Frutales Talavera S.A', 9.00, 7.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-39', 'Higuera Breva', 4, NULL, 'Frutales Talavera S.A', 9.00, 7.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-4', 'Naranjo calibre 8/10', 4, NULL, 'NaranjasValencianas.com', 29.00, 23.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-40', 'Manzano Starking Delicious', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-41', 'Manzano Reineta', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-42', 'Manzano Golden Delicious', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-43', 'Membrillero Gigante de Wranja', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-44', 'Melocotonero Spring Crest', 4, NULL, 'Melocotones de Cieza S.A.', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-45', 'Melocotonero Amarillo de Agosto', 4, NULL, 'Melocotones de Cieza S.A.', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-46', 'Melocotonero Federica', 4, NULL, 'Melocotones de Cieza S.A.', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-47', 'Melocotonero Paraguayo', 4, NULL, 'Melocotones de Cieza S.A.', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-48', 'Nogal Común', 4, NULL, 'Frutales Talavera S.A', 9.00, 7.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-49', 'Parra Uva de Mesa', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-5', 'Mandarino -Plantón joven', 4, NULL, 'Frutales Talavera S.A', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-50', 'Peral Castell', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-51', 'Peral Williams', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-52', 'Peral Conference', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-53', 'Peral Blanq. de Aranjuez', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-54', 'Níspero Tanaca', 4, NULL, 'Frutales Talavera S.A', 9.00, 7.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-55', 'Olivo Cipresino', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-56', 'Nectarina', 4, NULL, 'Frutales Talavera S.A', 8.00, 6.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-57', 'Kaki Rojo Brillante', 4, NULL, 'NaranjasValencianas.com', 9.00, 7.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-58', 'Albaricoquero', 4, '8/10', 'Melocotones de Cieza S.A.', 11.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-59', 'Albaricoquero', 4, '10/12', 'Melocotones de Cieza S.A.', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-6', 'Mandarino 2 años injerto', 4, NULL, 'Frutales Talavera S.A', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-60', 'Albaricoquero', 4, '12/14', 'Melocotones de Cieza S.A.', 32.00, 25.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-61', 'Albaricoquero', 4, '14/16', 'Melocotones de Cieza S.A.', 49.00, 39.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-62', 'Albaricoquero', 4, '16/18', 'Melocotones de Cieza S.A.', 70.00, 56.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-63', 'Cerezo', 4, '8/10', 'Jerte Distribuciones S.L.', 11.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-64', 'Cerezo', 4, '10/12', 'Jerte Distribuciones S.L.', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-65', 'Cerezo', 4, '12/14', 'Jerte Distribuciones S.L.', 32.00, 25.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-66', 'Cerezo', 4, '14/16', 'Jerte Distribuciones S.L.', 49.00, 39.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-67', 'Cerezo', 4, '16/18', 'Jerte Distribuciones S.L.', 70.00, 56.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-68', 'Cerezo', 4, '18/20', 'Jerte Distribuciones S.L.', 80.00, 64.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-69', 'Cerezo', 4, '20/25', 'Jerte Distribuciones S.L.', 91.00, 72.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-7', 'Mandarino calibre 8/10', 4, NULL, 'Frutales Talavera S.A', 29.00, 23.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-70', 'Ciruelo', 4, '8/10', 'Frutales Talavera S.A', 11.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-71', 'Ciruelo', 4, '10/12', 'Frutales Talavera S.A', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-72', 'Ciruelo', 4, '12/14', 'Frutales Talavera S.A', 32.00, 25.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-73', 'Granado', 4, '8/10', 'Frutales Talavera S.A', 13.00, 10.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-74', 'Granado', 4, '10/12', 'Frutales Talavera S.A', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-75', 'Granado', 4, '12/14', 'Frutales Talavera S.A', 32.00, 25.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-76', 'Granado', 4, '14/16', 'Frutales Talavera S.A', 49.00, 39.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-77', 'Granado', 4, '16/18', 'Frutales Talavera S.A', 70.00, 56.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-78', 'Higuera', 4, '8/10', 'Frutales Talavera S.A', 15.00, 12.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-79', 'Higuera', 4, '10/12', 'Frutales Talavera S.A', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-8', 'Limonero -Plantón joven', 4, NULL, 'NaranjasValencianas.com', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-80', 'Higuera', 4, '12/14', 'Frutales Talavera S.A', 32.00, 25.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-81', 'Higuera', 4, '14/16', 'Frutales Talavera S.A', 49.00, 39.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-82', 'Higuera', 4, '16/18', 'Frutales Talavera S.A', 70.00, 56.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-83', 'Higuera', 4, '18/20', 'Frutales Talavera S.A', 80.00, 64.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-84', 'Kaki', 4, '8/10', 'NaranjasValencianas.com', 13.00, 10.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-85', 'Kaki', 4, '16/18', 'NaranjasValencianas.com', 70.00, 56.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-86', 'Manzano', 4, '8/10', 'Frutales Talavera S.A', 11.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-87', 'Manzano', 4, '10/12', 'Frutales Talavera S.A', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-88', 'Manzano', 4, '12/14', 'Frutales Talavera S.A', 32.00, 25.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-89', 'Manzano', 4, '14/16', 'Frutales Talavera S.A', 49.00, 39.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-9', 'Limonero calibre 8/10', 4, NULL, 'NaranjasValencianas.com', 29.00, 23.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-90', 'Níspero', 4, '16/18', 'Frutales Talavera S.A', 70.00, 56.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-91', 'Níspero', 4, '18/20', 'Frutales Talavera S.A', 80.00, 64.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-92', 'Melocotonero', 4, '8/10', 'Melocotones de Cieza S.A.', 11.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-93', 'Melocotonero', 4, '10/12', 'Melocotones de Cieza S.A.', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-94', 'Melocotonero', 4, '12/14', 'Melocotones de Cieza S.A.', 32.00, 25.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-95', 'Melocotonero', 4, '14/16', 'Melocotones de Cieza S.A.', 49.00, 39.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-96', 'Membrillero', 4, '8/10', 'Frutales Talavera S.A', 11.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-97', 'Membrillero', 4, '10/12', 'Frutales Talavera S.A', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-98', 'Membrillero', 4, '12/14', 'Frutales Talavera S.A', 32.00, 25.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('FR-99', 'Membrillero', 4, '14/16', 'Frutales Talavera S.A', 49.00, 39.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-001', 'Arbustos Mix Maceta', 5, '40-60', 'Valencia Garden Service', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-100', 'Mimosa Injerto CLASICA Dealbata', 5, '100-110', 'Viveros EL OASIS', 12.00, 9.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-101', 'Expositor Mimosa Semilla Mix', 5, '170-200', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-102', 'Mimosa Semilla Bayleyana', 5, '170-200', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-103', 'Mimosa Semilla Bayleyana', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-104', 'Mimosa Semilla Cyanophylla', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-105', 'Mimosa Semilla Espectabilis', 5, '160-170', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-106', 'Mimosa Semilla Longifolia', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-107', 'Mimosa Semilla Floribunda 4 estaciones', 5, '120-140', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-108', 'Abelia Floribunda', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-109', 'Callistemom (Mix)', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-110', 'Callistemom (Mix)', 5, '40-60', 'Viveros EL OASIS', 2.00, 1.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-111', 'Corylus Avellana \"Contorta\"', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-112', 'Escallonia (Mix)', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-113', 'Evonimus Emerald Gayeti', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-114', 'Evonimus Pulchellus', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-115', 'Forsytia Intermedia \"Lynwood\"', 5, '35-45', 'Viveros EL OASIS', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-116', 'Hibiscus Syriacus  \"Diana\" -Blanco Puro', 5, '35-45', 'Viveros EL OASIS', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-117', 'Hibiscus Syriacus  \"Helene\" -Blanco-C.rojo', 5, '35-45', 'Viveros EL OASIS', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-118', 'Hibiscus Syriacus \"Pink Giant\" Rosa', 5, '35-45', 'Viveros EL OASIS', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-119', 'Laurus Nobilis Arbusto - Ramificado Bajo', 5, '40-50', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-120', 'Lonicera Nitida', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-121', 'Lonicera Nitida \"Maigrum\"', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-122', 'Lonicera Pileata', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-123', 'Philadelphus \"Virginal\"', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-124', 'Prunus pisardii', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-125', 'Viburnum Tinus \"Eve Price\"', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-126', 'Weigelia \"Bristol Ruby\"', 5, '35-45', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-127', 'Camelia japonica', 5, '40-60', 'Viveros EL OASIS', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-128', 'Camelia japonica ejemplar', 5, '200-250', 'Viveros EL OASIS', 98.00, 78.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-129', 'Camelia japonica ejemplar', 5, '250-300', 'Viveros EL OASIS', 110.00, 88.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-130', 'Callistemom COPA', 5, '110/120', 'Viveros EL OASIS', 18.00, 14.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-131', 'Leptospermum formado PIRAMIDE', 5, '80-100', 'Viveros EL OASIS', 18.00, 14.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-132', 'Leptospermum COPA', 5, '110/120', 'Viveros EL OASIS', 18.00, 14.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-133', 'Nerium oleander-CALIDAD \"GARDEN\"', 5, '40-45', 'Viveros EL OASIS', 2.00, 1.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-134', 'Nerium Oleander Arbusto GRANDE', 5, '160-200', 'Viveros EL OASIS', 38.00, 30.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-135', 'Nerium oleander COPA  Calibre 6/8', 5, '50-60', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-136', 'Nerium oleander ARBOL Calibre 8/10', 5, '225-250', 'Viveros EL OASIS', 18.00, 14.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-137', 'ROSAL TREPADOR', 5, NULL, 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-138', 'Camelia Blanco, Chrysler Rojo, Soraya Naranja,', 5, NULL, 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-139', 'Landora Amarillo, Rose Gaujard bicolor blanco-rojo', 5, NULL, 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-140', 'Kordes Perfect bicolor rojo-amarillo, Roundelay rojo fuerte', 5, NULL, 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-141', 'Pitimini rojo', 5, NULL, 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-142', 'Solanum Jazminoide', 5, '150-160', 'Viveros EL OASIS', 2.00, 1.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-143', 'Wisteria Sinensis  azul, rosa, blanca', 5, NULL, 'Viveros EL OASIS', 9.00, 7.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-144', 'Wisteria Sinensis INJERTADAS DECÃâ€œ', 5, '140-150', 'Viveros EL OASIS', 12.00, 9.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-145', 'Bougamvillea Sanderiana Tutor', 5, '80-100', 'Viveros EL OASIS', 2.00, 1.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-146', 'Bougamvillea Sanderiana Tutor', 5, '125-150', 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-147', 'Bougamvillea Sanderiana Tutor', 5, '180-200', 'Viveros EL OASIS', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-148', 'Bougamvillea Sanderiana Espaldera', 5, '45-50', 'Viveros EL OASIS', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-149', 'Bougamvillea Sanderiana Espaldera', 5, '140-150', 'Viveros EL OASIS', 17.00, 13.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-150', 'Bougamvillea roja, naranja', 5, '110-130', 'Viveros EL OASIS', 2.00, 1.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-151', 'Bougamvillea Sanderiana, 3 tut. piramide', 5, NULL, 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-152', 'Expositor Árboles clima continental', 5, '170-200', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-153', 'Expositor Árboles clima mediterráneo', 5, '170-200', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-154', 'Expositor Árboles borde del mar', 5, '170-200', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-155', 'Acer Negundo', 5, '200-225', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-156', 'Acer platanoides', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-157', 'Acer Pseudoplatanus', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-158', 'Brachychiton Acerifolius', 5, '200-225', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-159', 'Brachychiton Discolor', 5, '200-225', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-160', 'Brachychiton Rupestris', 5, '170-200', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-161', 'Cassia Corimbosa', 5, '200-225', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-162', 'Cassia Corimbosa', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-163', 'Chitalpa Summer Bells', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-164', 'Erytrina Kafra', 5, '170-180', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-165', 'Erytrina Kafra', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-166', 'Eucalyptus Citriodora', 5, '170-200', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-167', 'Eucalyptus Ficifolia', 5, '170-200', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-168', 'Eucalyptus Ficifolia', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-169', 'Hibiscus Syriacus  Var. Injertadas 1 Tallo', 5, '170-200', 'Viveros EL OASIS', 12.00, 9.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-170', 'Lagunaria Patersonii', 5, '140-150', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-171', 'Lagunaria Patersonii', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-172', 'Lagunaria patersonii  calibre 8/10', 5, '200-225', 'Viveros EL OASIS', 18.00, 14.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-173', 'Morus Alba', 5, '200-225', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-174', 'Morus Alba  calibre 8/10', 5, '200-225', 'Viveros EL OASIS', 18.00, 14.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-175', 'Platanus Acerifolia', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-176', 'Prunus pisardii', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-177', 'Robinia Pseudoacacia Casque Rouge', 5, '200-225', 'Viveros EL OASIS', 15.00, 12.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-178', 'Salix Babylonica  Pendula', 5, '170-200', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-179', 'Sesbania Punicea', 5, '170-200', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-180', 'Tamarix  Ramosissima Pink Cascade', 5, '170-200', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-181', 'Tamarix  Ramosissima Pink Cascade', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-182', 'Tecoma Stands', 5, '200-225', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-183', 'Tecoma Stands', 5, '200-225', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-184', 'Tipuana Tipu', 5, '170-200', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-185', 'Pleioblastus distichus-Bambú enano', 5, '15-20', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-186', 'Sasa palmata', 5, '20-30', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-187', 'Sasa palmata', 5, '40-45', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-188', 'Sasa palmata', 5, '50-60', 'Viveros EL OASIS', 25.00, 20.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-189', 'Phylostachys aurea', 5, '180-200', 'Viveros EL OASIS', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-190', 'Phylostachys aurea', 5, '250-300', 'Viveros EL OASIS', 32.00, 25.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-191', 'Phylostachys Bambusa Spectabilis', 5, '180-200', 'Viveros EL OASIS', 24.00, 19.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-192', 'Phylostachys biseti', 5, '160-170', 'Viveros EL OASIS', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-193', 'Phylostachys biseti', 5, '160-180', 'Viveros EL OASIS', 20.00, 16.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-194', 'Pseudosasa japonica (Metake)', 5, '225-250', 'Viveros EL OASIS', 20.00, 16.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-195', 'Pseudosasa japonica (Metake)', 5, '30-40', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-196', 'Cedrus Deodara', 5, '80-100', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-197', 'Cedrus Deodara \"Feeling Blue\" Novedad', 5, 'rastrero', 'Viveros EL OASIS', 12.00, 9.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-198', 'Juniperus chinensis \"Blue Alps\"', 5, '20-30', 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-199', 'Juniperus Chinensis Stricta', 5, '20-30', 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-200', 'Juniperus horizontalis Wiltonii', 5, '20-30', 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-201', 'Juniperus squamata \"Blue Star\"', 5, '20-30', 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-202', 'Juniperus x media Phitzeriana verde', 5, '20-30', 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-203', 'Pinus Canariensis', 5, '80-100', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-204', 'Pinus Halepensis', 5, '160-180', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-205', 'Pinus Pinea -Pino Piñonero', 5, '70-80', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-206', 'Thuja Esmeralda', 5, '80-100', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-207', 'Tuja Occidentalis Woodwardii', 5, '20-30', 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-208', 'Tuja orientalis \"Aurea nana\"', 5, '20-30', 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-209', 'Archontophoenix Cunninghamiana', 5, '80 - 100', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-210', 'Beucarnea Recurvata', 5, '130  - 150', 'Viveros EL OASIS', 39.00, 31.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-211', 'Beucarnea Recurvata', 5, '180 - 200', 'Viveros EL OASIS', 59.00, 47.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-212', 'Bismarckia Nobilis', 5, '200 - 220', 'Viveros EL OASIS', 217.00, 173.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-213', 'Bismarckia Nobilis', 5, '240 - 260', 'Viveros EL OASIS', 266.00, 212.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-214', 'Brahea Armata', 5, '45 - 60', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-215', 'Brahea Armata', 5, '120 - 140', 'Viveros EL OASIS', 112.00, 89.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-216', 'Brahea Edulis', 5, '80 - 100', 'Viveros EL OASIS', 19.00, 15.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-217', 'Brahea Edulis', 5, '140 - 160', 'Viveros EL OASIS', 64.00, 51.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-218', 'Butia Capitata', 5, '70 - 90', 'Viveros EL OASIS', 25.00, 20.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-219', 'Butia Capitata', 5, '90 - 110', 'Viveros EL OASIS', 29.00, 23.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-220', 'Butia Capitata', 5, '90 - 120', 'Viveros EL OASIS', 36.00, 28.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-221', 'Butia Capitata', 5, '85 - 105', 'Viveros EL OASIS', 59.00, 47.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-222', 'Butia Capitata', 5, '130 - 150', 'Viveros EL OASIS', 87.00, 69.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-223', 'Chamaerops Humilis', 5, '40 - 45', 'Viveros EL OASIS', 4.00, 3.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-224', 'Chamaerops Humilis', 5, '50 - 60', 'Viveros EL OASIS', 7.00, 5.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-225', 'Chamaerops Humilis', 5, '70 - 90', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-226', 'Chamaerops Humilis', 5, '115 - 130', 'Viveros EL OASIS', 38.00, 30.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-227', 'Chamaerops Humilis', 5, '130 - 150', 'Viveros EL OASIS', 64.00, 51.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-228', 'Chamaerops Humilis \"Cerifera\"', 5, '70 - 80', 'Viveros EL OASIS', 32.00, 25.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-229', 'Chrysalidocarpus Lutescens -ARECA', 5, '130 - 150', 'Viveros EL OASIS', 22.00, 17.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-230', 'Cordyline Australis -DRACAENA', 5, '190 - 210', 'Viveros EL OASIS', 38.00, 30.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-231', 'Cycas Revoluta', 5, '55 - 65', 'Viveros EL OASIS', 15.00, 12.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-232', 'Cycas Revoluta', 5, '80 - 90', 'Viveros EL OASIS', 34.00, 27.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-233', 'Dracaena Drago', 5, '60 - 70', 'Viveros EL OASIS', 13.00, 10.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-234', 'Dracaena Drago', 5, '130 - 150', 'Viveros EL OASIS', 64.00, 51.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-235', 'Dracaena Drago', 5, '150 - 175', 'Viveros EL OASIS', 92.00, 73.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-236', 'Jubaea Chilensis', 5, NULL, 'Viveros EL OASIS', 49.00, 39.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-237', 'Livistonia Australis', 5, '100 - 125', 'Viveros EL OASIS', 19.00, 15.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-238', 'Livistonia Decipiens', 5, '90 - 110', 'Viveros EL OASIS', 19.00, 15.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-239', 'Livistonia Decipiens', 5, '180 - 200', 'Viveros EL OASIS', 49.00, 39.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-240', 'Phoenix Canariensis', 5, '110 - 130', 'Viveros EL OASIS', 6.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-241', 'Phoenix Canariensis', 5, '180 - 200', 'Viveros EL OASIS', 19.00, 15.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-242', 'Rhaphis Excelsa', 5, '80 - 100', 'Viveros EL OASIS', 21.00, 16.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-243', 'Rhaphis Humilis', 5, '150- 170', 'Viveros EL OASIS', 64.00, 51.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-244', 'Sabal Minor', 5, '60 - 75', 'Viveros EL OASIS', 11.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-245', 'Sabal Minor', 5, '120 - 140', 'Viveros EL OASIS', 34.00, 27.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-246', 'Trachycarpus Fortunei', 5, '90 - 105', 'Viveros EL OASIS', 18.00, 14.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-247', 'Trachycarpus Fortunei', 5, '250-300', 'Viveros EL OASIS', 462.00, 369.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-248', 'Washingtonia Robusta', 5, '60 - 70', 'Viveros EL OASIS', 3.00, 2.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-249', 'Washingtonia Robusta', 5, '130 - 150', 'Viveros EL OASIS', 5.00, 4.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-250', 'Yucca Jewel', 5, '80 - 105', 'Viveros EL OASIS', 10.00, 8.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-251', 'Zamia Furfuracaea', 5, '90 - 110', 'Viveros EL OASIS', 168.00, 134.00);
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones, Proveedor, Precio_Venta, Precio_Proveedor) VALUES ('OR-99', 'Mimosa DEALBATA Gaulois Astier', 5, '200-225', 'Viveros EL OASIS', 14.00, 11.00);
GO

-- stg_detalle_pedido: 318 filas
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (1, 'FR-67', 3, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (1, 'OR-127', 1, 40, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (1, 'OR-141', 2, 25, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (1, 'OR-241', 4, 15, 19.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (1, 'OR-99', 5, 23, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (2, 'FR-4', 6, 3, 29.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (2, 'FR-40', 7, 7, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (2, 'OR-140', 3, 50, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (2, 'OR-141', 2, 20, 5.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (2, 'OR-159', 5, 12, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (2, 'OR-227', 1, 67, 64.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (2, 'OR-247', 4, 5, 462.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (3, 'FR-48', 6, 120, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (3, 'OR-122', 4, 32, 5.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (3, 'OR-123', 5, 11, 5.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (3, 'OR-213', 1, 30, 266.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (3, 'OR-217', 2, 15, 65.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (3, 'OR-218', 3, 24, 25.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (4, 'FR-31', 7, 12, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (4, 'FR-34', 6, 42, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (4, 'FR-40', 8, 42, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (4, 'OR-152', 5, 3, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (4, 'OR-155', 3, 4, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (4, 'OR-156', 4, 17, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (4, 'OR-157', 2, 38, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (4, 'OR-222', 1, 21, 59.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (8, 'FR-106', 1, 3, 11.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (8, 'FR-108', 2, 1, 32.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (8, 'FR-11', 3, 10, 100.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (9, 'AR-001', 3, 80, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (9, 'AR-008', 2, 450, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (9, 'FR-106', 1, 80, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (9, 'FR-69', 2, 15, 91.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (10, 'FR-82', 2, 5, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (10, 'FR-91', 1, 30, 75.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (10, 'OR-234', 3, 5, 64.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (11, 'AR-006', 3, 180, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (11, 'OR-247', 1, 80, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (12, 'AR-009', 1, 290, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (13, '11679', 1, 5, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (13, '21636', 2, 12, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (13, 'FR-11', 3, 5, 100.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (14, 'FR-100', 2, 8, 11.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (14, 'FR-13', 1, 13, 57.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (15, 'FR-84', 3, 4, 13.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (15, 'OR-101', 2, 2, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (15, 'OR-156', 1, 6, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (15, 'OR-203', 4, 9, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (16, '30310', 1, 12, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (16, 'FR-36', 2, 10, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (17, '11679', 1, 5, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (17, '22225', 3, 5, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (17, 'FR-37', 2, 5, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (17, 'FR-64', 4, 5, 22.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (17, 'OR-136', 5, 5, 18.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (18, '22225', 2, 4, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (18, 'FR-22', 1, 2, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (18, 'OR-159', 3, 10, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (19, '30310', 5, 9, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (19, 'FR-23', 4, 6, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (19, 'FR-75', 2, 1, 32.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (19, 'FR-84', 1, 5, 13.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (19, 'OR-208', 3, 20, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (20, '11679', 1, 14, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (20, '30310', 2, 8, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (21, '21636', 3, 5, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (21, 'FR-18', 1, 22, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (21, 'FR-53', 2, 3, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (22, 'OR-240', 1, 1, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (23, 'AR-002', 4, 110, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (23, 'FR-107', 3, 50, 22.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (23, 'FR-85', 2, 4, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (23, 'OR-249', 1, 30, 5.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (24, '22225', 1, 3, 15.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (24, 'FR-1', 4, 4, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (24, 'FR-23', 2, 2, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (24, 'OR-241', 3, 10, 20.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (25, 'FR-77', 1, 15, 69.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (25, 'FR-9', 3, 4, 30.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (25, 'FR-94', 2, 10, 30.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (26, 'FR-15', 3, 9, 25.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (26, 'OR-188', 1, 4, 25.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (26, 'OR-218', 2, 14, 25.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (27, 'OR-101', 2, 22, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (27, 'OR-102', 3, 22, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (27, 'OR-186', 1, 40, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (28, 'FR-11', 3, 8, 99.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (28, 'OR-213', 2, 3, 266.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (28, 'OR-247', 1, 1, 462.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (29, 'FR-82', 4, 4, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (29, 'FR-9', 1, 4, 28.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (29, 'FR-94', 5, 20, 31.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (29, 'OR-129', 2, 2, 111.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (29, 'OR-160', 3, 10, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (30, 'AR-004', 6, 10, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (30, 'FR-108', 2, 2, 32.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (30, 'FR-12', 3, 2, 19.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (30, 'FR-72', 5, 4, 31.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (30, 'FR-89', 1, 10, 45.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (30, 'OR-120', 4, 5, 5.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (31, 'AR-009', 3, 25, 2.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (31, 'FR-102', 1, 1, 20.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (31, 'FR-4', 2, 6, 29.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (32, '11679', 4, 1, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (32, '21636', 5, 4, 15.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (32, '22225', 3, 1, 15.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (32, 'OR-128', 2, 29, 100.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (32, 'OR-193', 1, 5, 20.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (33, 'FR-17', 4, 423, 2.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (33, 'FR-29', 3, 120, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (33, 'OR-214', 2, 212, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (33, 'OR-247', 1, 150, 462.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (34, 'FR-3', 4, 56, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (34, 'FR-7', 3, 12, 29.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (34, 'OR-172', 1, 20, 18.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (34, 'OR-174', 2, 24, 18.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (35, '21636', 4, 12, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (35, 'FR-47', 3, 55, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (35, 'OR-165', 2, 3, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (35, 'OR-181', 1, 36, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (35, 'OR-225', 5, 72, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (36, '30310', 2, 4, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (36, 'FR-1', 3, 2, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (36, 'OR-147', 4, 6, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (36, 'OR-203', 5, 1, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (36, 'OR-99', 1, 15, 13.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (37, 'FR-105', 1, 4, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (37, 'FR-57', 2, 203, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (37, 'OR-176', 3, 38, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (38, '11679', 1, 5, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (38, '21636', 2, 2, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (39, '22225', 1, 3, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (39, '30310', 2, 6, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (40, 'AR-001', 1, 4, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (40, 'AR-002', 2, 8, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (41, 'AR-003', 1, 5, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (41, 'AR-004', 2, 5, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (42, 'AR-005', 1, 3, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (42, 'AR-006', 2, 1, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (43, 'AR-007', 1, 9, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (44, 'AR-008', 1, 5, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (45, 'AR-009', 1, 6, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (45, 'AR-010', 2, 4, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (46, 'FR-1', 1, 4, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (46, 'FR-10', 2, 8, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (47, 'FR-100', 1, 9, 11.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (47, 'FR-101', 2, 5, 13.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (48, 'FR-102', 1, 1, 18.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (48, 'FR-103', 2, 1, 25.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (48, 'OR-234', 1, 50, 64.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (48, 'OR-236', 2, 45, 49.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (48, 'OR-237', 3, 50, 19.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (49, 'OR-204', 1, 50, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (49, 'OR-205', 2, 10, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (49, 'OR-206', 3, 5, 5.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (50, 'OR-225', 1, 12, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (50, 'OR-226', 2, 15, 38.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (50, 'OR-227', 3, 44, 64.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (51, 'OR-209', 1, 50, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (51, 'OR-210', 2, 80, 39.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (51, 'OR-211', 3, 70, 59.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (52, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (53, 'FR-2', 1, 1, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (53, 'FR-85', 3, 1, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (53, 'FR-86', 2, 2, 11.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (53, 'OR-116', 4, 6, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (54, '11679', 3, 3, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (54, 'FR-100', 2, 45, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (54, 'FR-18', 1, 5, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (54, 'FR-79', 4, 3, 22.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (54, 'OR-116', 6, 8, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (54, 'OR-123', 5, 3, 5.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (54, 'OR-168', 7, 2, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (55, 'OR-115', 1, 9, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (55, 'OR-213', 2, 2, 266.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (55, 'OR-227', 5, 6, 64.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (55, 'OR-243', 4, 2, 64.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (55, 'OR-247', 3, 1, 462.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (56, 'OR-129', 5, 1, 115.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (56, 'OR-130', 6, 10, 18.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (56, 'OR-179', 3, 1, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (56, 'OR-196', 4, 3, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (56, 'OR-207', 2, 4, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (56, 'OR-250', 1, 3, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (57, 'FR-69', 4, 6, 91.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (57, 'FR-81', 3, 3, 49.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (57, 'FR-84', 1, 2, 13.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (57, 'FR-94', 2, 6, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (58, 'OR-102', 3, 65, 18.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (58, 'OR-139', 1, 80, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (58, 'OR-172', 2, 69, 15.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (58, 'OR-177', 4, 150, 15.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (59, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (60, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (61, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (62, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (63, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (64, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (65, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (66, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (67, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (68, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (74, 'FR-67', 1, 15, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (74, 'OR-227', 2, 34, 64.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (74, 'OR-247', 3, 42, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (75, 'AR-006', 2, 60, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (75, 'FR-87', 3, 24, 22.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (75, 'OR-157', 1, 46, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (76, 'AR-009', 5, 250, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (76, 'FR-79', 3, 40, 22.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (76, 'FR-87', 4, 24, 22.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (76, 'FR-94', 1, 35, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (76, 'OR-196', 2, 25, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (77, '22225', 2, 34, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (77, '30310', 1, 15, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (78, 'FR-53', 2, 25, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (78, 'FR-85', 3, 56, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (78, 'OR-157', 4, 42, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (78, 'OR-208', 1, 30, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (79, 'OR-240', 1, 50, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (80, 'FR-11', 3, 40, 100.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (80, 'FR-36', 2, 47, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (80, 'OR-136', 1, 75, 18.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (81, 'OR-208', 1, 30, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (82, 'OR-227', 1, 34, 64.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (83, 'OR-208', 1, 30, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (89, 'FR-108', 2, 3, 32.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (89, 'FR-3', 6, 15, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (89, 'FR-42', 4, 12, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (89, 'FR-66', 1, 5, 49.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (89, 'FR-87', 3, 4, 22.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (89, 'OR-157', 5, 8, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (90, 'AR-001', 1, 19, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (90, 'AR-002', 2, 10, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (90, 'AR-003', 3, 12, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (91, 'FR-100', 1, 52, 11.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (91, 'FR-101', 2, 14, 13.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (91, 'FR-102', 3, 35, 18.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (92, 'FR-108', 1, 12, 23.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (92, 'FR-11', 2, 20, 100.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (92, 'FR-12', 3, 30, 21.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (93, 'FR-54', 1, 25, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (93, 'FR-58', 2, 51, 11.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (93, 'FR-60', 3, 3, 32.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (94, '11679', 1, 12, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (94, 'FR-11', 3, 33, 100.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (94, 'FR-4', 2, 79, 29.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (95, 'FR-10', 2, 9, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (95, 'FR-75', 1, 6, 32.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (95, 'FR-82', 3, 5, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (96, 'FR-43', 1, 6, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (96, 'FR-6', 4, 16, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (96, 'FR-71', 3, 10, 22.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (96, 'FR-90', 2, 4, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (97, 'FR-41', 1, 12, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (97, 'FR-54', 2, 14, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (97, 'OR-156', 3, 10, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (98, 'FR-33', 4, 14, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (98, 'FR-56', 3, 16, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (98, 'FR-60', 1, 8, 32.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (98, 'FR-8', 5, 18, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (98, 'FR-85', 2, 6, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (99, 'OR-157', 2, 15, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (99, 'OR-227', 1, 30, 64.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (100, 'FR-87', 1, 20, 22.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (100, 'FR-94', 2, 40, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (101, 'AR-006', 1, 50, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (101, 'AR-009', 2, 159, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (102, '22225', 2, 32, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (102, '30310', 1, 23, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (103, 'FR-53', 2, 12, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (103, 'OR-208', 1, 52, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (104, 'FR-85', 1, 9, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (104, 'OR-157', 2, 113, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (105, 'OR-227', 2, 21, 64.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (105, 'OR-240', 1, 27, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (106, 'AR-009', 1, 231, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (106, 'OR-136', 2, 47, 18.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (107, '30310', 2, 143, 12.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (107, 'FR-11', 1, 15, 100.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (108, 'FR-53', 1, 53, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (108, 'OR-208', 2, 59, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (109, 'FR-22', 5, 8, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (109, 'FR-36', 3, 12, 9.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (109, 'FR-45', 4, 14, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (109, 'OR-104', 1, 20, 10.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (109, 'OR-119', 2, 10, 5.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (109, 'OR-125', 6, 3, 5.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (109, 'OR-130', 7, 2, 18.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (110, 'AR-010', 3, 6, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (110, 'FR-1', 1, 14, 7.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (110, 'FR-16', 2, 1, 45.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (111, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (112, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (113, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (114, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (115, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (116, '21636', 1, 5, 14.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (116, 'AR-001', 2, 32, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (116, 'AR-005', 5, 18, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (116, 'FR-33', 3, 13, 8.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (116, 'OR-200', 4, 10, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (117, 'FR-78', 1, 2, 15.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (117, 'FR-80', 3, 1, 32.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (117, 'OR-146', 2, 17, 4.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (117, 'OR-179', 4, 4, 6.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (118, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (119, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (120, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (121, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (122, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (123, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (124, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (125, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (126, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (127, 'FR-67', 1, 10, 70.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (128, 'AR-004', 1, 15, 1.00);
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad) VALUES (128, 'OR-150', 2, 18, 2.00);
GO

-- stg_control_carga: 7 filas (bitácora de la carga)
INSERT INTO dbo.stg_control_carga (Tabla_Origen, Tabla_Staging, Filas_Origen, Filas_Staging, Resultado) VALUES ('oficina', 'stg_oficina', 9, 9, 'OK');
INSERT INTO dbo.stg_control_carga (Tabla_Origen, Tabla_Staging, Filas_Origen, Filas_Staging, Resultado) VALUES ('empleado', 'stg_empleado', 31, 31, 'OK');
INSERT INTO dbo.stg_control_carga (Tabla_Origen, Tabla_Staging, Filas_Origen, Filas_Staging, Resultado) VALUES ('Categoria_producto', 'stg_categoria_producto', 5, 5, 'OK');
INSERT INTO dbo.stg_control_carga (Tabla_Origen, Tabla_Staging, Filas_Origen, Filas_Staging, Resultado) VALUES ('cliente', 'stg_cliente', 36, 36, 'OK');
INSERT INTO dbo.stg_control_carga (Tabla_Origen, Tabla_Staging, Filas_Origen, Filas_Staging, Resultado) VALUES ('pedido', 'stg_pedido', 115, 115, 'OK');
INSERT INTO dbo.stg_control_carga (Tabla_Origen, Tabla_Staging, Filas_Origen, Filas_Staging, Resultado) VALUES ('producto', 'stg_producto', 276, 276, 'OK');
INSERT INTO dbo.stg_control_carga (Tabla_Origen, Tabla_Staging, Filas_Origen, Filas_Staging, Resultado) VALUES ('detalle_pedido', 'stg_detalle_pedido', 318, 318, 'OK');
GO
