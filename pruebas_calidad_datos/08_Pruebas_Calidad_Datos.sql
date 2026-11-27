/* =====================================================================
   08_Pruebas_Calidad_Datos.sql
   EA4 - Proyecto integrador | PRUEBAS DE VERIFICACIÓN DE CALIDAD DE DATOS
   Revisa la calidad de los datos en las tres capas del proyecto:
     1. Origen     -> jardineria            (diagnóstico de la fuente)
     2. Staging    -> Staging_Jardineria    (después de limpiar y transformar)
     3. Data mart  -> DM_Ventas_Jardineria  (resultado final del ETL)
   Cada prueba cuenta cuántas filas tienen el problema:
     - 0 filas            -> OK
     - más de 0 en origen  -> HALLAZGO (problema de la fuente; la columna
                              Detalle dice cómo lo trató el ETL)
     - más de 0 en staging
       o data mart         -> FALLA (el ETL no lo corrigió)
   Dimensiones de calidad: completitud, validez, unicidad, integridad
   referencial, exactitud, consistencia, formato y trazabilidad.
   Los resultados quedan guardados en DM_Ventas_Jardineria.dbo.Calidad_Datos.
   Requisito: haber ejecutado antes los scripts 00 a 05 de la EA3.
   Nota: el servidor usa la intercalación Latin1_General_CI_AI (no distingue
   tildes ni mayúsculas); por eso las pruebas de formato comparan con
   COLLATE Latin1_General_BIN2.
   ===================================================================== */
USE DM_Ventas_Jardineria;
GO
SET NOCOUNT ON;

IF OBJECT_ID('dbo.Calidad_Datos', 'U') IS NULL
    CREATE TABLE dbo.Calidad_Datos (
        ID_Prueba       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Fecha_Ejecucion DATETIME      NOT NULL,
        Capa            VARCHAR(15)   NOT NULL,
        Dimension       VARCHAR(25)   NOT NULL,
        Prueba          VARCHAR(100)  NOT NULL,
        Tabla           VARCHAR(60)   NOT NULL,
        Filas_Revisadas INT           NOT NULL,
        Filas_Problema  INT           NOT NULL,
        Calidad_Pct     DECIMAL(5,1)  NOT NULL,
        Resultado       VARCHAR(10)   NOT NULL,
        Detalle         VARCHAR(150)  NULL
    );
GO

DECLARE @Ahora DATETIME = GETDATE();

DECLARE @P TABLE (
    Orden           INT,
    Capa            VARCHAR(15),
    Dimension       VARCHAR(25),
    Prueba          VARCHAR(100),
    Tabla           VARCHAR(60),
    Filas_Revisadas INT,
    Filas_Problema  INT,
    Detalle         VARCHAR(150)
);

/* ---------------------------------------------------------------------
   CAPA 1. ORIGEN (jardineria): qué problemas trae la fuente
   --------------------------------------------------------------------- */
INSERT INTO @P (Orden, Capa, Dimension, Prueba, Tabla, Filas_Revisadas, Filas_Problema, Detalle)
SELECT  1, '1. Origen', 'Completitud', 'Clientes sin región', 'cliente',
       (SELECT COUNT(*) FROM jardineria.dbo.cliente),
       (SELECT COUNT(*) FROM jardineria.dbo.cliente WHERE region IS NULL OR LTRIM(RTRIM(region)) = ''),
       'El ETL guarda ''Sin dato'' en Dim_Cliente.Region'
UNION ALL
SELECT  2, '1. Origen', 'Completitud', 'Productos sin dimensiones', 'producto',
       (SELECT COUNT(*) FROM jardineria.dbo.producto),
       (SELECT COUNT(*) FROM jardineria.dbo.producto WHERE dimensiones IS NULL OR LTRIM(RTRIM(dimensiones)) = ''),
       'El ETL guarda ''Sin dato'' en Dim_Producto.Dimensiones'
UNION ALL
SELECT  3, '1. Origen', 'Completitud', 'Pedidos sin líneas de detalle', 'pedido',
       (SELECT COUNT(*) FROM jardineria.dbo.pedido),
       (SELECT COUNT(*) FROM jardineria.dbo.pedido p
        WHERE NOT EXISTS (SELECT 1 FROM jardineria.dbo.detalle_pedido d WHERE d.ID_pedido = p.ID_pedido)),
       'Quedan en Dim_Pedido pero no generan hechos (no tienen ventas)'
UNION ALL
SELECT  4, '1. Origen', 'Completitud', 'Pedidos entregados sin fecha de entrega', 'pedido',
       (SELECT COUNT(*) FROM jardineria.dbo.pedido),
       (SELECT COUNT(*) FROM jardineria.dbo.pedido
        WHERE UPPER(LTRIM(RTRIM(estado))) = 'ENTREGADO' AND fecha_entrega IS NULL),
       'Se marcan en Observacion y pasan a Dim_Pedido.Calidad_Fechas'
UNION ALL
SELECT  5, '1. Origen', 'Validez', 'Fecha esperada o de entrega antes del pedido', 'pedido',
       (SELECT COUNT(*) FROM jardineria.dbo.pedido),
       (SELECT COUNT(*) FROM jardineria.dbo.pedido
        WHERE fecha_esperada < fecha_pedido OR fecha_entrega < fecha_pedido),
       'Se marcan en Observacion y pasan a Dim_Pedido.Calidad_Fechas'
UNION ALL
SELECT  6, '1. Origen', 'Consistencia', 'Pedidos no entregados con fecha de entrega', 'pedido',
       (SELECT COUNT(*) FROM jardineria.dbo.pedido),
       (SELECT COUNT(*) FROM jardineria.dbo.pedido
        WHERE UPPER(LTRIM(RTRIM(estado))) <> 'ENTREGADO' AND fecha_entrega IS NOT NULL),
       'Se marcan en Observacion y pasan a Dim_Pedido.Calidad_Fechas'
UNION ALL
SELECT  7, '1. Origen', 'Unicidad', 'Líneas de pedido repetidas', 'detalle_pedido',
       (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido),
       (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido)
       - (SELECT COUNT(*) FROM (SELECT DISTINCT ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea
                                FROM jardineria.dbo.detalle_pedido) AS x),
       'El ETL deja la primera y excluye la repetida'
UNION ALL
SELECT  8, '1. Origen', 'Integridad referencial', 'Referencias a registros que no existen', '6 relaciones',
       (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido) * 2
       + (SELECT COUNT(*) FROM jardineria.dbo.pedido)
       + (SELECT COUNT(*) FROM jardineria.dbo.cliente)
       + (SELECT COUNT(*) FROM jardineria.dbo.empleado)
       + (SELECT COUNT(*) FROM jardineria.dbo.producto),
       (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido d
        WHERE NOT EXISTS (SELECT 1 FROM jardineria.dbo.pedido p WHERE p.ID_pedido = d.ID_pedido))
       + (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido d
          WHERE NOT EXISTS (SELECT 1 FROM jardineria.dbo.producto p WHERE p.ID_producto = d.ID_producto))
       + (SELECT COUNT(*) FROM jardineria.dbo.pedido p
          WHERE NOT EXISTS (SELECT 1 FROM jardineria.dbo.cliente c WHERE c.ID_cliente = p.ID_cliente))
       + (SELECT COUNT(*) FROM jardineria.dbo.cliente c
          WHERE c.ID_empleado_rep_ventas IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM jardineria.dbo.empleado e WHERE e.ID_empleado = c.ID_empleado_rep_ventas))
       + (SELECT COUNT(*) FROM jardineria.dbo.empleado e
          WHERE NOT EXISTS (SELECT 1 FROM jardineria.dbo.oficina o WHERE o.ID_oficina = e.ID_oficina))
       + (SELECT COUNT(*) FROM jardineria.dbo.producto p
          WHERE NOT EXISTS (SELECT 1 FROM jardineria.dbo.Categoria_producto k WHERE k.Id_Categoria = p.Categoria)),
       'Detalle-pedido, detalle-producto, pedido-cliente, cliente-empleado, empleado-oficina, producto-categoría'
UNION ALL
SELECT  9, '1. Origen', 'Validez', 'Cantidad o precio en cero o negativo', 'detalle_pedido',
       (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido),
       (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido WHERE cantidad <= 0 OR precio_unidad <= 0),
       NULL
UNION ALL
SELECT 10, '1. Origen', 'Exactitud', 'Líneas vendidas por debajo del costo', 'detalle_pedido',
       (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido),
       (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido d
        JOIN jardineria.dbo.producto p ON p.ID_producto = d.ID_producto
        WHERE d.precio_unidad < p.precio_proveedor),
       'Se conservan: son ventas reales; el margen de esas líneas queda negativo'
UNION ALL
SELECT 11, '1. Origen', 'Formato', 'País escrito de forma no estándar', 'cliente, oficina',
       (SELECT COUNT(*) FROM jardineria.dbo.cliente) + (SELECT COUNT(*) FROM jardineria.dbo.oficina),
       (SELECT COUNT(*) FROM jardineria.dbo.cliente
        WHERE pais COLLATE Latin1_General_BIN2 NOT IN ('España', 'Estados Unidos', 'Reino Unido', 'Francia', 'Australia', 'Japón'))
       + (SELECT COUNT(*) FROM jardineria.dbo.oficina
          WHERE pais COLLATE Latin1_General_BIN2 NOT IN ('España', 'Estados Unidos', 'Reino Unido', 'Francia', 'Australia', 'Japón')),
       'Spain, USA, EEUU, Inglaterra...: el script 03 los normaliza'
UNION ALL
SELECT 12, '1. Origen', 'Formato', 'Nombres de producto con espacios sobrantes', 'producto',
       (SELECT COUNT(*) FROM jardineria.dbo.producto),
       (SELECT COUNT(*) FROM jardineria.dbo.producto
        WHERE DATALENGTH(nombre) <> DATALENGTH(LTRIM(RTRIM(nombre))) OR CHARINDEX('  ', nombre) > 0),
       'fn_LimpiarTexto los quita en el script 03'
UNION ALL
SELECT 13, '1. Origen', 'Formato', 'Textos con tildes dañadas (Ã)', 'producto, cliente',
       (SELECT COUNT(*) FROM jardineria.dbo.producto) + (SELECT COUNT(*) FROM jardineria.dbo.cliente),
       (SELECT COUNT(*) FROM jardineria.dbo.producto
        WHERE nombre COLLATE Latin1_General_BIN2 LIKE '%Ã%'
           OR proveedor COLLATE Latin1_General_BIN2 LIKE '%Ã%'
           OR dimensiones COLLATE Latin1_General_BIN2 LIKE '%Ã%')
       + (SELECT COUNT(*) FROM jardineria.dbo.cliente
          WHERE nombre_cliente COLLATE Latin1_General_BIN2 LIKE '%Ã%'
             OR ciudad COLLATE Latin1_General_BIN2 LIKE '%Ã%'),
       'fn_LimpiarTexto las repara en el script 03';

/* ---------------------------------------------------------------------
   CAPA 2. STAGING (Staging_Jardineria): ¿la limpieza funcionó?
   --------------------------------------------------------------------- */
INSERT INTO @P (Orden, Capa, Dimension, Prueba, Tabla, Filas_Revisadas, Filas_Problema, Detalle)
SELECT 14, '2. Staging', 'Formato', 'País fuera de la lista oficial', 'stg_cliente, stg_oficina',
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_cliente) + (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_oficina),
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_cliente
        WHERE pais COLLATE Latin1_General_BIN2 NOT IN ('España', 'Estados Unidos', 'Reino Unido', 'Francia', 'Australia', 'Japón'))
       + (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_oficina
          WHERE pais COLLATE Latin1_General_BIN2 NOT IN ('España', 'Estados Unidos', 'Reino Unido', 'Francia', 'Australia', 'Japón')),
       NULL
UNION ALL
SELECT 15, '2. Staging', 'Validez', 'Estado del pedido fuera de la lista', 'stg_pedido',
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_pedido),
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_pedido
        WHERE estado IS NULL
           OR estado COLLATE Latin1_General_BIN2 NOT IN ('Entregado', 'Pendiente', 'Rechazado')),
       'Valores permitidos: Entregado, Pendiente, Rechazado'
UNION ALL
SELECT 16, '2. Staging', 'Consistencia', 'Pedidos con fechas que no cuadran y sin marcar', 'stg_pedido',
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_pedido),
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_pedido
        WHERE Observacion IS NULL
          AND (   fecha_esperada < fecha_pedido
               OR fecha_entrega  < fecha_pedido
               OR (estado = 'Entregado'  AND fecha_entrega IS NULL)
               OR (estado <> 'Entregado' AND fecha_entrega IS NOT NULL))),
       'Todo pedido con fechas raras debe quedar marcado en Observacion'
UNION ALL
SELECT 17, '2. Staging', 'Unicidad', 'Líneas repetidas que no se marcaron para excluir', 'stg_detalle_pedido',
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_detalle_pedido),
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_detalle_pedido WHERE Observacion IS NULL)
       - (SELECT COUNT(*) FROM (SELECT DISTINCT ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea
                                FROM Staging_Jardineria.dbo.stg_detalle_pedido
                                WHERE Observacion IS NULL) AS x),
       NULL
UNION ALL
SELECT 18, '2. Staging', 'Formato', 'Textos con espacios sobrantes o tildes dañadas', 'stg_producto, stg_cliente',
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_producto) + (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_cliente),
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_producto
        WHERE DATALENGTH(nombre) <> DATALENGTH(LTRIM(RTRIM(nombre))) OR CHARINDEX('  ', nombre) > 0
           OR nombre COLLATE Latin1_General_BIN2 LIKE '%Ã%'
           OR proveedor COLLATE Latin1_General_BIN2 LIKE '%Ã%'
           OR dimensiones COLLATE Latin1_General_BIN2 LIKE '%Ã%')
       + (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_cliente
          WHERE DATALENGTH(nombre_cliente) <> DATALENGTH(LTRIM(RTRIM(nombre_cliente)))
             OR CHARINDEX('  ', nombre_cliente) > 0
             OR nombre_cliente COLLATE Latin1_General_BIN2 LIKE '%Ã%'
             OR ciudad COLLATE Latin1_General_BIN2 LIKE '%Ã%'),
       NULL;

/* ---------------------------------------------------------------------
   CAPA 3. DATA MART (DM_Ventas_Jardineria): ¿el resultado final es confiable?
   --------------------------------------------------------------------- */
DECLARE @Lineas_Origen  INT,
        @Unidades_Origen INT,
        @Importe_Origen  NUMERIC(15,2),
        @Lineas_DM       INT,
        @Unidades_DM     INT,
        @Importe_DM      NUMERIC(15,2);

-- Origen sin la línea repetida (es lo que debe llegar al data mart)
SELECT @Lineas_Origen   = COUNT(*),
       @Unidades_Origen = SUM(cantidad),
       @Importe_Origen  = SUM(cantidad * precio_unidad)
FROM (SELECT DISTINCT ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea
      FROM jardineria.dbo.detalle_pedido) AS x;

SELECT @Lineas_DM   = COUNT(*),
       @Unidades_DM = SUM(Cantidad),
       @Importe_DM  = SUM(Importe_Linea)
FROM dbo.Hechos_Ventas;

INSERT INTO @P (Orden, Capa, Dimension, Prueba, Tabla, Filas_Revisadas, Filas_Problema, Detalle)
SELECT 19, '3. Data mart', 'Completitud', 'Hechos con dimensión desconocida (-1)', 'Hechos_Ventas',
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas),
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas
        WHERE -1 IN (SK_Tiempo, SK_Producto, SK_Cliente, SK_Empleado, SK_Oficina, SK_Pedido)),
       NULL
UNION ALL
SELECT 20, '3. Data mart', 'Integridad referencial', 'Hechos sin su fila en alguna dimensión', 'Hechos_Ventas',
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas),
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas h
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Dim_Tiempo   d WHERE d.SK_Tiempo   = h.SK_Tiempo)
           OR NOT EXISTS (SELECT 1 FROM dbo.Dim_Producto d WHERE d.SK_Producto = h.SK_Producto)
           OR NOT EXISTS (SELECT 1 FROM dbo.Dim_Cliente  d WHERE d.SK_Cliente  = h.SK_Cliente)
           OR NOT EXISTS (SELECT 1 FROM dbo.Dim_Empleado d WHERE d.SK_Empleado = h.SK_Empleado)
           OR NOT EXISTS (SELECT 1 FROM dbo.Dim_Oficina  d WHERE d.SK_Oficina  = h.SK_Oficina)
           OR NOT EXISTS (SELECT 1 FROM dbo.Dim_Pedido   d WHERE d.SK_Pedido   = h.SK_Pedido)),
       NULL
UNION ALL
SELECT 21, '3. Data mart', 'Unicidad', 'Claves naturales repetidas en las dimensiones', '5 dimensiones',
       (SELECT COUNT(*) FROM dbo.Dim_Producto) + (SELECT COUNT(*) FROM dbo.Dim_Cliente)
       + (SELECT COUNT(*) FROM dbo.Dim_Empleado) + (SELECT COUNT(*) FROM dbo.Dim_Oficina)
       + (SELECT COUNT(*) FROM dbo.Dim_Pedido),
       (SELECT COUNT(*) - COUNT(DISTINCT ID_Producto) FROM dbo.Dim_Producto)
       + (SELECT COUNT(*) - COUNT(DISTINCT ID_Cliente) FROM dbo.Dim_Cliente)
       + (SELECT COUNT(*) - COUNT(DISTINCT ID_Empleado) FROM dbo.Dim_Empleado)
       + (SELECT COUNT(*) - COUNT(DISTINCT ID_Oficina) FROM dbo.Dim_Oficina)
       + (SELECT COUNT(*) - COUNT(DISTINCT ID_Pedido) FROM dbo.Dim_Pedido),
       'Producto, cliente, empleado, oficina y pedido'
UNION ALL
SELECT 22, '3. Data mart', 'Unicidad', 'Mismo producto repetido en un pedido', 'Hechos_Ventas',
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas),
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas)
       - (SELECT COUNT(*) FROM (SELECT DISTINCT SK_Pedido, SK_Producto FROM dbo.Hechos_Ventas) AS x),
       NULL
UNION ALL
SELECT 23, '3. Data mart', 'Validez', 'Cantidad o precio en cero o negativo', 'Hechos_Ventas',
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas),
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas WHERE Cantidad <= 0 OR Precio_Unitario <= 0),
       NULL
UNION ALL
SELECT 24, '3. Data mart', 'Validez', 'Días que faltan en el calendario', 'Dim_Tiempo',
       (SELECT COUNT(*) FROM dbo.Dim_Tiempo WHERE SK_Tiempo <> -1),
       (SELECT DATEDIFF(DAY, MIN(Fecha), MAX(Fecha)) + 1 - COUNT(*) FROM dbo.Dim_Tiempo WHERE SK_Tiempo <> -1),
       NULL
UNION ALL
SELECT 25, '3. Data mart', 'Exactitud', 'Importe distinto de cantidad x precio', 'Hechos_Ventas',
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas),
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas WHERE Importe_Linea <> Cantidad * Precio_Unitario),
       NULL
UNION ALL
SELECT 26, '3. Data mart', 'Exactitud', 'Margen distinto de importe menos costo', 'Hechos_Ventas',
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas),
       (SELECT COUNT(*) FROM dbo.Hechos_Ventas WHERE Margen_Linea <> Importe_Linea - Costo_Linea),
       NULL
UNION ALL
SELECT 27, '3. Data mart', 'Consistencia', 'Filas de hechos = líneas del origen', 'Hechos_Ventas vs origen',
       @Lineas_Origen,
       ABS(@Lineas_Origen - @Lineas_DM),
       CONCAT('Origen sin la repetida: ', @Lineas_Origen, ' | Data mart: ', @Lineas_DM)
UNION ALL
SELECT 28, '3. Data mart', 'Consistencia', 'Unidades vendidas cuadran con el origen', 'Hechos_Ventas vs origen',
       @Lineas_Origen,
       CASE WHEN @Unidades_Origen = @Unidades_DM THEN 0 ELSE 1 END,
       CONCAT('Origen: ', @Unidades_Origen, ' | Data mart: ', @Unidades_DM)
UNION ALL
SELECT 29, '3. Data mart', 'Consistencia', 'Importe total cuadra con el origen', 'Hechos_Ventas vs origen',
       @Lineas_Origen,
       CASE WHEN @Importe_Origen = @Importe_DM THEN 0 ELSE 1 END,
       CONCAT('Origen: ', @Importe_Origen, ' | Data mart: ', @Importe_DM)
UNION ALL
SELECT 30, '3. Data mart', 'Trazabilidad', 'Pasos del ETL que no terminaron en OK', 'stg_control_carga',
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_control_carga),
       (SELECT COUNT(*) FROM Staging_Jardineria.dbo.stg_control_carga WHERE Resultado <> 'OK'),
       'Bitácora de extracción, transformación y carga';

/* ---------------------------------------------------------------------
   GUARDAR Y MOSTRAR LOS RESULTADOS
   --------------------------------------------------------------------- */
INSERT INTO dbo.Calidad_Datos (Fecha_Ejecucion, Capa, Dimension, Prueba, Tabla,
                               Filas_Revisadas, Filas_Problema, Calidad_Pct, Resultado, Detalle)
SELECT @Ahora, Capa, Dimension, Prueba, Tabla, Filas_Revisadas, Filas_Problema,
       CASE WHEN Filas_Revisadas = 0 OR Filas_Problema = 0 THEN 100.0
            ELSE CAST(100.0 * (Filas_Revisadas - Filas_Problema) / Filas_Revisadas AS DECIMAL(5,1)) END,
       CASE WHEN Filas_Problema = 0 THEN 'OK'
            WHEN Capa = '1. Origen' THEN 'HALLAZGO'
            ELSE 'FALLA' END,
       Detalle
FROM @P
ORDER BY Orden;

-- Resultado 1: todas las pruebas de esta ejecución
SELECT ROW_NUMBER() OVER (ORDER BY ID_Prueba) AS N,
       Capa, Dimension, Prueba, Filas_Revisadas, Filas_Problema,
       Calidad_Pct, Resultado, Detalle
FROM dbo.Calidad_Datos
WHERE Fecha_Ejecucion = @Ahora
ORDER BY ID_Prueba;

-- Resultado 2: resumen por capa
SELECT Capa,
       COUNT(*)                                            AS Pruebas,
       SUM(CASE WHEN Resultado = 'OK'       THEN 1 ELSE 0 END) AS OK,
       SUM(CASE WHEN Resultado = 'HALLAZGO' THEN 1 ELSE 0 END) AS Hallazgos,
       SUM(CASE WHEN Resultado = 'FALLA'    THEN 1 ELSE 0 END) AS Fallas,
       CAST(AVG(Calidad_Pct) AS DECIMAL(5,1))              AS Calidad_Promedio_Pct
FROM dbo.Calidad_Datos
WHERE Fecha_Ejecucion = @Ahora
GROUP BY Capa
ORDER BY Capa;
GO

PRINT 'Pruebas de calidad terminadas. Resultados guardados en DM_Ventas_Jardineria.dbo.Calidad_Datos.';
GO
