SET NOCOUNT ON;
PRINT '##### V0 SURUM';
SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar(40)) AS surum;
GO
IF DB_ID('qs_demo') IS NOT NULL BEGIN ALTER DATABASE qs_demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_demo; END
CREATE DATABASE qs_demo;
GO
USE qs_demo;
GO
CREATE TABLE dbo.T(id int IDENTITY PRIMARY KEY, k int NOT NULL, v char(100) NOT NULL DEFAULT 'x');
INSERT dbo.T(k) SELECT TOP (20000) ABS(CHECKSUM(NEWID())) % 1000 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
GO
CREATE PROCEDURE dbo.Say @k int AS BEGIN DECLARE @a int; SELECT @a = COUNT(*) FROM dbo.T WHERE k = @k; END
GO
PRINT '##### V1 KAPATMA SECENEKLERI: veri ne oluyor';
ALTER DATABASE qs_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, INTERVAL_LENGTH_MINUTES = 1);
GO
DECLARE @i int = 0; WHILE @i < 50 BEGIN EXEC dbo.Say @i; SET @i += 1; END
EXEC sys.sp_query_store_flush_db;
SELECT '1 READ_WRITE, 50 cagri' AS an, (SELECT COUNT(*) FROM sys.query_store_query) AS sorgu_sayisi, (SELECT SUM(count_executions) FROM sys.query_store_runtime_stats rs JOIN sys.query_store_plan p ON p.plan_id=rs.plan_id JOIN sys.query_store_query q ON q.query_id=p.query_id WHERE q.object_id = OBJECT_ID('dbo.Say')) AS say_calistirma, (SELECT actual_state_desc FROM sys.database_query_store_options) AS durum;
GO
ALTER DATABASE qs_demo SET QUERY_STORE (OPERATION_MODE = READ_ONLY);
GO
DECLARE @i int = 0; WHILE @i < 50 BEGIN EXEC dbo.Say @i; SET @i += 1; END
DECLARE @x int; SELECT @x = COUNT(*) FROM dbo.T WHERE id = 1 AND 1 = 1 /* yeni_sorgu_a */;
EXEC sys.sp_query_store_flush_db;
SELECT '2 READ_ONLY, 50 cagri daha' AS an, (SELECT COUNT(*) FROM sys.query_store_query) AS sorgu_sayisi, (SELECT SUM(count_executions) FROM sys.query_store_runtime_stats rs JOIN sys.query_store_plan p ON p.plan_id=rs.plan_id JOIN sys.query_store_query q ON q.query_id=p.query_id WHERE q.object_id = OBJECT_ID('dbo.Say')) AS say_calistirma, (SELECT actual_state_desc FROM sys.database_query_store_options) AS durum;
GO
ALTER DATABASE qs_demo SET QUERY_STORE (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = NONE);
GO
DECLARE @i int = 0; WHILE @i < 50 BEGIN EXEC dbo.Say @i; SET @i += 1; END
DECLARE @x int; SELECT @x = COUNT(*) FROM dbo.T WHERE id = 2 AND 2 = 2 /* yeni_sorgu_b */;
EXEC sys.sp_query_store_flush_db;
SELECT '3 capture NONE, 50 cagri daha' AS an, (SELECT COUNT(*) FROM sys.query_store_query) AS sorgu_sayisi, (SELECT SUM(count_executions) FROM sys.query_store_runtime_stats rs JOIN sys.query_store_plan p ON p.plan_id=rs.plan_id JOIN sys.query_store_query q ON q.query_id=p.query_id WHERE q.object_id = OBJECT_ID('dbo.Say')) AS say_calistirma, (SELECT actual_state_desc FROM sys.database_query_store_options) AS durum;
GO
ALTER DATABASE qs_demo SET QUERY_STORE = OFF;
GO
SELECT '4 OFF' AS an, (SELECT actual_state_desc FROM sys.database_query_store_options) AS durum;
GO
BEGIN TRY
  SELECT '4 OFF iken okuma' AS an, COUNT(*) AS sorgu_sayisi FROM sys.query_store_query;
END TRY BEGIN CATCH PRINT 'OFF iken okuma hatasi: ' + CAST(ERROR_NUMBER() AS varchar(10)) + ' ' + ERROR_MESSAGE(); END CATCH
GO
ALTER DATABASE qs_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
SELECT '5 yeniden ON' AS an, (SELECT COUNT(*) FROM sys.query_store_query) AS sorgu_sayisi, (SELECT SUM(count_executions) FROM sys.query_store_runtime_stats rs JOIN sys.query_store_plan p ON p.plan_id=rs.plan_id JOIN sys.query_store_query q ON q.query_id=p.query_id WHERE q.object_id = OBJECT_ID('dbo.Say')) AS say_calistirma, (SELECT actual_state_desc FROM sys.database_query_store_options) AS durum;
GO
BEGIN TRY
  ALTER DATABASE qs_demo SET QUERY_STORE = OFF (FORCED);
  SELECT '6 OFF (FORCED)' AS an, (SELECT actual_state_desc FROM sys.database_query_store_options) AS durum;
END TRY BEGIN CATCH PRINT 'OFF FORCED hatasi: ' + CAST(ERROR_NUMBER() AS varchar(10)) + ' ' + ERROR_MESSAGE(); END CATCH
GO
ALTER DATABASE qs_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
ALTER DATABASE qs_demo SET QUERY_STORE CLEAR;
GO
SELECT '7 CLEAR sonrasi' AS an, (SELECT COUNT(*) FROM sys.query_store_query) AS sorgu_sayisi;
GO
PRINT '##### V2 DEPOLAMA: 3000 farkli ad hoc sorgu ALL modda ne kadar yer tutar';
ALTER DATABASE qs_demo SET QUERY_STORE (QUERY_CAPTURE_MODE = ALL, MAX_STORAGE_SIZE_MB = 1000, SIZE_BASED_CLEANUP_MODE = AUTO);
GO
DECLARE @i int = 0, @sql nvarchar(max); CREATE TABLE #t(c int);
WHILE @i < 3000 BEGIN SET @sql = N'SELECT COUNT(*) AS a' + CAST(@i AS nvarchar(10)) + N' FROM dbo.T WHERE k = ' + CAST(@i % 1000 AS nvarchar(10)) + N' AND id > ' + CAST(@i AS nvarchar(10)); INSERT #t EXEC(@sql); SET @i += 1; END
EXEC sys.sp_query_store_flush_db;
GO
SELECT current_storage_size_mb AS depolama_mb, (SELECT COUNT(*) FROM sys.query_store_query) AS sorgu_sayisi, (SELECT COUNT(*) FROM sys.query_store_plan) AS plan_sayisi FROM sys.database_query_store_options;
GO
PRINT '##### V3 SURE ETKISI: 20000 kisa prosedur cagrisi, 3 tekrar (ms)';
GO
CREATE TABLE dbo.Sure(mod varchar(20), tekrar int, ms int);
GO
DECLARE @m TABLE(n int IDENTITY, mod varchar(20), sql nvarchar(400));
INSERT @m(mod, sql) VALUES
 ('OFF', N'ALTER DATABASE qs_demo SET QUERY_STORE = OFF'),
 ('AUTO', N'ALTER DATABASE qs_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = AUTO)'),
 ('ALL', N'ALTER DATABASE qs_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL)');
DECLARE @n int = 1, @mod varchar(20), @sql nvarchar(400), @r int, @i int, @t0 datetime2;
WHILE @n <= 3
BEGIN
  SELECT @mod = mod, @sql = sql FROM @m WHERE n = @n;
  EXEC(@sql);
  SET @r = 1;
  WHILE @r <= 3
  BEGIN
    SET @i = 0; SET @t0 = SYSDATETIME();
    WHILE @i < 20000 BEGIN EXEC dbo.Say @i % 1000; SET @i += 1; END
    INSERT dbo.Sure VALUES (@mod, @r, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
    SET @r += 1;
  END
  SET @n += 1;
END
SELECT mod, MIN(ms) AS en_hizli_ms, AVG(ms) AS ortalama_ms, MAX(ms) AS en_yavas_ms FROM dbo.Sure GROUP BY mod ORDER BY CASE mod WHEN 'OFF' THEN 1 WHEN 'AUTO' THEN 2 ELSE 3 END;
GO
PRINT '##### BITTI';
