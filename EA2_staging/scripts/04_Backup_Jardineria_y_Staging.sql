/* =====================================================================
   04_Backup_Jardineria_y_Staging.sql
   Genera el BK (copia de seguridad completa .bak) de las dos bases:
     - Jardineria.bak
     - Staging_Jardineria.bak

   Los archivos se guardan en la carpeta de copias de seguridad
   predeterminada de la instancia, porque SQL Server siempre tiene permiso
   de escritura allí. El script imprime la ruta exacta en la pestaña
   Mensajes. Si se quiere otra carpeta, cambie @Ruta por una que ya exista,
   por ejemplo N'C:\BK\'.

   Después de cada copia se ejecuta RESTORE VERIFYONLY, que confirma que el
   archivo .bak está completo y se puede restaurar.
   ===================================================================== */

USE master;
GO

DECLARE @Ruta NVARCHAR(260) = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(260));
IF @Ruta IS NULL SET @Ruta = N'C:\BK\';
IF RIGHT(@Ruta, 1) <> N'\' SET @Ruta = @Ruta + N'\';

DECLARE @ArchivoJardineria NVARCHAR(400) = @Ruta + N'Jardineria.bak';
DECLARE @ArchivoStaging    NVARCHAR(400) = @Ruta + N'Staging_Jardineria.bak';

/* 1. BK de la base transaccional */
BACKUP DATABASE jardineria
    TO DISK = @ArchivoJardineria
    WITH FORMAT, INIT, CHECKSUM, STATS = 25,
         NAME = N'Jardineria - copia completa';

RESTORE VERIFYONLY FROM DISK = @ArchivoJardineria WITH CHECKSUM;

/* 2. BK de la base Staging */
BACKUP DATABASE Staging_Jardineria
    TO DISK = @ArchivoStaging
    WITH FORMAT, INIT, CHECKSUM, STATS = 25,
         NAME = N'Staging_Jardineria - copia completa';

RESTORE VERIFYONLY FROM DISK = @ArchivoStaging WITH CHECKSUM;

PRINT N'BK generados en:';
PRINT @ArchivoJardineria;
PRINT @ArchivoStaging;
GO

/* Para restaurar una copia en otro equipo (ejemplo):
   RESTORE DATABASE Staging_Jardineria
       FROM DISK = N'C:\BK\Staging_Jardineria.bak'
       WITH REPLACE, RECOVERY;
*/
