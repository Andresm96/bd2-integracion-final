# Pruebas de verificación de calidad de datos (EA4)

El script `08_Pruebas_Calidad_Datos.sql` revisa la calidad de los datos en las tres capas del proyecto y guarda los resultados en la tabla `DM_Ventas_Jardineria.dbo.Calidad_Datos`.

Cada prueba cuenta cuántas filas tienen el problema:

| Resultado | Significado |
|---|---|
| **OK** | Ninguna fila tiene el problema. |
| **HALLAZGO** | Problema que trae la base de origen. La columna `Detalle` dice cómo lo trató el ETL. |
| **FALLA** | Problema que quedó en el staging o en el data mart (el ETL no lo corrigió). |

También calcula el porcentaje de calidad de cada prueba: filas sin problema ÷ filas revisadas.

## Cómo ejecutarlo

1. Tener creadas las tres bases (scripts `00` a `05` de la EA3).
2. Abrir `08_Pruebas_Calidad_Datos.sql` en Visual Studio Code (extensión SQL Server) o en SSMS, conectado a `localhost\SQLEXPRESS`.
3. Ejecutarlo. Salen dos resultados: el detalle de las 30 pruebas y el resumen por capa.

## Las 30 pruebas

| N.° | Capa | Dimensión | Prueba |
|---|---|---|---|
| 1 | Origen | Completitud | Clientes sin región |
| 2 | Origen | Completitud | Productos sin dimensiones |
| 3 | Origen | Completitud | Pedidos sin líneas de detalle |
| 4 | Origen | Completitud | Pedidos entregados sin fecha de entrega |
| 5 | Origen | Validez | Fecha esperada o de entrega antes del pedido |
| 6 | Origen | Consistencia | Pedidos no entregados con fecha de entrega |
| 7 | Origen | Unicidad | Líneas de pedido repetidas |
| 8 | Origen | Integridad referencial | Referencias a registros que no existen (6 relaciones) |
| 9 | Origen | Validez | Cantidad o precio en cero o negativo |
| 10 | Origen | Exactitud | Líneas vendidas por debajo del costo |
| 11 | Origen | Formato | País escrito de forma no estándar |
| 12 | Origen | Formato | Nombres de producto con espacios sobrantes |
| 13 | Origen | Formato | Textos con tildes dañadas |
| 14 | Staging | Formato | País fuera de la lista oficial |
| 15 | Staging | Validez | Estado del pedido fuera de la lista |
| 16 | Staging | Consistencia | Pedidos con fechas que no cuadran y sin marcar |
| 17 | Staging | Unicidad | Líneas repetidas que no se marcaron para excluir |
| 18 | Staging | Formato | Textos con espacios sobrantes o tildes dañadas |
| 19 | Data mart | Completitud | Hechos con dimensión desconocida (-1) |
| 20 | Data mart | Integridad referencial | Hechos sin su fila en alguna dimensión |
| 21 | Data mart | Unicidad | Claves naturales repetidas en las dimensiones |
| 22 | Data mart | Unicidad | Mismo producto repetido en un pedido |
| 23 | Data mart | Validez | Cantidad o precio en cero o negativo |
| 24 | Data mart | Validez | Días que faltan en el calendario |
| 25 | Data mart | Exactitud | Importe distinto de cantidad × precio |
| 26 | Data mart | Exactitud | Margen distinto de importe menos costo |
| 27 | Data mart | Consistencia | Filas de hechos = líneas del origen |
| 28 | Data mart | Consistencia | Unidades vendidas cuadran con el origen |
| 29 | Data mart | Consistencia | Importe total cuadra con el origen |
| 30 | Data mart | Trazabilidad | Pasos del ETL que no terminaron en OK |

> Nota técnica: el servidor usa la intercalación `Latin1_General_CI_AI`, que no distingue tildes. Por eso las pruebas de formato comparan con `COLLATE Latin1_General_BIN2`; si no, una «Ã» dañada pasaría por una «a» normal.

## Resultados (ejecución del 26 de noviembre de 2026)

Ejecuté el script en SQL Server 2025 Express (`localhost\SQLEXPRESS`) desde Visual Studio Code; terminó en 598 ms. Los pantallazos están en `resultados/`:

- `01_resultados_y_resumen_por_capa.png`: la ejecución en VS Code, con el detalle y el resumen por capa.
- `02_detalle_con_resultados.png`: el detalle con las columnas de filas con problema, calidad, resultado y detalle.

### Resumen por capa

| Capa | Pruebas | OK | Hallazgos | Fallas | Calidad promedio |
|---|---|---|---|---|---|
| 1. Origen | 13 | 2 | 11 | 0 | 86,7 % |
| 2. Staging | 5 | 5 | 0 | 0 | 100,0 % |
| 3. Data mart | 12 | 12 | 0 | 0 | 100,0 % |

### Detalle

| N.° | Prueba | Filas revisadas | Filas con problema | Calidad | Resultado |
|---|---|---|---|---|---|
| 1 | Clientes sin región | 36 | 5 | 86,1 % | HALLAZGO |
| 2 | Productos sin dimensiones | 276 | 62 | 77,5 % | HALLAZGO |
| 3 | Pedidos sin líneas de detalle | 115 | 13 | 88,7 % | HALLAZGO |
| 4 | Pedidos entregados sin fecha de entrega | 115 | 3 | 97,4 % | HALLAZGO |
| 5 | Fecha esperada o de entrega antes del pedido | 115 | 4 | 96,5 % | HALLAZGO |
| 6 | Pedidos no entregados con fecha de entrega | 115 | 16 | 86,1 % | HALLAZGO |
| 7 | Líneas de pedido repetidas | 318 | 1 | 99,7 % | HALLAZGO |
| 8 | Referencias a registros que no existen | 1.094 | 0 | 100,0 % | OK |
| 9 | Cantidad o precio en cero o negativo | 318 | 0 | 100,0 % | OK |
| 10 | Líneas vendidas por debajo del costo | 318 | 8 | 97,5 % | HALLAZGO |
| 11 | País escrito de forma no estándar | 45 | 37 | 17,8 % | HALLAZGO |
| 12 | Nombres de producto con espacios sobrantes | 276 | 54 | 80,4 % | HALLAZGO |
| 13 | Textos con tildes dañadas | 312 | 1 | 99,7 % | HALLAZGO |
| 14–18 | Las 5 pruebas del staging | — | 0 | 100,0 % | OK |
| 19–30 | Las 12 pruebas del data mart | — | 0 | 100,0 % | OK |

### Qué significan

- **La base de origen tiene problemas reales:** 22 pedidos con fechas que no cuadran (pruebas 4, 5 y 6), una línea de pedido repetida, países escritos de varias formas (Spain, USA, EEUU, Inglaterra…), nombres con espacios sobrantes, una tilde dañada y datos que faltan (región y dimensiones).
- **El ETL los resolvió:** en el staging y en el data mart no queda ningún problema. Los países y los textos quedaron normalizados, las fechas raras quedaron marcadas en `Dim_Pedido.Calidad_Fechas`, la línea repetida se excluyó y los datos que faltaban quedaron como «Sin dato».
- **El data mart es confiable:** no tiene hechos huérfanos ni repetidos, los importes y márgenes están bien calculados, el calendario no tiene huecos y los totales cuadran con el origen (317 líneas, 8.530 unidades y 217.038,00 de importe, sin la línea repetida).
- Las 8 líneas vendidas por debajo del costo (prueba 10) se dejaron como están porque son ventas reales: el margen de esas líneas queda negativo.
