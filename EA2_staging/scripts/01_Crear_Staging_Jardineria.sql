/* =====================================================================
   01_Crear_Staging_Jardineria.sql
   Crea la base de datos Staging_Jardineria y sus tablas (SQL Server).

   Criterios de diseño:
   - Una tabla stg_ por cada tabla de Jardinería que alimenta el modelo
     estrella de la entrega 1. La tabla pago no se traslada.
   - Solo se copian las columnas que usa el modelo estrella.
   - Las tablas no tienen claves foráneas: la integridad se revisa con el
     script 03 y no bloquea la carga.
   - Cada tabla conserva la clave primaria de origen, para impedir filas
     duplicadas, y agrega la columna Fecha_Carga para auditoría.
   - stg_control_carga registra cuántas filas había en el origen y cuántas
     quedaron en Staging en cada ejecución.
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

PRINT 'Base de datos Staging_Jardineria creada con 8 tablas.';
GO
