/* =====================================================================
   06_Validacion_y_Analisis.sql
   EA3 - Proceso ETL Jardinería | VERIFICACIÓN Y ANÁLISIS
   Parte A: compara el data mart con la base de origen (todas OK).
   Parte B: consultas de negocio sobre el modelo estrella.
   Parte C: bitácora completa del ETL.
   ===================================================================== */
USE DM_Ventas_Jardineria;
GO
SET NOCOUNT ON;

/* ---------------------------------------------------------------------
   PARTE A. VALIDACIÓN (Esperado se calcula en la base de ORIGEN)
   --------------------------------------------------------------------- */
-- A1. Conteos
SELECT v.Prueba, v.Esperado, v.Obtenido,
       CASE WHEN v.Esperado = v.Obtenido THEN 'OK' ELSE 'ERROR' END AS Resultado
FROM (
    SELECT 'Filas de hechos = líneas de origen sin duplicados' AS Prueba,
           (SELECT COUNT(*) FROM (SELECT DISTINCT ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea
                                  FROM jardineria.dbo.detalle_pedido) AS x) AS Esperado,
           (SELECT COUNT(*) FROM dbo.Hechos_Ventas) AS Obtenido
    UNION ALL SELECT 'Pedidos con ventas',
           (SELECT COUNT(DISTINCT ID_pedido) FROM jardineria.dbo.detalle_pedido),
           (SELECT COUNT(DISTINCT SK_Pedido) FROM dbo.Hechos_Ventas)
    UNION ALL SELECT 'Productos vendidos',
           (SELECT COUNT(DISTINCT ID_producto) FROM jardineria.dbo.detalle_pedido),
           (SELECT COUNT(DISTINCT SK_Producto) FROM dbo.Hechos_Ventas)
    UNION ALL SELECT 'Dim_Producto = productos + 1 desconocido',
           (SELECT COUNT(*) + 1 FROM jardineria.dbo.producto), (SELECT COUNT(*) FROM dbo.Dim_Producto)
    UNION ALL SELECT 'Dim_Cliente = clientes + 1 desconocido',
           (SELECT COUNT(*) + 1 FROM jardineria.dbo.cliente), (SELECT COUNT(*) FROM dbo.Dim_Cliente)
    UNION ALL SELECT 'Dim_Empleado = empleados + 1 desconocido',
           (SELECT COUNT(*) + 1 FROM jardineria.dbo.empleado), (SELECT COUNT(*) FROM dbo.Dim_Empleado)
    UNION ALL SELECT 'Dim_Oficina = oficinas + 1 desconocido',
           (SELECT COUNT(*) + 1 FROM jardineria.dbo.oficina), (SELECT COUNT(*) FROM dbo.Dim_Oficina)
    UNION ALL SELECT 'Dim_Pedido = pedidos + 1 desconocido',
           (SELECT COUNT(*) + 1 FROM jardineria.dbo.pedido), (SELECT COUNT(*) FROM dbo.Dim_Pedido)
    UNION ALL SELECT 'Dim_Tiempo sin huecos (días del calendario)',
           (SELECT DATEDIFF(DAY, MIN(Fecha), MAX(Fecha)) + 1 FROM dbo.Dim_Tiempo WHERE SK_Tiempo <> -1),
           (SELECT COUNT(*) FROM dbo.Dim_Tiempo WHERE SK_Tiempo <> -1)
    UNION ALL SELECT 'Hechos apuntando a un miembro desconocido (-1)', 0,
           (SELECT COUNT(*) FROM dbo.Hechos_Ventas
            WHERE -1 IN (SK_Tiempo, SK_Producto, SK_Cliente, SK_Empleado, SK_Oficina, SK_Pedido))
    UNION ALL SELECT 'Hechos sin producto en la dimensión (huérfanos)', 0,
           (SELECT COUNT(*) FROM dbo.Hechos_Ventas h
            WHERE NOT EXISTS (SELECT 1 FROM dbo.Dim_Producto p WHERE p.SK_Producto = h.SK_Producto))
    UNION ALL SELECT 'Hechos con importe distinto de cantidad x precio', 0,
           (SELECT COUNT(*) FROM dbo.Hechos_Ventas WHERE Importe_Linea <> Cantidad * Precio_Unitario)
    UNION ALL SELECT 'Hechos con margen distinto de importe - costo', 0,
           (SELECT COUNT(*) FROM dbo.Hechos_Ventas WHERE Margen_Linea <> Importe_Linea - Costo_Linea)
) AS v;

-- A2. Totales (cuadre de dinero y unidades con el origen)
SELECT v.Prueba, v.Esperado, v.Obtenido,
       CASE WHEN v.Esperado = v.Obtenido THEN 'OK' ELSE 'ERROR' END AS Resultado
FROM (
    SELECT 'Unidades vendidas' AS Prueba,
           (SELECT SUM(cantidad) FROM (SELECT DISTINCT ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea
                                       FROM jardineria.dbo.detalle_pedido) AS x) AS Esperado,
           (SELECT SUM(Cantidad) FROM dbo.Hechos_Ventas) AS Obtenido
    UNION ALL SELECT 'Importe total',
           (SELECT SUM(cantidad * precio_unidad) FROM (SELECT DISTINCT ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea
                                                      FROM jardineria.dbo.detalle_pedido) AS x),
           (SELECT SUM(Importe_Linea) FROM dbo.Hechos_Ventas)
) AS v;

/* ---------------------------------------------------------------------
   PARTE B. ANÁLISIS PARA LA TOMA DE DECISIONES
   --------------------------------------------------------------------- */
-- B1. Producto más vendido (por unidades)
SELECT TOP (5) p.Codigo_Producto, p.Nombre_Producto, p.Desc_Categoria,
       SUM(h.Cantidad) AS Unidades, SUM(h.Importe_Linea) AS Importe
FROM dbo.Hechos_Ventas h
JOIN dbo.Dim_Producto p ON p.SK_Producto = h.SK_Producto
GROUP BY p.Codigo_Producto, p.Nombre_Producto, p.Desc_Categoria
ORDER BY Unidades DESC, Importe DESC;

-- B2. Producto que más dinero generó
SELECT TOP (5) p.Codigo_Producto, p.Nombre_Producto, p.Desc_Categoria,
       SUM(h.Cantidad) AS Unidades, SUM(h.Importe_Linea) AS Importe
FROM dbo.Hechos_Ventas h
JOIN dbo.Dim_Producto p ON p.SK_Producto = h.SK_Producto
GROUP BY p.Codigo_Producto, p.Nombre_Producto, p.Desc_Categoria
ORDER BY Importe DESC, Unidades DESC;

-- B3. Categorías: productos en catálogo y ventas
SELECT p.Desc_Categoria,
       COUNT(DISTINCT p.SK_Producto)  AS Productos_Catalogo,
       COUNT(DISTINCT h.SK_Producto)  AS Productos_Vendidos,
       COALESCE(SUM(h.Cantidad), 0)      AS Unidades,
       COALESCE(SUM(h.Importe_Linea), 0) AS Importe,
       COALESCE(SUM(h.Margen_Linea), 0)  AS Margen
FROM dbo.Dim_Producto p
LEFT JOIN dbo.Hechos_Ventas h ON h.SK_Producto = p.SK_Producto
WHERE p.SK_Producto <> -1
GROUP BY p.Desc_Categoria
ORDER BY Productos_Catalogo DESC;

-- B4. Ventas por año
SELECT t.Anio,
       COUNT(DISTINCT h.SK_Pedido) AS Pedidos,
       SUM(h.Cantidad)             AS Unidades,
       SUM(h.Importe_Linea)        AS Importe,
       SUM(h.Margen_Linea)         AS Margen
FROM dbo.Hechos_Ventas h
JOIN dbo.Dim_Tiempo t ON t.SK_Tiempo = h.SK_Tiempo
GROUP BY t.Anio
ORDER BY t.Anio;

-- B5. Ventas por oficina (sede del representante del cliente)
SELECT o.Descripcion, o.Ciudad, o.Pais,
       COUNT(DISTINCT h.SK_Pedido) AS Pedidos,
       SUM(h.Importe_Linea)        AS Importe
FROM dbo.Hechos_Ventas h
JOIN dbo.Dim_Oficina o ON o.SK_Oficina = h.SK_Oficina
GROUP BY o.Descripcion, o.Ciudad, o.Pais
ORDER BY Importe DESC;

-- B6. Representantes de ventas con más importe
SELECT TOP (5) e.Nombre_Completo, e.Jefe,
       COUNT(DISTINCT h.SK_Cliente) AS Clientes,
       SUM(h.Importe_Linea)         AS Importe
FROM dbo.Hechos_Ventas h
JOIN dbo.Dim_Empleado e ON e.SK_Empleado = h.SK_Empleado
GROUP BY e.Nombre_Completo, e.Jefe
ORDER BY Importe DESC;

-- B7. Clientes que más compran
SELECT TOP (5) c.Nombre_Cliente, c.Pais,
       COUNT(DISTINCT h.SK_Pedido) AS Pedidos,
       SUM(h.Importe_Linea)        AS Importe
FROM dbo.Hechos_Ventas h
JOIN dbo.Dim_Cliente c ON c.SK_Cliente = h.SK_Cliente
GROUP BY c.Nombre_Cliente, c.Pais
ORDER BY Importe DESC;

-- B8. Ventas según el estado del pedido
SELECT pe.Estado,
       COUNT(DISTINCT h.SK_Pedido) AS Pedidos,
       SUM(h.Cantidad)             AS Unidades,
       SUM(h.Importe_Linea)        AS Importe
FROM dbo.Hechos_Ventas h
JOIN dbo.Dim_Pedido pe ON pe.SK_Pedido = h.SK_Pedido
GROUP BY pe.Estado
ORDER BY Importe DESC;

-- B9. Cumplimiento de entregas (pedidos entregados)
SELECT Entrega_A_Tiempo, COUNT(*) AS Pedidos
FROM dbo.Dim_Pedido
WHERE Estado = 'Entregado'
GROUP BY Entrega_A_Tiempo
ORDER BY Pedidos DESC;

/* ---------------------------------------------------------------------
   PARTE C. BITÁCORA COMPLETA DEL ETL
   --------------------------------------------------------------------- */
SELECT ID_Control, Etapa, Tabla, Filas_Origen, Filas_Destino, Resultado, Fecha_Ejecucion
FROM Staging_Jardineria.dbo.stg_control_carga
ORDER BY ID_Control;
GO
