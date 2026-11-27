/* =====================================================================
   02_Cargar_Staging_Jardineria.sql
   Trae los registros de jardineria a Staging_Jardineria (SQL Server).

   Requisitos: haber ejecutado 00_Jardineria_corregido.sql y
               01_Crear_Staging_Jardineria.sql en la misma instancia.

   Es una carga completa: vacía cada tabla stg_ y la vuelve a llenar, así
   que se puede ejecutar varias veces y siempre deja el mismo resultado.
   Todo corre en una sola transacción: si una instrucción falla, no queda
   ninguna tabla a medio cargar.

   Limpieza aplicada al trasladar los datos:
   - LTRIM/RTRIM en los textos.
   - Las cadenas vacías ('') se guardan como NULL.
   - El país se escribe de una sola forma (Spain y España -> España,
     USA y EEUU -> Estados Unidos, United Kingdom e Inglaterra -> Reino Unido,
     France -> Francia).
   - stg_pedido.Observacion marca los pedidos con fechas inconsistentes.
     Las fechas no se modifican: se dejan para que el negocio las revise.
   ===================================================================== */

USE Staging_Jardineria;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

/* 1. Vaciar las tablas de Staging */
TRUNCATE TABLE dbo.stg_detalle_pedido;
TRUNCATE TABLE dbo.stg_producto;
TRUNCATE TABLE dbo.stg_pedido;
TRUNCATE TABLE dbo.stg_cliente;
TRUNCATE TABLE dbo.stg_categoria_producto;
TRUNCATE TABLE dbo.stg_empleado;
TRUNCATE TABLE dbo.stg_oficina;

/* 2. oficina -> stg_oficina */
INSERT INTO dbo.stg_oficina (ID_oficina, Descripcion, Ciudad, Pais, Region, Codigo_Postal)
SELECT o.ID_oficina,
       LTRIM(RTRIM(o.Descripcion)),
       LTRIM(RTRIM(o.ciudad)),
       CASE LTRIM(RTRIM(o.pais))
            WHEN 'Spain'          THEN 'España'
            WHEN 'USA'            THEN 'Estados Unidos'
            WHEN 'EEUU'           THEN 'Estados Unidos'
            WHEN 'United Kingdom' THEN 'Reino Unido'
            WHEN 'Inglaterra'     THEN 'Reino Unido'
            WHEN 'France'         THEN 'Francia'
            ELSE LTRIM(RTRIM(o.pais))
       END,
       NULLIF(LTRIM(RTRIM(o.region)), ''),
       LTRIM(RTRIM(o.codigo_postal))
FROM jardineria.dbo.oficina AS o;

/* 3. empleado -> stg_empleado */
INSERT INTO dbo.stg_empleado (ID_empleado, Nombre, Apellido1, Apellido2, Email, Puesto, ID_oficina)
SELECT e.ID_empleado,
       LTRIM(RTRIM(e.nombre)),
       LTRIM(RTRIM(e.apellido1)),
       NULLIF(LTRIM(RTRIM(e.apellido2)), ''),
       LTRIM(RTRIM(e.email)),
       NULLIF(LTRIM(RTRIM(e.puesto)), ''),
       e.ID_oficina
FROM jardineria.dbo.empleado AS e;

/* 4. Categoria_producto -> stg_categoria_producto */
INSERT INTO dbo.stg_categoria_producto (ID_categoria, Desc_Categoria)
SELECT c.Id_Categoria,
       LTRIM(RTRIM(c.Desc_Categoria))
FROM jardineria.dbo.Categoria_producto AS c;

/* 5. cliente -> stg_cliente */
INSERT INTO dbo.stg_cliente (ID_cliente, Nombre_Cliente, Ciudad, Region, Pais,
                             Limite_Credito, ID_empleado_rep_ventas)
SELECT c.ID_cliente,
       LTRIM(RTRIM(c.nombre_cliente)),
       LTRIM(RTRIM(c.ciudad)),
       NULLIF(LTRIM(RTRIM(c.region)), ''),
       CASE LTRIM(RTRIM(c.pais))
            WHEN 'Spain'          THEN 'España'
            WHEN 'USA'            THEN 'Estados Unidos'
            WHEN 'EEUU'           THEN 'Estados Unidos'
            WHEN 'United Kingdom' THEN 'Reino Unido'
            WHEN 'Inglaterra'     THEN 'Reino Unido'
            WHEN 'France'         THEN 'Francia'
            ELSE NULLIF(LTRIM(RTRIM(c.pais)), '')
       END,
       c.limite_credito,
       c.ID_empleado_rep_ventas
FROM jardineria.dbo.cliente AS c;

/* 6. pedido -> stg_pedido (con la observación de calidad de fechas) */
INSERT INTO dbo.stg_pedido (ID_pedido, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega,
                            Estado, ID_cliente, Observacion)
SELECT p.ID_pedido,
       p.fecha_pedido,
       p.fecha_esperada,
       p.fecha_entrega,
       LTRIM(RTRIM(p.estado)),
       p.ID_cliente,
       CASE
            WHEN p.estado = 'Entregado' AND p.fecha_entrega IS NULL
                 THEN 'Entregado sin fecha de entrega'
            WHEN p.fecha_entrega < p.fecha_pedido
                 THEN 'Fecha de entrega anterior al pedido'
            WHEN p.fecha_esperada < p.fecha_pedido
                 THEN 'Fecha esperada anterior al pedido'
            WHEN p.fecha_entrega IS NOT NULL AND p.estado <> 'Entregado'
                 THEN CONCAT('Tiene fecha de entrega y estado ', p.estado)
            ELSE NULL
       END
FROM jardineria.dbo.pedido AS p;

/* 7. producto -> stg_producto */
INSERT INTO dbo.stg_producto (ID_producto, Nombre, ID_categoria, Dimensiones,
                              Proveedor, Precio_Venta, Precio_Proveedor)
SELECT LTRIM(RTRIM(p.ID_producto)),
       LTRIM(RTRIM(p.nombre)),
       p.Categoria,
       NULLIF(LTRIM(RTRIM(p.dimensiones)), ''),
       NULLIF(LTRIM(RTRIM(p.proveedor)), ''),
       p.precio_venta,
       p.precio_proveedor
FROM jardineria.dbo.producto AS p;

/* 8. detalle_pedido -> stg_detalle_pedido */
INSERT INTO dbo.stg_detalle_pedido (ID_pedido, ID_producto, Numero_Linea, Cantidad, Precio_Unidad)
SELECT d.ID_pedido,
       LTRIM(RTRIM(d.ID_producto)),
       d.numero_linea,
       d.cantidad,
       d.precio_unidad
FROM jardineria.dbo.detalle_pedido AS d;

/* 9. Bitácora: filas en origen contra filas en Staging */
INSERT INTO dbo.stg_control_carga (Tabla_Origen, Tabla_Staging, Filas_Origen, Filas_Staging, Resultado)
SELECT x.Tabla_Origen, x.Tabla_Staging, x.Filas_Origen, x.Filas_Staging,
       CASE WHEN x.Filas_Origen = x.Filas_Staging THEN 'OK' ELSE 'REVISAR' END
FROM (
    SELECT 'oficina' AS Tabla_Origen, 'stg_oficina' AS Tabla_Staging,
           (SELECT COUNT(*) FROM jardineria.dbo.oficina) AS Filas_Origen,
           (SELECT COUNT(*) FROM dbo.stg_oficina)        AS Filas_Staging
    UNION ALL
    SELECT 'empleado', 'stg_empleado',
           (SELECT COUNT(*) FROM jardineria.dbo.empleado),
           (SELECT COUNT(*) FROM dbo.stg_empleado)
    UNION ALL
    SELECT 'Categoria_producto', 'stg_categoria_producto',
           (SELECT COUNT(*) FROM jardineria.dbo.Categoria_producto),
           (SELECT COUNT(*) FROM dbo.stg_categoria_producto)
    UNION ALL
    SELECT 'cliente', 'stg_cliente',
           (SELECT COUNT(*) FROM jardineria.dbo.cliente),
           (SELECT COUNT(*) FROM dbo.stg_cliente)
    UNION ALL
    SELECT 'pedido', 'stg_pedido',
           (SELECT COUNT(*) FROM jardineria.dbo.pedido),
           (SELECT COUNT(*) FROM dbo.stg_pedido)
    UNION ALL
    SELECT 'producto', 'stg_producto',
           (SELECT COUNT(*) FROM jardineria.dbo.producto),
           (SELECT COUNT(*) FROM dbo.stg_producto)
    UNION ALL
    SELECT 'detalle_pedido', 'stg_detalle_pedido',
           (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido),
           (SELECT COUNT(*) FROM dbo.stg_detalle_pedido)
) AS x;

COMMIT TRANSACTION;
GO

/* Resultado de la última carga */
SELECT Tabla_Origen, Tabla_Staging, Filas_Origen, Filas_Staging, Resultado, Fecha_Carga
FROM dbo.stg_control_carga
WHERE Fecha_Carga = (SELECT MAX(Fecha_Carga) FROM dbo.stg_control_carga)
ORDER BY ID_control;
GO
