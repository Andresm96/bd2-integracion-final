/* =====================================================================
   02_Extraccion_Origen_a_Staging.sql
   EA3 - Proceso ETL Jardinería | ETAPA 1: EXTRACCIÓN
   Copia los datos de jardineria (origen) a Staging_Jardineria.
   Tipo de carga: completa (TRUNCATE + INSERT ... SELECT), dentro de una
   transacción: si una tabla falla, no se carga ninguna.
   Los datos se copian tal como están; la limpieza se hace en el script 03.
   ===================================================================== */
USE Staging_Jardineria;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 1. Disponibilidad: las dos bases deben aparecer en estado ONLINE
SELECT name AS Base_Datos, state_desc AS Estado
FROM sys.databases
WHERE name IN ('jardineria', 'Staging_Jardineria');

-- 2. Extracción
BEGIN TRANSACTION;

TRUNCATE TABLE dbo.stg_oficina;
TRUNCATE TABLE dbo.stg_empleado;
TRUNCATE TABLE dbo.stg_categoria;
TRUNCATE TABLE dbo.stg_cliente;
TRUNCATE TABLE dbo.stg_pedido;
TRUNCATE TABLE dbo.stg_producto;
TRUNCATE TABLE dbo.stg_detalle_pedido;

INSERT INTO dbo.stg_oficina (ID_oficina, Descripcion, ciudad, pais, region, codigo_postal)
SELECT ID_oficina, Descripcion, ciudad, pais, region, codigo_postal
FROM jardineria.dbo.oficina;

INSERT INTO dbo.stg_empleado (ID_empleado, nombre, apellido1, apellido2, email, ID_oficina, ID_jefe, puesto)
SELECT ID_empleado, nombre, apellido1, apellido2, email, ID_oficina, ID_jefe, puesto
FROM jardineria.dbo.empleado;

INSERT INTO dbo.stg_categoria (Id_Categoria, Desc_Categoria)
SELECT Id_Categoria, Desc_Categoria
FROM jardineria.dbo.Categoria_producto;

INSERT INTO dbo.stg_cliente (ID_cliente, nombre_cliente, ciudad, region, pais, codigo_postal,
                             ID_empleado_rep_ventas, limite_credito)
SELECT ID_cliente, nombre_cliente, ciudad, region, pais, codigo_postal,
       ID_empleado_rep_ventas, limite_credito
FROM jardineria.dbo.cliente;

INSERT INTO dbo.stg_pedido (ID_pedido, fecha_pedido, fecha_esperada, fecha_entrega, estado, ID_cliente)
SELECT ID_pedido, fecha_pedido, fecha_esperada, fecha_entrega, estado, ID_cliente
FROM jardineria.dbo.pedido;

INSERT INTO dbo.stg_producto (ID_producto, CodigoProducto, nombre, Categoria, dimensiones, proveedor,
                              cantidad_en_stock, precio_venta, precio_proveedor)
SELECT ID_producto, CodigoProducto, nombre, Categoria, dimensiones, proveedor,
       cantidad_en_stock, precio_venta, precio_proveedor
FROM jardineria.dbo.producto;

INSERT INTO dbo.stg_detalle_pedido (ID_detalle_pedido, ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea)
SELECT ID_detalle_pedido, ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea
FROM jardineria.dbo.detalle_pedido;

COMMIT TRANSACTION;

-- 3. Bitácora: filas del origen contra filas extraídas
INSERT INTO dbo.stg_control_carga (Etapa, Tabla, Filas_Origen, Filas_Destino, Resultado)
SELECT 'Extracción', c.Tabla, c.Origen, c.Destino,
       CASE WHEN c.Origen = c.Destino THEN 'OK' ELSE 'REVISAR' END
FROM (
    SELECT 'stg_oficina' AS Tabla, (SELECT COUNT(*) FROM jardineria.dbo.oficina) AS Origen,
           (SELECT COUNT(*) FROM dbo.stg_oficina) AS Destino
    UNION ALL SELECT 'stg_empleado', (SELECT COUNT(*) FROM jardineria.dbo.empleado),
           (SELECT COUNT(*) FROM dbo.stg_empleado)
    UNION ALL SELECT 'stg_categoria', (SELECT COUNT(*) FROM jardineria.dbo.Categoria_producto),
           (SELECT COUNT(*) FROM dbo.stg_categoria)
    UNION ALL SELECT 'stg_cliente', (SELECT COUNT(*) FROM jardineria.dbo.cliente),
           (SELECT COUNT(*) FROM dbo.stg_cliente)
    UNION ALL SELECT 'stg_pedido', (SELECT COUNT(*) FROM jardineria.dbo.pedido),
           (SELECT COUNT(*) FROM dbo.stg_pedido)
    UNION ALL SELECT 'stg_producto', (SELECT COUNT(*) FROM jardineria.dbo.producto),
           (SELECT COUNT(*) FROM dbo.stg_producto)
    UNION ALL SELECT 'stg_detalle_pedido', (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido),
           (SELECT COUNT(*) FROM dbo.stg_detalle_pedido)
) AS c;

SELECT TOP (7) Etapa, Tabla, Filas_Origen, Filas_Destino, Resultado
FROM dbo.stg_control_carga
WHERE Etapa = 'Extracción'
ORDER BY ID_Control DESC;

-- 4. Integridad: como staging no tiene claves foráneas, se revisan aquí.
--    Todas las pruebas deben dar 0 casos (la última es solo informativa).
SELECT p.Prueba, p.Casos,
       CASE WHEN p.Casos = 0 THEN 'OK' WHEN p.Prueba LIKE 'Info:%' THEN 'INFO' ELSE 'REVISAR' END AS Resultado
FROM (
    SELECT 'Detalle sin pedido' AS Prueba, COUNT(*) AS Casos
    FROM dbo.stg_detalle_pedido d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.stg_pedido p WHERE p.ID_pedido = d.ID_pedido)
    UNION ALL
    SELECT 'Detalle sin producto', COUNT(*)
    FROM dbo.stg_detalle_pedido d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.stg_producto p WHERE p.ID_producto = d.ID_producto)
    UNION ALL
    SELECT 'Pedido sin cliente', COUNT(*)
    FROM dbo.stg_pedido p
    WHERE NOT EXISTS (SELECT 1 FROM dbo.stg_cliente c WHERE c.ID_cliente = p.ID_cliente)
    UNION ALL
    SELECT 'Cliente con representante inexistente', COUNT(*)
    FROM dbo.stg_cliente c
    WHERE c.ID_empleado_rep_ventas IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM dbo.stg_empleado e WHERE e.ID_empleado = c.ID_empleado_rep_ventas)
    UNION ALL
    SELECT 'Empleado con oficina inexistente', COUNT(*)
    FROM dbo.stg_empleado e
    WHERE NOT EXISTS (SELECT 1 FROM dbo.stg_oficina o WHERE o.ID_oficina = e.ID_oficina)
    UNION ALL
    SELECT 'Producto con categoría inexistente', COUNT(*)
    FROM dbo.stg_producto p
    WHERE NOT EXISTS (SELECT 1 FROM dbo.stg_categoria c WHERE c.Id_Categoria = p.Categoria)
    UNION ALL
    SELECT 'Cantidad o precio menor o igual a 0', COUNT(*)
    FROM dbo.stg_detalle_pedido
    WHERE cantidad <= 0 OR precio_unidad <= 0
    UNION ALL
    SELECT 'Pedido sin fecha de pedido', COUNT(*)
    FROM dbo.stg_pedido
    WHERE fecha_pedido IS NULL
    UNION ALL
    SELECT 'Info: pedidos sin líneas de detalle', COUNT(*)
    FROM dbo.stg_pedido p
    WHERE NOT EXISTS (SELECT 1 FROM dbo.stg_detalle_pedido d WHERE d.ID_pedido = p.ID_pedido)
) AS p;
GO
