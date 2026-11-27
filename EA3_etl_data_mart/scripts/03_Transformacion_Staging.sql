/* =====================================================================
   03_Transformacion_Staging.sql
   EA3 - Proceso ETL Jardinería | ETAPA 2: TRANSFORMACIÓN
   Trabaja dentro de Staging_Jardineria, en cuatro pasos:
     3.1 Limpieza ......... espacios, tildes dañadas, comillas, '' -> NULL
     3.2 Normalización .... países, categorías, estados y correos
     3.3 Calidad .......... marca fechas inconsistentes y líneas duplicadas
     3.4 Enriquecimiento .. llena las tablas tr_ con la forma del modelo
                            estrella (calendario, uniones, campos derivados
                            y métricas)
   Requisito: haber ejecutado antes el script 02 (extracción).
   ===================================================================== */
USE Staging_Jardineria;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

/* ---------------------------------------------------------------------
   3.1 LIMPIEZA: fn_LimpiarTexto quita espacios sobrantes, repara
       caracteres como 'Ã³' -> 'ó', cambia \" por " y deja NULL donde
       había texto vacío.
   --------------------------------------------------------------------- */
UPDATE dbo.stg_oficina
SET Descripcion   = dbo.fn_LimpiarTexto(Descripcion),
    ciudad        = dbo.fn_LimpiarTexto(ciudad),
    pais          = dbo.fn_LimpiarTexto(pais),
    region        = dbo.fn_LimpiarTexto(region),
    codigo_postal = dbo.fn_LimpiarTexto(codigo_postal);

UPDATE dbo.stg_empleado
SET nombre    = dbo.fn_LimpiarTexto(nombre),
    apellido1 = dbo.fn_LimpiarTexto(apellido1),
    apellido2 = dbo.fn_LimpiarTexto(apellido2),
    email     = dbo.fn_LimpiarTexto(email),
    puesto    = dbo.fn_LimpiarTexto(puesto);

UPDATE dbo.stg_categoria
SET Desc_Categoria = dbo.fn_LimpiarTexto(Desc_Categoria);

UPDATE dbo.stg_cliente
SET nombre_cliente = dbo.fn_LimpiarTexto(nombre_cliente),
    ciudad         = dbo.fn_LimpiarTexto(ciudad),
    region         = dbo.fn_LimpiarTexto(region),
    pais           = dbo.fn_LimpiarTexto(pais),
    codigo_postal  = dbo.fn_LimpiarTexto(codigo_postal);

UPDATE dbo.stg_pedido
SET estado = dbo.fn_LimpiarTexto(estado);

UPDATE dbo.stg_producto
SET CodigoProducto = dbo.fn_LimpiarTexto(CodigoProducto),
    nombre         = dbo.fn_LimpiarTexto(nombre),
    dimensiones    = dbo.fn_LimpiarTexto(dimensiones),
    proveedor      = dbo.fn_LimpiarTexto(proveedor);

/* ---------------------------------------------------------------------
   3.2 NORMALIZACIÓN: un mismo valor escrito de una sola forma.
   --------------------------------------------------------------------- */
-- País: el origen mezcla inglés y español (Spain/España, USA/EEUU, ...)
UPDATE dbo.stg_cliente
SET pais = CASE UPPER(pais)
               WHEN 'SPAIN' THEN 'España'           WHEN 'ESPAÑA' THEN 'España'
               WHEN 'USA' THEN 'Estados Unidos'     WHEN 'EEUU' THEN 'Estados Unidos'
               WHEN 'UNITED KINGDOM' THEN 'Reino Unido' WHEN 'INGLATERRA' THEN 'Reino Unido'
               WHEN 'FRANCE' THEN 'Francia'         WHEN 'FRANCIA' THEN 'Francia'
               WHEN 'JAPAN' THEN 'Japón'            WHEN 'JAPÓN' THEN 'Japón'
               ELSE pais
           END;

UPDATE dbo.stg_oficina
SET pais = CASE UPPER(pais)
               WHEN 'SPAIN' THEN 'España'           WHEN 'ESPAÑA' THEN 'España'
               WHEN 'USA' THEN 'Estados Unidos'     WHEN 'EEUU' THEN 'Estados Unidos'
               WHEN 'UNITED KINGDOM' THEN 'Reino Unido' WHEN 'INGLATERRA' THEN 'Reino Unido'
               WHEN 'FRANCE' THEN 'Francia'         WHEN 'FRANCIA' THEN 'Francia'
               WHEN 'JAPAN' THEN 'Japón'            WHEN 'JAPÓN' THEN 'Japón'
               ELSE pais
           END;

-- Categoría: nombres sin tilde en el origen
UPDATE dbo.stg_categoria
SET Desc_Categoria = CASE UPPER(Desc_Categoria)
                         WHEN 'HERBACEAS'  THEN 'Herbáceas'
                         WHEN 'AROMATICAS' THEN 'Aromáticas'
                         ELSE Desc_Categoria
                     END;

-- Estado del pedido: primera letra en mayúscula
UPDATE dbo.stg_pedido
SET estado = CASE UPPER(estado)
                 WHEN 'ENTREGADO' THEN 'Entregado'
                 WHEN 'PENDIENTE' THEN 'Pendiente'
                 WHEN 'RECHAZADO' THEN 'Rechazado'
                 ELSE estado
             END;

-- Correo en minúsculas
UPDATE dbo.stg_empleado
SET email = LOWER(email);

/* ---------------------------------------------------------------------
   3.3 CALIDAD DE DATOS
   --------------------------------------------------------------------- */
-- Pedidos con fechas que no cuadran: no se cambian (no se sabe cuál es
-- la fecha real), se marcan para que el análisis los pueda filtrar.
UPDATE dbo.stg_pedido
SET Observacion = NULLIF(CONCAT_WS('; ',
        CASE WHEN fecha_esperada < fecha_pedido THEN 'Fecha esperada anterior al pedido' END,
        CASE WHEN fecha_entrega  < fecha_pedido THEN 'Entrega anterior al pedido' END,
        CASE WHEN estado = 'Entregado' AND fecha_entrega IS NULL THEN 'Entregado sin fecha de entrega' END,
        CASE WHEN estado <> 'Entregado' AND fecha_entrega IS NOT NULL THEN 'Fecha de entrega en pedido no entregado' END
    ), '');

-- Líneas de detalle repetidas (mismo pedido, producto, cantidad, precio
-- y número de línea): se conserva la primera y las demás se excluyen.
UPDATE dbo.stg_detalle_pedido
SET Observacion = 'Línea duplicada: se excluye'
WHERE ID_detalle_pedido IN (
    SELECT x.ID_detalle_pedido
    FROM (
        SELECT ID_detalle_pedido,
               ROW_NUMBER() OVER (PARTITION BY ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea
                                  ORDER BY ID_detalle_pedido) AS Repeticion
        FROM dbo.stg_detalle_pedido
    ) AS x
    WHERE x.Repeticion > 1
);

/* ---------------------------------------------------------------------
   3.4 ENRIQUECIMIENTO: tablas tr_ listas para el data mart
   --------------------------------------------------------------------- */
TRUNCATE TABLE dbo.tr_dim_tiempo;
TRUNCATE TABLE dbo.tr_dim_producto;
TRUNCATE TABLE dbo.tr_dim_cliente;
TRUNCATE TABLE dbo.tr_dim_empleado;
TRUNCATE TABLE dbo.tr_dim_oficina;
TRUNCATE TABLE dbo.tr_dim_pedido;
TRUNCATE TABLE dbo.tr_hechos_ventas;

-- Dim_Tiempo: calendario generado, un día por fila, desde el 1 de enero
-- del primer año con pedidos hasta el 31 de diciembre del último.
-- El día de la semana se calcula desde el 01/01/1900 (lunes), así no
-- depende del idioma ni de SET DATEFIRST del servidor.
WITH Fechas AS (
    SELECT DATEFROMPARTS(YEAR(MIN(fecha_pedido)), 1, 1)   AS Fecha,
           DATEFROMPARTS(YEAR(MAX(fecha_pedido)), 12, 31) AS Fecha_Fin
    FROM dbo.stg_pedido
    UNION ALL
    SELECT DATEADD(DAY, 1, Fecha), Fecha_Fin
    FROM Fechas
    WHERE Fecha < Fecha_Fin
)
INSERT INTO dbo.tr_dim_tiempo (SK_Tiempo, Fecha, Anio, Trimestre, Mes, Nombre_Mes, Dia, Nombre_Dia, Semana_Anio, Fin_Semana)
SELECT YEAR(Fecha) * 10000 + MONTH(Fecha) * 100 + DAY(Fecha),
       Fecha,
       YEAR(Fecha),
       (MONTH(Fecha) + 2) / 3,
       MONTH(Fecha),
       CASE MONTH(Fecha)
            WHEN 1 THEN 'Enero'  WHEN 2 THEN 'Febrero'   WHEN 3 THEN 'Marzo'      WHEN 4 THEN 'Abril'
            WHEN 5 THEN 'Mayo'   WHEN 6 THEN 'Junio'     WHEN 7 THEN 'Julio'      WHEN 8 THEN 'Agosto'
            WHEN 9 THEN 'Septiembre' WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' ELSE 'Diciembre'
       END,
       DAY(Fecha),
       CASE DATEDIFF(DAY, '19000101', Fecha) % 7
            WHEN 0 THEN 'Lunes'   WHEN 1 THEN 'Martes' WHEN 2 THEN 'Miércoles' WHEN 3 THEN 'Jueves'
            WHEN 4 THEN 'Viernes' WHEN 5 THEN 'Sábado' ELSE 'Domingo'
       END,
       DATEPART(ISO_WEEK, Fecha),
       CASE WHEN DATEDIFF(DAY, '19000101', Fecha) % 7 IN (5, 6) THEN 'Sí' ELSE 'No' END
FROM Fechas
OPTION (MAXRECURSION 0);

-- Dim_Producto: une producto con su categoría (evita el copo de nieve)
INSERT INTO dbo.tr_dim_producto (ID_Producto, Codigo_Producto, Nombre_Producto, ID_Categoria, Desc_Categoria,
                                 Proveedor, Dimensiones, Precio_Venta, Precio_Proveedor, Margen_Unitario)
SELECT p.ID_producto,
       p.CodigoProducto,
       p.nombre,
       p.Categoria,
       COALESCE(c.Desc_Categoria, 'Sin categoría'),
       COALESCE(p.proveedor, 'Sin dato'),
       COALESCE(p.dimensiones, 'Sin dato'),
       p.precio_venta,
       p.precio_proveedor,
       p.precio_venta - p.precio_proveedor
FROM dbo.stg_producto p
LEFT JOIN dbo.stg_categoria c ON c.Id_Categoria = p.Categoria;

-- Dim_Cliente
INSERT INTO dbo.tr_dim_cliente (ID_Cliente, Nombre_Cliente, Ciudad, Region, Pais, Limite_Credito)
SELECT ID_cliente,
       nombre_cliente,
       COALESCE(ciudad, 'Sin dato'),
       COALESCE(region, 'Sin dato'),
       COALESCE(pais, 'Sin dato'),
       COALESCE(limite_credito, 0)
FROM dbo.stg_cliente;

-- Dim_Empleado: nombre completo y nombre del jefe (autorrelación)
INSERT INTO dbo.tr_dim_empleado (ID_Empleado, Nombre_Completo, Puesto, Email, Jefe)
SELECT e.ID_empleado,
       CONCAT_WS(' ', e.nombre, e.apellido1, e.apellido2),
       COALESCE(e.puesto, 'Sin dato'),
       COALESCE(e.email, 'Sin dato'),
       CASE WHEN j.ID_empleado IS NULL THEN 'Sin jefe'
            ELSE CONCAT_WS(' ', j.nombre, j.apellido1, j.apellido2) END
FROM dbo.stg_empleado e
LEFT JOIN dbo.stg_empleado j ON j.ID_empleado = e.ID_jefe;

-- Dim_Oficina
INSERT INTO dbo.tr_dim_oficina (ID_Oficina, Descripcion, Ciudad, Region, Pais, Codigo_Postal)
SELECT ID_oficina,
       Descripcion,
       COALESCE(ciudad, 'Sin dato'),
       COALESCE(region, 'Sin dato'),
       COALESCE(pais, 'Sin dato'),
       COALESCE(codigo_postal, 'Sin dato')
FROM dbo.stg_oficina;

-- Dim_Pedido: indicadores de entrega derivados de las fechas
-- (Dias_Retraso negativo = el pedido llegó antes de lo esperado)
INSERT INTO dbo.tr_dim_pedido (ID_Pedido, Estado, Fecha_Pedido, Fecha_Esperada, Fecha_Entrega,
                               Entrega_A_Tiempo, Dias_Retraso, Calidad_Fechas)
SELECT ID_pedido,
       estado,
       fecha_pedido,
       fecha_esperada,
       fecha_entrega,
       CASE WHEN estado = 'Entregado' AND fecha_entrega IS NOT NULL AND fecha_entrega <= fecha_esperada THEN 'Sí'
            WHEN estado = 'Entregado' AND fecha_entrega IS NOT NULL THEN 'No'
            ELSE 'No aplica' END,
       CASE WHEN estado = 'Entregado' AND fecha_entrega IS NOT NULL
            THEN DATEDIFF(DAY, fecha_esperada, fecha_entrega) END,
       COALESCE(Observacion, 'OK')
FROM dbo.stg_pedido;

-- Hechos: una fila por línea de pedido. El empleado y la oficina se
-- obtienen por la ruta pedido -> cliente -> representante -> oficina.
-- El precio es el de la línea (histórico), no el precio actual.
INSERT INTO dbo.tr_hechos_ventas (ID_Detalle_Pedido, ID_Pedido, ID_Producto, ID_Cliente, ID_Empleado, ID_Oficina,
                                  SK_Tiempo, Numero_Linea, Cantidad, Precio_Unitario,
                                  Importe_Linea, Costo_Linea, Margen_Linea)
SELECT d.ID_detalle_pedido,
       d.ID_pedido,
       d.ID_producto,
       p.ID_cliente,
       c.ID_empleado_rep_ventas,
       e.ID_oficina,
       YEAR(p.fecha_pedido) * 10000 + MONTH(p.fecha_pedido) * 100 + DAY(p.fecha_pedido),
       d.numero_linea,
       d.cantidad,
       d.precio_unidad,
       d.cantidad * d.precio_unidad,
       d.cantidad * pr.precio_proveedor,
       d.cantidad * d.precio_unidad - d.cantidad * pr.precio_proveedor
FROM dbo.stg_detalle_pedido d
JOIN dbo.stg_pedido p    ON p.ID_pedido = d.ID_pedido
JOIN dbo.stg_producto pr ON pr.ID_producto = d.ID_producto
LEFT JOIN dbo.stg_cliente c  ON c.ID_cliente = p.ID_cliente
LEFT JOIN dbo.stg_empleado e ON e.ID_empleado = c.ID_empleado_rep_ventas
WHERE d.Observacion IS NULL;

COMMIT TRANSACTION;

-- Bitácora de la transformación
INSERT INTO dbo.stg_control_carga (Etapa, Tabla, Filas_Origen, Filas_Destino, Resultado)
SELECT 'Transformación', c.Tabla, c.Origen, c.Destino,
       CASE WHEN c.Origen = c.Destino THEN 'OK' ELSE 'REVISAR' END
FROM (
    SELECT 'tr_dim_tiempo' AS Tabla,
           (SELECT DATEDIFF(DAY, DATEFROMPARTS(YEAR(MIN(fecha_pedido)), 1, 1),
                                 DATEFROMPARTS(YEAR(MAX(fecha_pedido)), 12, 31)) + 1
            FROM dbo.stg_pedido) AS Origen,
           (SELECT COUNT(*) FROM dbo.tr_dim_tiempo) AS Destino
    UNION ALL SELECT 'tr_dim_producto', (SELECT COUNT(*) FROM dbo.stg_producto), (SELECT COUNT(*) FROM dbo.tr_dim_producto)
    UNION ALL SELECT 'tr_dim_cliente',  (SELECT COUNT(*) FROM dbo.stg_cliente),  (SELECT COUNT(*) FROM dbo.tr_dim_cliente)
    UNION ALL SELECT 'tr_dim_empleado', (SELECT COUNT(*) FROM dbo.stg_empleado), (SELECT COUNT(*) FROM dbo.tr_dim_empleado)
    UNION ALL SELECT 'tr_dim_oficina',  (SELECT COUNT(*) FROM dbo.stg_oficina),  (SELECT COUNT(*) FROM dbo.tr_dim_oficina)
    UNION ALL SELECT 'tr_dim_pedido',   (SELECT COUNT(*) FROM dbo.stg_pedido),   (SELECT COUNT(*) FROM dbo.tr_dim_pedido)
    UNION ALL SELECT 'tr_hechos_ventas',
           (SELECT COUNT(*) FROM dbo.stg_detalle_pedido WHERE Observacion IS NULL),
           (SELECT COUNT(*) FROM dbo.tr_hechos_ventas)
) AS c;

SELECT TOP (7) Etapa, Tabla, Filas_Origen, Filas_Destino, Resultado
FROM dbo.stg_control_carga
WHERE Etapa = 'Transformación'
ORDER BY ID_Control DESC;

-- Verificación de las reglas de transformación (las primeras deben dar 0)
SELECT r.Regla, r.Casos,
       CASE WHEN r.Regla LIKE 'Info:%' THEN 'INFO' WHEN r.Casos = 0 THEN 'OK' ELSE 'REVISAR' END AS Resultado
FROM (
    SELECT 'Países sin normalizar' AS Regla, COUNT(*) AS Casos
    FROM (SELECT pais FROM dbo.stg_cliente UNION ALL SELECT pais FROM dbo.stg_oficina) AS x
    WHERE pais NOT IN ('España', 'Estados Unidos', 'Reino Unido', 'Francia', 'Australia', 'Japón')
    UNION ALL
    SELECT 'Nombres con tildes dañadas, comillas escapadas o espacios dobles', COUNT(*)
    FROM dbo.tr_dim_producto
    WHERE Nombre_Producto COLLATE Latin1_General_BIN2 LIKE '%Ã%'
       OR Nombre_Producto COLLATE Latin1_General_BIN2 LIKE '%Â%'
       OR CHARINDEX('\', Nombre_Producto) > 0
       OR CHARINDEX('  ', Nombre_Producto COLLATE Latin1_General_BIN2) > 0
    UNION ALL
    SELECT 'Hechos sin empleado u oficina', COUNT(*)
    FROM dbo.tr_hechos_ventas
    WHERE ID_Empleado IS NULL OR ID_Oficina IS NULL
    UNION ALL
    SELECT 'Hechos con importe mal calculado', COUNT(*)
    FROM dbo.tr_hechos_ventas
    WHERE Importe_Linea <> Cantidad * Precio_Unitario
    UNION ALL
    SELECT 'Info: pedidos marcados por fechas inconsistentes', COUNT(*)
    FROM dbo.stg_pedido WHERE Observacion IS NOT NULL
    UNION ALL
    SELECT 'Info: líneas duplicadas excluidas', COUNT(*)
    FROM dbo.stg_detalle_pedido WHERE Observacion IS NOT NULL
    UNION ALL
    SELECT 'Info: líneas vendidas por debajo del costo', COUNT(*)
    FROM dbo.tr_hechos_ventas WHERE Margen_Linea < 0
) AS r;
GO
