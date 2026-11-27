/* =====================================================================
   04_Crear_DataMart.sql
   EA3 - Proceso ETL Jardinería | DATA MART FINAL (modelo estrella)
   Crea DM_Ventas_Jardineria: 6 dimensiones + Hechos_Ventas.
   Grano: una fila de Hechos_Ventas = un producto dentro de un pedido.
   - Claves sustitutas SK_ propias del data mart (las asigna el script 05).
   - Cada dimensión guarda su clave natural (ID_) para rastrear el origen.
   - Miembro desconocido SK = -1 en cada dimensión (lo inserta el 05).
   ===================================================================== */
USE master;
GO
IF DB_ID('DM_Ventas_Jardineria') IS NOT NULL ALTER DATABASE DM_Ventas_Jardineria SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE IF EXISTS DM_Ventas_Jardineria;
GO
CREATE DATABASE DM_Ventas_Jardineria;
GO
USE DM_Ventas_Jardineria;
GO

CREATE TABLE dbo.Dim_Tiempo (
    SK_Tiempo    INT         NOT NULL,   -- AAAAMMDD
    Fecha        DATE        NULL,
    Anio         SMALLINT    NOT NULL,
    Trimestre    TINYINT     NOT NULL,
    Mes          TINYINT     NOT NULL,
    Nombre_Mes   VARCHAR(15) NOT NULL,
    Dia          TINYINT     NOT NULL,
    Nombre_Dia   VARCHAR(15) NOT NULL,
    Semana_Anio  TINYINT     NOT NULL,
    Fin_Semana   VARCHAR(2)  NOT NULL,
    CONSTRAINT PK_Dim_Tiempo PRIMARY KEY (SK_Tiempo)
);

CREATE TABLE dbo.Dim_Producto (
    SK_Producto      INT           NOT NULL,
    ID_Producto      INT           NOT NULL,
    Codigo_Producto  VARCHAR(15)   NOT NULL,
    Nombre_Producto  VARCHAR(70)   NOT NULL,
    ID_Categoria     INT           NOT NULL,
    Desc_Categoria   VARCHAR(50)   NOT NULL,
    Proveedor        VARCHAR(50)   NOT NULL,
    Dimensiones      VARCHAR(25)   NOT NULL,
    Precio_Venta     NUMERIC(15,2) NOT NULL,
    Precio_Proveedor NUMERIC(15,2) NULL,
    Margen_Unitario  NUMERIC(15,2) NULL,
    CONSTRAINT PK_Dim_Producto PRIMARY KEY (SK_Producto),
    CONSTRAINT UQ_Dim_Producto_ID UNIQUE (ID_Producto)
);

CREATE TABLE dbo.Dim_Cliente (
    SK_Cliente      INT           NOT NULL,
    ID_Cliente      INT           NOT NULL,
    Nombre_Cliente  VARCHAR(50)   NOT NULL,
    Ciudad          VARCHAR(50)   NOT NULL,
    Region          VARCHAR(50)   NOT NULL,
    Pais            VARCHAR(50)   NOT NULL,
    Limite_Credito  NUMERIC(15,2) NOT NULL,
    CONSTRAINT PK_Dim_Cliente PRIMARY KEY (SK_Cliente),
    CONSTRAINT UQ_Dim_Cliente_ID UNIQUE (ID_Cliente)
);

CREATE TABLE dbo.Dim_Empleado (
    SK_Empleado     INT          NOT NULL,
    ID_Empleado     INT          NOT NULL,
    Nombre_Completo VARCHAR(100) NOT NULL,
    Puesto          VARCHAR(50)  NOT NULL,
    Email           VARCHAR(100) NOT NULL,
    Jefe            VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Dim_Empleado PRIMARY KEY (SK_Empleado),
    CONSTRAINT UQ_Dim_Empleado_ID UNIQUE (ID_Empleado)
);

CREATE TABLE dbo.Dim_Oficina (
    SK_Oficina     INT         NOT NULL,
    ID_Oficina     INT         NOT NULL,
    Descripcion    VARCHAR(10) NOT NULL,
    Ciudad         VARCHAR(30) NOT NULL,
    Region         VARCHAR(50) NOT NULL,
    Pais           VARCHAR(50) NOT NULL,
    Codigo_Postal  VARCHAR(10) NOT NULL,
    CONSTRAINT PK_Dim_Oficina PRIMARY KEY (SK_Oficina),
    CONSTRAINT UQ_Dim_Oficina_ID UNIQUE (ID_Oficina)
);

CREATE TABLE dbo.Dim_Pedido (
    SK_Pedido         INT          NOT NULL,
    ID_Pedido         INT          NOT NULL,
    Estado            VARCHAR(15)  NOT NULL,
    Fecha_Esperada    DATE         NULL,
    Fecha_Entrega     DATE         NULL,
    Entrega_A_Tiempo  VARCHAR(10)  NOT NULL,   -- Sí / No / No aplica
    Dias_Retraso      INT          NULL,
    Calidad_Fechas    VARCHAR(200) NOT NULL,   -- OK o la inconsistencia encontrada
    CONSTRAINT PK_Dim_Pedido PRIMARY KEY (SK_Pedido),
    CONSTRAINT UQ_Dim_Pedido_ID UNIQUE (ID_Pedido)
);

CREATE TABLE dbo.Hechos_Ventas (
    SK_Venta          BIGINT IDENTITY(1,1) NOT NULL,
    SK_Tiempo         INT           NOT NULL,
    SK_Producto       INT           NOT NULL,
    SK_Cliente        INT           NOT NULL,
    SK_Empleado       INT           NOT NULL,
    SK_Oficina        INT           NOT NULL,
    SK_Pedido         INT           NOT NULL,
    ID_Detalle_Pedido INT           NOT NULL,   -- rastreo a la línea de origen
    Numero_Linea      SMALLINT      NOT NULL,   -- atributo degenerado
    Cantidad          INT           NOT NULL,
    Precio_Unitario   NUMERIC(15,2) NOT NULL,
    Importe_Linea     NUMERIC(15,2) NOT NULL,
    Costo_Linea       NUMERIC(15,2) NULL,
    Margen_Linea      NUMERIC(15,2) NULL,
    CONSTRAINT PK_Hechos_Ventas PRIMARY KEY (SK_Venta),
    CONSTRAINT FK_Hechos_Tiempo   FOREIGN KEY (SK_Tiempo)   REFERENCES dbo.Dim_Tiempo (SK_Tiempo),
    CONSTRAINT FK_Hechos_Producto FOREIGN KEY (SK_Producto) REFERENCES dbo.Dim_Producto (SK_Producto),
    CONSTRAINT FK_Hechos_Cliente  FOREIGN KEY (SK_Cliente)  REFERENCES dbo.Dim_Cliente (SK_Cliente),
    CONSTRAINT FK_Hechos_Empleado FOREIGN KEY (SK_Empleado) REFERENCES dbo.Dim_Empleado (SK_Empleado),
    CONSTRAINT FK_Hechos_Oficina  FOREIGN KEY (SK_Oficina)  REFERENCES dbo.Dim_Oficina (SK_Oficina),
    CONSTRAINT FK_Hechos_Pedido   FOREIGN KEY (SK_Pedido)   REFERENCES dbo.Dim_Pedido (SK_Pedido),
    CONSTRAINT UQ_Hechos_Pedido_Producto UNIQUE (SK_Pedido, SK_Producto),
    CONSTRAINT UQ_Hechos_Detalle UNIQUE (ID_Detalle_Pedido),
    CONSTRAINT CK_Hechos_Cantidad CHECK (Cantidad > 0)
);

-- Índices para las consultas de análisis más comunes
CREATE INDEX IX_Hechos_Tiempo   ON dbo.Hechos_Ventas (SK_Tiempo);
CREATE INDEX IX_Hechos_Producto ON dbo.Hechos_Ventas (SK_Producto);
CREATE INDEX IX_Hechos_Cliente  ON dbo.Hechos_Ventas (SK_Cliente);
GO

PRINT 'DM_Ventas_Jardineria creado: 6 dimensiones y Hechos_Ventas.';
GO
