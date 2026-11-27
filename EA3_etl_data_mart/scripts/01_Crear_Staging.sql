/* =====================================================================
   01_Crear_Staging.sql
   EA3 - Proceso ETL Jardinería | Base de datos STAGING
   Crea (o vuelve a crear) Staging_Jardineria con:
     - 7 tablas stg_  : copia de los datos del origen (extracción).
     - 7 tablas tr_   : datos ya transformados, con la forma del modelo estrella.
     - stg_control_carga : bitácora de cada etapa del ETL.
     - dbo.fn_LimpiarTexto : función de limpieza de textos.
   Reglas de staging: sin claves foráneas, clave primaria = clave natural
   del origen y Fecha_Carga en cada tabla stg_.
   Orden de ejecución: 00 -> 01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07
   ===================================================================== */
USE master;
GO
IF DB_ID('Staging_Jardineria') IS NOT NULL ALTER DATABASE Staging_Jardineria SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE IF EXISTS Staging_Jardineria;
GO
CREATE DATABASE Staging_Jardineria;
GO
USE Staging_Jardineria;
GO

/* ---------------------------------------------------------------------
   1. Tablas stg_ (extracción). Solo las columnas que usa el modelo
      estrella. La tabla pago no se extrae: su grano (pago por cliente)
      no encaja con la tabla de hechos (línea de pedido).
   --------------------------------------------------------------------- */
CREATE TABLE dbo.stg_oficina (
    ID_oficina      INT          NOT NULL PRIMARY KEY,
    Descripcion     VARCHAR(10)  NULL,
    ciudad          VARCHAR(30)  NULL,
    pais            VARCHAR(50)  NULL,
    region          VARCHAR(50)  NULL,
    codigo_postal   VARCHAR(10)  NULL,
    Fecha_Carga     DATETIME     NOT NULL DEFAULT GETDATE()
);

CREATE TABLE dbo.stg_empleado (
    ID_empleado     INT          NOT NULL PRIMARY KEY,
    nombre          VARCHAR(50)  NULL,
    apellido1       VARCHAR(50)  NULL,
    apellido2       VARCHAR(50)  NULL,
    email           VARCHAR(100) NULL,
    ID_oficina      INT          NULL,
    ID_jefe         INT          NULL,
    puesto          VARCHAR(50)  NULL,
    Fecha_Carga     DATETIME     NOT NULL DEFAULT GETDATE()
);

CREATE TABLE dbo.stg_categoria (
    Id_Categoria    INT          NOT NULL PRIMARY KEY,
    Desc_Categoria  VARCHAR(50)  NULL,
    Fecha_Carga     DATETIME     NOT NULL DEFAULT GETDATE()
);

CREATE TABLE dbo.stg_cliente (
    ID_cliente              INT           NOT NULL PRIMARY KEY,
    nombre_cliente          VARCHAR(50)   NULL,
    ciudad                  VARCHAR(50)   NULL,
    region                  VARCHAR(50)   NULL,
    pais                    VARCHAR(50)   NULL,
    codigo_postal           VARCHAR(10)   NULL,
    ID_empleado_rep_ventas  INT           NULL,
    limite_credito          NUMERIC(15,2) NULL,
    Fecha_Carga             DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE dbo.stg_pedido (
    ID_pedido       INT          NOT NULL PRIMARY KEY,
    fecha_pedido    DATE         NULL,
    fecha_esperada  DATE         NULL,
    fecha_entrega   DATE         NULL,
    estado          VARCHAR(15)  NULL,
    ID_cliente      INT          NULL,
    Observacion     VARCHAR(200) NULL,   -- la llena la transformación (calidad de fechas)
    Fecha_Carga     DATETIME     NOT NULL DEFAULT GETDATE()
);

CREATE TABLE dbo.stg_producto (
    ID_producto       INT           NOT NULL PRIMARY KEY,
    CodigoProducto    VARCHAR(15)   NULL,
    nombre            VARCHAR(70)   NULL,
    Categoria         INT           NULL,
    dimensiones       VARCHAR(25)   NULL,
    proveedor         VARCHAR(50)   NULL,
    cantidad_en_stock SMALLINT      NULL,
    precio_venta      NUMERIC(15,2) NULL,
    precio_proveedor  NUMERIC(15,2) NULL,
    Fecha_Carga       DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE dbo.stg_detalle_pedido (
    ID_detalle_pedido INT           NOT NULL PRIMARY KEY,
    ID_pedido         INT           NULL,
    ID_producto       INT           NULL,
    cantidad          INT           NULL,
    precio_unidad     NUMERIC(15,2) NULL,
    numero_linea      SMALLINT      NULL,
    Observacion       VARCHAR(200)  NULL,   -- la llena la transformación (duplicados)
    Fecha_Carga       DATETIME      NOT NULL DEFAULT GETDATE()
);

/* ---------------------------------------------------------------------
   2. Tablas tr_ (transformación). Tienen la misma forma que las tablas
      del data mart, pero con claves naturales. La carga final solo
      asigna las claves sustitutas.
   --------------------------------------------------------------------- */
CREATE TABLE dbo.tr_dim_tiempo (
    SK_Tiempo    INT         NOT NULL PRIMARY KEY,   -- AAAAMMDD
    Fecha        DATE        NOT NULL,
    Anio         SMALLINT    NOT NULL,
    Trimestre    TINYINT     NOT NULL,
    Mes          TINYINT     NOT NULL,
    Nombre_Mes   VARCHAR(15) NOT NULL,
    Dia          TINYINT     NOT NULL,
    Nombre_Dia   VARCHAR(15) NOT NULL,
    Semana_Anio  TINYINT     NOT NULL,
    Fin_Semana   VARCHAR(2)  NOT NULL
);

CREATE TABLE dbo.tr_dim_producto (
    ID_Producto      INT           NOT NULL PRIMARY KEY,
    Codigo_Producto  VARCHAR(15)   NOT NULL,
    Nombre_Producto  VARCHAR(70)   NOT NULL,
    ID_Categoria     INT           NOT NULL,
    Desc_Categoria   VARCHAR(50)   NOT NULL,
    Proveedor        VARCHAR(50)   NOT NULL,
    Dimensiones      VARCHAR(25)   NOT NULL,
    Precio_Venta     NUMERIC(15,2) NOT NULL,
    Precio_Proveedor NUMERIC(15,2) NULL,
    Margen_Unitario  NUMERIC(15,2) NULL
);

CREATE TABLE dbo.tr_dim_cliente (
    ID_Cliente      INT           NOT NULL PRIMARY KEY,
    Nombre_Cliente  VARCHAR(50)   NOT NULL,
    Ciudad          VARCHAR(50)   NOT NULL,
    Region          VARCHAR(50)   NOT NULL,
    Pais            VARCHAR(50)   NOT NULL,
    Limite_Credito  NUMERIC(15,2) NOT NULL
);

CREATE TABLE dbo.tr_dim_empleado (
    ID_Empleado     INT          NOT NULL PRIMARY KEY,
    Nombre_Completo VARCHAR(100) NOT NULL,
    Puesto          VARCHAR(50)  NOT NULL,
    Email           VARCHAR(100) NOT NULL,
    Jefe            VARCHAR(100) NOT NULL
);

CREATE TABLE dbo.tr_dim_oficina (
    ID_Oficina     INT         NOT NULL PRIMARY KEY,
    Descripcion    VARCHAR(10) NOT NULL,
    Ciudad         VARCHAR(30) NOT NULL,
    Region         VARCHAR(50) NOT NULL,
    Pais           VARCHAR(50) NOT NULL,
    Codigo_Postal  VARCHAR(10) NOT NULL
);

CREATE TABLE dbo.tr_dim_pedido (
    ID_Pedido         INT          NOT NULL PRIMARY KEY,
    Estado            VARCHAR(15)  NOT NULL,
    Fecha_Pedido      DATE         NOT NULL,
    Fecha_Esperada    DATE         NULL,
    Fecha_Entrega     DATE         NULL,
    Entrega_A_Tiempo  VARCHAR(10)  NOT NULL,
    Dias_Retraso      INT          NULL,
    Calidad_Fechas    VARCHAR(200) NOT NULL
);

CREATE TABLE dbo.tr_hechos_ventas (
    ID_Detalle_Pedido INT           NOT NULL PRIMARY KEY,
    ID_Pedido         INT           NOT NULL,
    ID_Producto       INT           NOT NULL,
    ID_Cliente        INT           NOT NULL,
    ID_Empleado       INT           NULL,
    ID_Oficina        INT           NULL,
    SK_Tiempo         INT           NOT NULL,
    Numero_Linea      SMALLINT      NOT NULL,
    Cantidad          INT           NOT NULL,
    Precio_Unitario   NUMERIC(15,2) NOT NULL,
    Importe_Linea     NUMERIC(15,2) NOT NULL,
    Costo_Linea       NUMERIC(15,2) NULL,
    Margen_Linea      NUMERIC(15,2) NULL
);

/* ---------------------------------------------------------------------
   3. Bitácora del ETL
   --------------------------------------------------------------------- */
CREATE TABLE dbo.stg_control_carga (
    ID_Control      INT IDENTITY(1,1) PRIMARY KEY,
    Etapa           VARCHAR(30)  NOT NULL,   -- Extracción / Transformación / Carga
    Tabla           VARCHAR(50)  NOT NULL,
    Filas_Origen    INT          NULL,
    Filas_Destino   INT          NULL,
    Resultado       VARCHAR(10)  NOT NULL,   -- OK / REVISAR
    Fecha_Ejecucion DATETIME     NOT NULL DEFAULT GETDATE()
);
GO

/* ---------------------------------------------------------------------
   4. Función de limpieza de textos (se usa en el script 03):
      quita espacios sobrantes (al inicio, al final y repetidos),
      repara tildes mal codificadas (texto UTF-8 leído como ANSI,
      p. ej. 'EspaÃ±a' -> 'España'), quita la barra de las comillas
      escapadas (\" -> ") y convierte la cadena vacía en NULL.
      Se usa COLLATE Latin1_General_BIN2 (comparación exacta) porque en
      una intercalación que no distingue tildes (por ejemplo
      Latin1_General_CI_AI) 'Ã' sería igual a 'a' y se dañarían palabras.
   --------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION dbo.fn_LimpiarTexto (@texto VARCHAR(4000))
RETURNS VARCHAR(4000)
AS
BEGIN
    DECLARE @t VARCHAR(4000) = LTRIM(RTRIM(@texto));
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ã±', 'ñ');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ã‘', 'Ñ');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ã¡', 'á');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ã©', 'é');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ã' + CHAR(173), 'í');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ã³', 'ó');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ãº', 'ú');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ã‰', 'É');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ã“', 'Ó');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ãš', 'Ú');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ã¼', 'ü');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ã§', 'ç');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Ã¨', 'è');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Âª', 'ª');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, 'Âº', 'º');
    SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, '\"', '"');            -- comillas escapadas al estilo MySQL
    WHILE CHARINDEX('  ', @t COLLATE Latin1_General_BIN2) > 0                -- espacios dobles o triples -> uno
        SET @t = REPLACE(@t COLLATE Latin1_General_BIN2, '  ', ' ');
    RETURN NULLIF(@t, '');
END;
GO

PRINT 'Staging_Jardineria creada: 7 tablas stg_, 7 tablas tr_, stg_control_carga y fn_LimpiarTexto.';
GO
