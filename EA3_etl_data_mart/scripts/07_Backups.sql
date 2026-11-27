/* =====================================================================
   07_Backups.sql
   EA3 - Proceso ETL Jardinería | COPIAS DE SEGURIDAD (BK)
   Crea un .bak completo de las tres bases trabajadas. Como solo se da el
   nombre del archivo, SQL Server lo guarda en su carpeta de backups por
   defecto; la última consulta muestra la ruta exacta para copiarlos a la
   carpeta BK de la entrega.
   ===================================================================== */
USE master;
GO

BACKUP DATABASE jardineria
TO DISK = N'Jardineria.bak'
WITH INIT, NAME = N'jardineria - copia completa (origen)', STATS = 25;

BACKUP DATABASE Staging_Jardineria
TO DISK = N'Staging_Jardineria.bak'
WITH INIT, NAME = N'Staging_Jardineria - copia completa', STATS = 25;

BACKUP DATABASE DM_Ventas_Jardineria
TO DISK = N'DM_Ventas_Jardineria.bak'
WITH INIT, NAME = N'DM_Ventas_Jardineria - copia completa (data mart)', STATS = 25;
GO

-- Ruta donde quedaron los archivos .bak
SELECT TOP (3) bs.database_name    AS Base_Datos,
               bmf.physical_device_name AS Archivo,
               bs.backup_finish_date    AS Fecha
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bmf.media_set_id = bs.media_set_id
ORDER BY bs.backup_finish_date DESC;
GO

/* Para restaurar una copia (ejemplo):
   RESTORE DATABASE DM_Ventas_Jardineria
   FROM DISK = N'C:\ruta\DM_Ventas_Jardineria.bak'
   WITH REPLACE;
*/
