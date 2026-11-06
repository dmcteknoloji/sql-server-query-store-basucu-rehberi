SET NOCOUNT ON;
SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar(40)) AS surum;
GO
PRINT '##### S1 varsayilan durum';
SELECT d.name, d.database_id, d.is_query_store_on FROM sys.databases d WHERE d.database_id <= 4 ORDER BY d.database_id;
GO
USE msdb;
SELECT 'msdb' AS db, actual_state_desc, desired_state_desc, readonly_reason, max_storage_size_mb, query_capture_mode_desc FROM sys.database_query_store_options;
GO
USE master;
SELECT 'master' AS db, actual_state_desc, desired_state_desc FROM sys.database_query_store_options;
GO
USE model;
SELECT 'model' AS db, actual_state_desc, desired_state_desc, max_storage_size_mb, query_capture_mode_desc FROM sys.database_query_store_options;
GO
PRINT '##### S2 msdb ve model icin ac';
BEGIN TRY ALTER DATABASE msdb SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = AUTO); PRINT 'msdb acildi'; END TRY BEGIN CATCH PRINT 'msdb hata ' + CAST(ERROR_NUMBER() AS varchar(10)) + ' ' + ERROR_MESSAGE(); END CATCH
BEGIN TRY ALTER DATABASE master SET QUERY_STORE = ON; PRINT 'master acildi'; END TRY BEGIN CATCH PRINT 'master hata ' + CAST(ERROR_NUMBER() AS varchar(10)) + ' ' + ERROR_MESSAGE(); END CATCH
GO
PRINT '##### S3 msdb is yukunu yakaliyor mu';
USE msdb;
GO
DECLARE @i int = 0, @x int;
WHILE @i < 60 BEGIN SELECT @x = COUNT(*) FROM msdb.dbo.backupset WHERE backup_finish_date > DATEADD(day, -30, GETDATE()); EXEC msdb.dbo.sp_help_job; SET @i += 1; END
EXEC sys.sp_query_store_flush_db;
GO
SELECT TOP (6) q.query_id, ISNULL(OBJECT_NAME(q.object_id), '(ad hoc)') AS nesne, SUM(rs.count_executions) AS calisma, CAST(AVG(rs.avg_duration)/1000.0 AS decimal(10,2)) AS ort_ms,
       LEFT(REPLACE(REPLACE(t.query_sql_text, CHAR(13), ' '), CHAR(10), ' '), 70) AS metin
FROM sys.query_store_query q JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id
JOIN sys.query_store_plan p ON p.query_id = q.query_id JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
GROUP BY q.query_id, q.object_id, t.query_sql_text ORDER BY SUM(rs.count_executions) DESC;
GO
SELECT 'msdb QS boyut' AS an, current_storage_size_mb, max_storage_size_mb, actual_state_desc FROM sys.database_query_store_options;
GO
PRINT '##### S4 model aciksa yeni db';
USE master;
IF DB_ID('yeni_db') IS NOT NULL DROP DATABASE yeni_db;
CREATE DATABASE yeni_db;
SELECT name, is_query_store_on FROM sys.databases WHERE name = 'yeni_db';
GO
DROP DATABASE yeni_db;
PRINT '##### BITTI';
