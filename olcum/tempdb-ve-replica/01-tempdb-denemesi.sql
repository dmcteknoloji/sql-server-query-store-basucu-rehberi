SET NOCOUNT ON;
SELECT @@VERSION AS surum;
GO
IF DB_ID('td_ref') IS NOT NULL BEGIN ALTER DATABASE td_ref SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE td_ref; END
GO
CREATE DATABASE td_ref;
GO
ALTER DATABASE td_ref SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
PRINT '#### 1. baslangic, sistem veritabanlari';
SELECT database_id, name, is_query_store_on FROM sys.databases WHERE database_id <= 4 OR name = 'td_ref' ORDER BY database_id;
SELECT 'tempdb' AS vt, desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb, query_capture_mode_desc FROM tempdb.sys.database_query_store_options;
SELECT 'td_ref' AS vt, desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb, query_capture_mode_desc FROM td_ref.sys.database_query_store_options;
SELECT wait_type, waiting_tasks_count, wait_time_ms FROM sys.dm_os_wait_stats WHERE wait_type = 'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP';
GO
PRINT '#### 2. ALTER DATABASE tempdb SET QUERY_STORE = ON';
BEGIN TRY ALTER DATABASE tempdb SET QUERY_STORE = ON; SELECT 'kabul edildi' AS sonuc; END TRY BEGIN CATCH SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata; END CATCH
SELECT database_id, name, is_query_store_on FROM sys.databases WHERE database_id = 2;
SELECT 'tempdb' AS vt, desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb, max_storage_size_mb, query_capture_mode_desc FROM tempdb.sys.database_query_store_options;
BEGIN TRY ALTER DATABASE tempdb SET QUERY_STORE (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL); SELECT 'ayar kabul edildi' AS sonuc; END TRY BEGIN CATCH SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata; END CATCH
SELECT 'tempdb' AS vt, desired_state_desc, actual_state_desc, readonly_reason, query_capture_mode_desc FROM tempdb.sys.database_query_store_options;
GO
PRINT '#### 3. is yuku, tempdb icinde (gecici tablo ve kalici tablo) ve referans veritabani';
USE tempdb;
CREATE TABLE #g (id int PRIMARY KEY, k int);
INSERT #g SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)), 1 FROM sys.all_objects;
CREATE TABLE dbo.td_kalici (id int PRIMARY KEY, k int);
INSERT dbo.td_kalici SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)), 1 FROM sys.all_objects;
DECLARE @i int = 0, @s nvarchar(300);
WHILE @i < 300 BEGIN
  SET @s = N'SELECT COUNT(*) FROM #g WHERE id > ' + CAST(@i AS nvarchar(10)) + N' AND k = 1'; EXEC (@s);
  SET @s = N'SELECT COUNT(*) FROM dbo.td_kalici WHERE id > ' + CAST(@i AS nvarchar(10)) + N' AND k = 1'; EXEC (@s);
  SET @i += 1;
END
GO
USE td_ref;
CREATE TABLE dbo.k (id int PRIMARY KEY, k int);
INSERT dbo.k SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)), 1 FROM sys.all_objects;
DECLARE @i int = 0, @s nvarchar(300);
WHILE @i < 300 BEGIN
  SET @s = N'SELECT COUNT(*) FROM dbo.k WHERE id > ' + CAST(@i AS nvarchar(10)) + N' AND k = 1'; EXEC (@s);
  SET @i += 1;
END
GO
BEGIN TRY EXEC tempdb.sys.sp_query_store_flush_db; SELECT 'tempdb flush kabul' AS sonuc; END TRY BEGIN CATCH SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata; END CATCH
BEGIN TRY EXEC td_ref.sys.sp_query_store_flush_db; SELECT 'td_ref flush kabul' AS sonuc; END TRY BEGIN CATCH SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata; END CATCH
WAITFOR DELAY '00:00:03';
GO
PRINT '#### 4. kayit sayilari';
SELECT 'tempdb' AS vt, (SELECT COUNT(*) FROM tempdb.sys.query_store_query) AS query_sayisi, (SELECT COUNT(*) FROM tempdb.sys.query_store_plan) AS plan_sayisi, (SELECT COUNT(*) FROM tempdb.sys.query_store_runtime_stats) AS runtime_satiri
UNION ALL SELECT 'td_ref', (SELECT COUNT(*) FROM td_ref.sys.query_store_query), (SELECT COUNT(*) FROM td_ref.sys.query_store_plan), (SELECT COUNT(*) FROM td_ref.sys.query_store_runtime_stats);
SELECT 'tempdb' AS vt, desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb FROM tempdb.sys.database_query_store_options;
SELECT 'td_ref' AS vt, desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb FROM td_ref.sys.database_query_store_options;
SELECT wait_type, waiting_tasks_count, wait_time_ms FROM sys.dm_os_wait_stats WHERE wait_type = 'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP';
GO
PRINT '#### 5. tempdb Query Store islemleri';
BEGIN TRY ALTER DATABASE tempdb SET QUERY_STORE CLEAR; SELECT 'CLEAR kabul' AS sonuc; END TRY BEGIN CATCH SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata; END CATCH
BEGIN TRY ALTER DATABASE tempdb SET QUERY_STORE = OFF; SELECT 'OFF kabul' AS sonuc; END TRY BEGIN CATCH SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata; END CATCH
SELECT database_id, name, is_query_store_on FROM sys.databases WHERE database_id = 2;
BEGIN TRY ALTER DATABASE tempdb SET QUERY_STORE = ON; SELECT 'ON (ikinci) kabul' AS sonuc; END TRY BEGIN CATCH SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata; END CATCH
SELECT database_id, name, is_query_store_on FROM sys.databases WHERE database_id = 2;
GO
