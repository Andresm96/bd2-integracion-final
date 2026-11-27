/* =====================================================================
   Consultas_Analisis_DataMart.sql
   Consultas SQL de análisis sobre el data mart DM_Ventas_Jardineria
   (modelo estrella). Son la Parte B del script 06 de la EA3, separadas
   aquí para encontrarlas fácil. Responden las preguntas del negocio:
     B1 producto más vendido · B2 producto con más ingreso
     B3 categorías · B4 ventas por año · B5 ventas por oficina
     B6 representantes de ventas · B7 clientes · B8 estado del pedido
     B9 cumplimiento de entregas
   Requisito: haber ejecutado los scripts 00 a 05 de la EA3.
   ===================================================================== */
USE DM_Ventas_Jardineria;
GO
SET NOCOUNT ON;

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
GO
