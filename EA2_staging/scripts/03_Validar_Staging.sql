/* =====================================================================
   03_Validar_Staging.sql
   Comprueba que los datos de jardineria quedaron bien en Staging_Jardineria.

   Devuelve una fila por prueba con el valor esperado, el obtenido y el
   resultado (OK o REVISAR). Pruebas:
     A. Mismo número de filas en origen y en Staging (7 tablas).
     B. Ninguna clave del origen se quedó sin cargar (7 tablas).
     C. Mismas unidades e importe total en las líneas de pedido.
     D. Integridad entre tablas de Staging (no hay huérfanos).
     E. Limpieza: no quedan cadenas vacías ni nombres de país sin normalizar.
   ===================================================================== */

USE Staging_Jardineria;
GO

SET NOCOUNT ON;

SELECT v.Prueba,
       v.Esperado,
       v.Obtenido,
       CASE WHEN v.Esperado = v.Obtenido THEN 'OK' ELSE 'REVISAR' END AS Resultado
FROM (
    /* A. Conteo de filas */
    SELECT 'A1 Filas oficina' AS Prueba,
           CAST((SELECT COUNT(*) FROM jardineria.dbo.oficina) AS DECIMAL(18,2)) AS Esperado,
           CAST((SELECT COUNT(*) FROM dbo.stg_oficina) AS DECIMAL(18,2))        AS Obtenido
    UNION ALL
    SELECT 'A2 Filas empleado',
           (SELECT COUNT(*) FROM jardineria.dbo.empleado),
           (SELECT COUNT(*) FROM dbo.stg_empleado)
    UNION ALL
    SELECT 'A3 Filas Categoria_producto',
           (SELECT COUNT(*) FROM jardineria.dbo.Categoria_producto),
           (SELECT COUNT(*) FROM dbo.stg_categoria_producto)
    UNION ALL
    SELECT 'A4 Filas cliente',
           (SELECT COUNT(*) FROM jardineria.dbo.cliente),
           (SELECT COUNT(*) FROM dbo.stg_cliente)
    UNION ALL
    SELECT 'A5 Filas pedido',
           (SELECT COUNT(*) FROM jardineria.dbo.pedido),
           (SELECT COUNT(*) FROM dbo.stg_pedido)
    UNION ALL
    SELECT 'A6 Filas producto',
           (SELECT COUNT(*) FROM jardineria.dbo.producto),
           (SELECT COUNT(*) FROM dbo.stg_producto)
    UNION ALL
    SELECT 'A7 Filas detalle_pedido',
           (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido),
           (SELECT COUNT(*) FROM dbo.stg_detalle_pedido)

    /* B. Claves del origen que no llegaron a Staging (se espera 0) */
    UNION ALL
    SELECT 'B1 Oficinas sin cargar', 0,
           (SELECT COUNT(*) FROM (SELECT ID_oficina FROM jardineria.dbo.oficina
                                  EXCEPT SELECT ID_oficina FROM dbo.stg_oficina) AS k)
    UNION ALL
    SELECT 'B2 Empleados sin cargar', 0,
           (SELECT COUNT(*) FROM (SELECT ID_empleado FROM jardineria.dbo.empleado
                                  EXCEPT SELECT ID_empleado FROM dbo.stg_empleado) AS k)
    UNION ALL
    SELECT 'B3 Categorías sin cargar', 0,
           (SELECT COUNT(*) FROM (SELECT Id_Categoria FROM jardineria.dbo.Categoria_producto
                                  EXCEPT SELECT ID_categoria FROM dbo.stg_categoria_producto) AS k)
    UNION ALL
    SELECT 'B4 Clientes sin cargar', 0,
           (SELECT COUNT(*) FROM (SELECT ID_cliente FROM jardineria.dbo.cliente
                                  EXCEPT SELECT ID_cliente FROM dbo.stg_cliente) AS k)
    UNION ALL
    SELECT 'B5 Pedidos sin cargar', 0,
           (SELECT COUNT(*) FROM (SELECT ID_pedido FROM jardineria.dbo.pedido
                                  EXCEPT SELECT ID_pedido FROM dbo.stg_pedido) AS k)
    UNION ALL
    SELECT 'B6 Productos sin cargar', 0,
           (SELECT COUNT(*) FROM (SELECT ID_producto FROM jardineria.dbo.producto
                                  EXCEPT SELECT ID_producto FROM dbo.stg_producto) AS k)
    UNION ALL
    SELECT 'B7 Líneas de pedido sin cargar', 0,
           (SELECT COUNT(*) FROM (SELECT ID_pedido, ID_producto FROM jardineria.dbo.detalle_pedido
                                  EXCEPT SELECT ID_pedido, ID_producto FROM dbo.stg_detalle_pedido) AS k)

    /* C. Totales de las líneas de pedido */
    UNION ALL
    SELECT 'C1 Unidades vendidas',
           (SELECT SUM(cantidad) FROM jardineria.dbo.detalle_pedido),
           (SELECT SUM(Cantidad) FROM dbo.stg_detalle_pedido)
    UNION ALL
    SELECT 'C2 Importe vendido',
           (SELECT SUM(cantidad * precio_unidad) FROM jardineria.dbo.detalle_pedido),
           (SELECT SUM(Cantidad * Precio_Unidad) FROM dbo.stg_detalle_pedido)

    /* D. Integridad dentro de Staging (se espera 0 huérfanos) */
    UNION ALL
    SELECT 'D1 Líneas sin pedido', 0,
           (SELECT COUNT(*) FROM dbo.stg_detalle_pedido AS d
            WHERE NOT EXISTS (SELECT 1 FROM dbo.stg_pedido AS p WHERE p.ID_pedido = d.ID_pedido))
    UNION ALL
    SELECT 'D2 Líneas sin producto', 0,
           (SELECT COUNT(*) FROM dbo.stg_detalle_pedido AS d
            WHERE NOT EXISTS (SELECT 1 FROM dbo.stg_producto AS p WHERE p.ID_producto = d.ID_producto))
    UNION ALL
    SELECT 'D3 Pedidos sin cliente', 0,
           (SELECT COUNT(*) FROM dbo.stg_pedido AS p
            WHERE NOT EXISTS (SELECT 1 FROM dbo.stg_cliente AS c WHERE c.ID_cliente = p.ID_cliente))
    UNION ALL
    SELECT 'D4 Productos sin categoría', 0,
           (SELECT COUNT(*) FROM dbo.stg_producto AS p
            WHERE NOT EXISTS (SELECT 1 FROM dbo.stg_categoria_producto AS c WHERE c.ID_categoria = p.ID_categoria))
    UNION ALL
    SELECT 'D5 Clientes con representante inexistente', 0,
           (SELECT COUNT(*) FROM dbo.stg_cliente AS c
            WHERE c.ID_empleado_rep_ventas IS NOT NULL
              AND NOT EXISTS (SELECT 1 FROM dbo.stg_empleado AS e WHERE e.ID_empleado = c.ID_empleado_rep_ventas))
    UNION ALL
    SELECT 'D6 Empleados sin oficina', 0,
           (SELECT COUNT(*) FROM dbo.stg_empleado AS e
            WHERE NOT EXISTS (SELECT 1 FROM dbo.stg_oficina AS o WHERE o.ID_oficina = e.ID_oficina))

    /* E. Limpieza aplicada */
    UNION ALL
    SELECT 'E1 Cadenas vacías en Staging', 0,
           (SELECT COUNT(*) FROM dbo.stg_empleado WHERE Apellido2 = '')
         + (SELECT COUNT(*) FROM dbo.stg_producto WHERE Dimensiones = '')
         + (SELECT COUNT(*) FROM dbo.stg_cliente  WHERE Region = '')
    UNION ALL
    SELECT 'E2 Países sin normalizar', 0,
           (SELECT COUNT(*) FROM dbo.stg_cliente
            WHERE Pais IN ('Spain', 'USA', 'EEUU', 'United Kingdom', 'Inglaterra', 'France'))
         + (SELECT COUNT(*) FROM dbo.stg_oficina
            WHERE Pais IN ('Spain', 'USA', 'EEUU', 'United Kingdom', 'Inglaterra', 'France'))
) AS v;
GO

/* Pedidos marcados con fechas inconsistentes (informativo) */
SELECT Observacion, COUNT(*) AS Pedidos
FROM dbo.stg_pedido
WHERE Observacion IS NOT NULL
GROUP BY Observacion
ORDER BY Pedidos DESC;
GO

/* Países después de la normalización (informativo) */
SELECT 'cliente' AS Tabla, Pais, COUNT(*) AS Filas FROM dbo.stg_cliente GROUP BY Pais
UNION ALL
SELECT 'oficina', Pais, COUNT(*) FROM dbo.stg_oficina GROUP BY Pais
ORDER BY Tabla, Filas DESC;
GO
