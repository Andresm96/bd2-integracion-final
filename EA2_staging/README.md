# EA2. Creación de una base de datos de staging

Construcción de la base `Staging_Jardineria`, la zona intermedia donde se copian y limpian los datos de `jardineria` antes de llevarlos al data mart.

## Archivos

| Archivo | Contenido |
|---|---|
| `informe/EA2_Staging_Jardineria.pdf` | Informe de la evidencia. |
| `scripts/00_Jardineria_corregido.sql` | Base de origen con los INSERT corregidos (categoría por ID y códigos originales de clientes y pedidos). |
| `scripts/01_Crear_Staging_Jardineria.sql` | Crea `Staging_Jardineria`: 7 tablas `stg_` y la bitácora `stg_control_carga`. |
| `scripts/02_Cargar_Staging_Jardineria.sql` | Carga completa desde el origen (TRUNCATE + INSERT…SELECT en una transacción). |
| `scripts/03_Validar_Staging.sql` | 24 pruebas de validación entre el origen y el staging. |
| `scripts/04_Backup_Jardineria_y_Staging.sql` | Copias de seguridad de las dos bases. |
| `BK/` | Respaldo de las dos bases generado como script SQL. |

## Orden de ejecución

`00` → `01` → `02` → `03` → `04` en SQL Server (`localhost\SQLEXPRESS`).

> La EA3 retoma este staging y lo amplía con la transformación y la carga al data mart. Para reproducir el proyecto completo use los scripts de la carpeta `EA3_etl_data_mart`.
