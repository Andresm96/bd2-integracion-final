/* =====================================================================
   05_Carga_DataMart.sql
   EA3 - Proceso ETL Jardinería | ETAPA 3: CARGA
   Pasa los datos transformados (tablas tr_ de Staging_Jardineria) al
   data mart DM_Ventas_Jardineria.
     1. Vacía el data mart (primero hechos, luego dimensiones).
     2. Inserta el miembro desconocido (SK = -1) de cada dimensión.
     3. Carga las dimensiones y asigna la clave sustituta con ROW_NUMBER().
     4. Carga los hechos buscando la SK de cada dimensión por su clave
        natural; si no la encuentra usa -1 (nunca NULL).
   Todo en una transacción: o se carga completo o no se carga nada.
   Requisito: scripts 03 y 04 ejecutados.
   ===================================================================== */
USE DM_Ventas_Jardineria;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

-- 1. Vaciar (así el script se puede ejecutar varias veces)
TRUNCATE TABLE dbo.Hechos_Ventas;
DELETE FROM dbo.Dim_Tiempo;
DELETE FROM dbo.Dim_Producto;
DELETE FROM dbo.Dim_Cliente;
DELETE FROM dbo.Dim_Empleado;
DELETE FROM dbo.Dim_Oficina;
DELETE FROM dbo.Dim_Pedido;

-- 2. Miembro desconocido
INSERT INTO dbo.Dim_Tiempo (SK_Tiempo, Fecha, Anio, Trimestre, Mes, Nombre_Mes, Dia, Nombre_Dia, Semana_Anio, Fin_Semana)
VALUES (-1, NULL, 0, 0, 0, 'Sin fecha', 0, 'Sin fecha', 0, 'No');

INSERT INTO dbo.Dim_Producto (SK_Producto, ID_Producto, Codigo_Producto, Nombre_Producto, ID_Categoria, Desc_Categoria,
                              Proveedor, Dimensiones, Precio_Venta, Precio_Proveedor, Margen_Unitario)
VALUES (-1, -1, 'N/A', 'Desconocido', -1, 'Desconocida', 'Sin dato', 'Sin dato', 0, NULL, NULL);

INSERT INTO dbo.Dim_Cliente (SK_Cliente, ID_Cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito)
VALUES (-1, -1, 'Desconocido', 'Sin dato', 'Sin dato', 'Sin dato', 0);

INSERT INTO dbo.Dim_Empleado (SK_Empleado, ID_Empleado, Nombre_Completo, Puesto, Email, Jefe)
VALUES (-1, -1, 'Sin representante', 'Sin dato', 'Sin dato', 'Sin jefe');

INSERT INTO dbo.Dim_Oficina (SK_Oficina, ID_Oficina, Descripcion, Ciudad, Region, Pais, Codigo_Postal)
VALUES (-1, -1, 'N/A', 'Sin dato', 'Sin dato', 'Sin dato', 'Sin dato');

INSERT INTO dbo.Dim_Pedido (SK_Pedido, ID_Pedido, Estado, Fecha_Esperada, Fecha_Entrega, Entrega_A_Tiempo, Dias_Retraso, Calidad_Fechas)
VALUES (-1, -1, 'Desconocido', NULL, NULL, 'No aplica', NULL, 'Sin dato');

-- 3. Dimensiones
INSERT INTO dbo.Dim_Tiempo (SK_Tiempo, Fecha, Anio, Trimestre, Mes, Nombre_Mes, Dia, Nombre_Dia, Semana_Anio, Fin_Semana)
SELECT SK_Tiempo, Fecha, Anio, Trimestre, Mes, Nombre_Mes, Dia, Nombre_Dia, Semana_Anio, Fin_Semana
FROM Staging_Jardineria.dbo.tr_dim_tiempo;

INSERT INTO dbo.Dim_Producto (SK_Producto, ID_Producto, Codigo_Producto, Nombre_Producto, ID_Categoria, Desc_Categoria,
                              Proveedor, Dimensiones, Precio_Venta, Precio_Proveedor, Margen_Unitario)
SELECT ROW_NUMBER() OVER (ORDER BY ID_Producto),
       ID_Producto, Codigo_Producto, Nombre_Producto, ID_Categoria, Desc_Categoria,
       Proveedor, Dimensiones, Precio_Venta, Precio_Proveedor, Margen_Unitario
FROM Staging_Jardineria.dbo.tr_dim_producto;

INSERT INTO dbo.Dim_Cliente (SK_Cliente, ID_Cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito)
SELECT ROW_NUMBER() OVER (ORDER BY ID_Cliente),
       ID_Cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito
FROM Staging_Jardineria.dbo.tr_dim_cliente;

INSERT INTO dbo.Dim_Empleado (SK_Empleado, ID_Empleado, Nombre_Completo, Puesto, Email, Jefe)
SELECT ROW_NUMBER() OVER (ORDER BY ID_Empleado),
       ID_Empleado, Nombre_Completo, Puesto, Email, Jefe
FROM Staging_Jardineria.dbo.tr_dim_empleado;

INSERT INTO dbo.Dim_Oficina (SK_Oficina, ID_Oficina, Descripcion, Ciudad, Region, Pais, Codigo_Postal)
SELECT ROW_NUMBER() OVER (ORDER BY ID_Oficina),
       ID_Oficina, Descripcion, Ciudad, Region, Pais, Codigo_Postal
FROM Staging_Jardineria.dbo.tr_dim_oficina;

INSERT INTO dbo.Dim_Pedido (SK_Pedido, ID_Pedido, Estado, Fecha_Esperada, Fecha_Entrega, Entrega_A_Tiempo, Dias_Retraso, Calidad_Fechas)
SELECT ROW_NUMBER() OVER (ORDER BY ID_Pedido),
       ID_Pedido, Estado, Fecha_Esperada, Fecha_Entrega, Entrega_A_Tiempo, Dias_Retraso, Calidad_Fechas
FROM Staging_Jardineria.dbo.tr_dim_pedido;

-- 4. Hechos: búsqueda de claves sustitutas (lookup)
INSERT INTO dbo.Hechos_Ventas (SK_Tiempo, SK_Producto, SK_Cliente, SK_Empleado, SK_Oficina, SK_Pedido,
                               ID_Detalle_Pedido, Numero_Linea, Cantidad, Precio_Unitario,
                               Importe_Linea, Costo_Linea, Margen_Linea)
SELECT COALESCE(t.SK_Tiempo, -1),
       COALESCE(pr.SK_Producto, -1),
       COALESCE(c.SK_Cliente, -1),
       COALESCE(e.SK_Empleado, -1),
       COALESCE(o.SK_Oficina, -1),
       COALESCE(pe.SK_Pedido, -1),
       h.ID_Detalle_Pedido,
       h.Numero_Linea,
       h.Cantidad,
       h.Precio_Unitario,
       h.Importe_Linea,
       h.Costo_Linea,
       h.Margen_Linea
FROM Staging_Jardineria.dbo.tr_hechos_ventas h
LEFT JOIN dbo.Dim_Tiempo   t  ON t.SK_Tiempo    = h.SK_Tiempo
LEFT JOIN dbo.Dim_Producto pr ON pr.ID_Producto = h.ID_Producto
LEFT JOIN dbo.Dim_Cliente  c  ON c.ID_Cliente   = h.ID_Cliente
LEFT JOIN dbo.Dim_Empleado e  ON e.ID_Empleado  = h.ID_Empleado
LEFT JOIN dbo.Dim_Oficina  o  ON o.ID_Oficina   = h.ID_Oficina
LEFT JOIN dbo.Dim_Pedido   pe ON pe.ID_Pedido   = h.ID_Pedido;

COMMIT TRANSACTION;

-- Bitácora de la carga (filas en staging contra filas en el data mart,
-- sin contar el miembro desconocido)
INSERT INTO Staging_Jardineria.dbo.stg_control_carga (Etapa, Tabla, Filas_Origen, Filas_Destino, Resultado)
SELECT 'Carga', c.Tabla, c.Origen, c.Destino,
       CASE WHEN c.Origen = c.Destino THEN 'OK' ELSE 'REVISAR' END
FROM (
    SELECT 'Dim_Tiempo' AS Tabla, (SELECT COUNT(*) FROM Staging_Jardineria.dbo.tr_dim_tiempo) AS Origen,
           (SELECT COUNT(*) FROM dbo.Dim_Tiempo WHERE SK_Tiempo <> -1) AS Destino
    UNION ALL SELECT 'Dim_Producto', (SELECT COUNT(*) FROM Staging_Jardineria.dbo.tr_dim_producto),
           (SELECT COUNT(*) FROM dbo.Dim_Producto WHERE SK_Producto <> -1)
    UNION ALL SELECT 'Dim_Cliente', (SELECT COUNT(*) FROM Staging_Jardineria.dbo.tr_dim_cliente),
           (SELECT COUNT(*) FROM dbo.Dim_Cliente WHERE SK_Cliente <> -1)
    UNION ALL SELECT 'Dim_Empleado', (SELECT COUNT(*) FROM Staging_Jardineria.dbo.tr_dim_empleado),
           (SELECT COUNT(*) FROM dbo.Dim_Empleado WHERE SK_Empleado <> -1)
    UNION ALL SELECT 'Dim_Oficina', (SELECT COUNT(*) FROM Staging_Jardineria.dbo.tr_dim_oficina),
           (SELECT COUNT(*) FROM dbo.Dim_Oficina WHERE SK_Oficina <> -1)
    UNION ALL SELECT 'Dim_Pedido', (SELECT COUNT(*) FROM Staging_Jardineria.dbo.tr_dim_pedido),
           (SELECT COUNT(*) FROM dbo.Dim_Pedido WHERE SK_Pedido <> -1)
    UNION ALL SELECT 'Hechos_Ventas', (SELECT COUNT(*) FROM Staging_Jardineria.dbo.tr_hechos_ventas),
           (SELECT COUNT(*) FROM dbo.Hechos_Ventas)
) AS c;

SELECT TOP (7) Etapa, Tabla, Filas_Origen, Filas_Destino, Resultado
FROM Staging_Jardineria.dbo.stg_control_carga
WHERE Etapa = 'Carga'
ORDER BY ID_Control DESC;
GO
