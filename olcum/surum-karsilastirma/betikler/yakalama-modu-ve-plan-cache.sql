SET NOCOUNT ON;
PRINT '##### T0 SURUM';
SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar(40)) AS surum;
GO
IF DB_ID('qs_demo') IS NOT NULL BEGIN ALTER DATABASE qs_demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_demo; END
CREATE DATABASE qs_demo;
GO
USE qs_demo;
GO
CREATE TABLE dbo.Siparis(id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL);
INSERT dbo.Siparis(musteri_id, tutar) SELECT TOP (20000) ABS(CHECKSUM(NEWID())) % 500, ABS(CHECKSUM(NEWID())) % 1000 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
GO
CREATE PROCEDURE dbo.SiparisSay @m int AS BEGIN DECLARE @a int; SELECT @a = COUNT(*) FROM dbo.Siparis WHERE musteri_id = @m; END
GO
DECLARE @i int = 0; WHILE @i < 20 BEGIN EXEC dbo.SiparisSay @i; SET @i += 1; END
GO
PRINT '##### T1 QUERY STORE AYARI DEGISINCE PROSEDUR PLANLARI (plan cache)';
SELECT 'once' AS an, COUNT(*) AS cache_plan_sayisi FROM sys.dm_exec_cached_plans cp CROSS APPLY sys.dm_exec_plan_attributes(cp.plan_handle) pa WHERE pa.attribute = 'dbid' AND CAST(pa.value AS int) = DB_ID() AND cp.objtype = 'Proc';
GO
ALTER DATABASE qs_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
GO
SELECT 'QS ON sonrasi' AS an, COUNT(*) AS cache_plan_sayisi FROM sys.dm_exec_cached_plans cp CROSS APPLY sys.dm_exec_plan_attributes(cp.plan_handle) pa WHERE pa.attribute = 'dbid' AND CAST(pa.value AS int) = DB_ID() AND cp.objtype = 'Proc';
GO
DECLARE @i int = 0; WHILE @i < 20 BEGIN EXEC dbo.SiparisSay @i; SET @i += 1; END
GO
ALTER DATABASE qs_demo SET QUERY_STORE (INTERVAL_LENGTH_MINUTES = 30);
GO
SELECT 'ayar degisikligi sonrasi' AS an, COUNT(*) AS cache_plan_sayisi FROM sys.dm_exec_cached_plans cp CROSS APPLY sys.dm_exec_plan_attributes(cp.plan_handle) pa WHERE pa.attribute = 'dbid' AND CAST(pa.value AS int) = DB_ID() AND cp.objtype = 'Proc';
GO
ALTER DATABASE qs_demo SET QUERY_STORE = OFF;
GO
SELECT 'QS OFF sonrasi' AS an, COUNT(*) AS cache_plan_sayisi FROM sys.dm_exec_cached_plans cp CROSS APPLY sys.dm_exec_plan_attributes(cp.plan_handle) pa WHERE pa.attribute = 'dbid' AND CAST(pa.value AS int) = DB_ID() AND cp.objtype = 'Proc';
GO
PRINT '##### T2 OTOMATIK PARAMETRELENDIRME QS METNI';
ALTER DATABASE qs_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
ALTER DATABASE qs_demo SET QUERY_STORE CLEAR;
GO
DECLARE @x int;
SELECT @x = COUNT(*) FROM dbo.Siparis WHERE id = 5;
SELECT @x = COUNT(*) FROM dbo.Siparis WHERE id = 6;
SELECT @x = COUNT(*) FROM dbo.Siparis WHERE id = 7;
GO
EXEC sys.sp_query_store_flush_db;
SELECT COUNT(*) AS farkli_metin FROM sys.query_store_query_text WHERE query_sql_text LIKE N'%Siparis%' AND query_sql_text NOT LIKE N'%query_store%';
SELECT query_sql_text FROM sys.query_store_query_text WHERE query_sql_text LIKE N'%Siparis%' AND query_sql_text NOT LIKE N'%query_store%';
GO
PRINT '##### T3 YAKALAMA MODU (300 tek seferlik + 1 sorgu 40 kez), sik sorgu = %sik% ile aranir';
DECLARE @modlar TABLE(n int IDENTITY, m varchar(10)); INSERT @modlar(m) VALUES ('ALL'),('AUTO'),('NONE');
DECLARE @sonuc TABLE(mod varchar(10), tek_seferlik int, sik_sorgu int);
CREATE TABLE #t(c int);
DECLARE @n int = 1, @m varchar(10), @sql nvarchar(max), @i int, @a int, @b int;
WHILE @n <= 3
BEGIN
  SELECT @m = m FROM @modlar WHERE n = @n;
  SET @sql = N'ALTER DATABASE qs_demo SET QUERY_STORE CLEAR; ALTER DATABASE qs_demo SET QUERY_STORE (QUERY_CAPTURE_MODE = ' + @m + N')';
  EXEC(@sql);
  SET @i = 0;
  WHILE @i < 300 BEGIN SET @sql = N'SELECT COUNT(*) AS tek' + CAST(@i AS nvarchar(10)) + N' FROM dbo.Siparis WHERE id = ' + CAST(@i + 100 AS nvarchar(10)); INSERT #t EXEC(@sql); SET @i += 1; END
  SET @i = 0;
  WHILE @i < 40 BEGIN SET @sql = N'SELECT COUNT(*) AS sikcalisan FROM dbo.Siparis WHERE musteri_id > ' + CAST(@i AS nvarchar(10)); INSERT #t EXEC(@sql); SET @i += 1; END
  EXEC sys.sp_query_store_flush_db;
  SELECT @a = COUNT(DISTINCT query_text_id) FROM sys.query_store_query_text WHERE query_sql_text LIKE N'%tek[0-9]%';
  SELECT @b = COUNT(DISTINCT query_text_id) FROM sys.query_store_query_text WHERE query_sql_text LIKE N'%sikcalisan%';
  INSERT @sonuc VALUES (@m, @a, @b);
  SET @n += 1;
END
SELECT * FROM @sonuc;
GO
PRINT '##### BITTI';
