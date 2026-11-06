-- Kitaptaki ornek cikti kutularinin uretildigi demo veritabanlari (qs_demo, ornek_kapali, ornek_dolu).
-- Bu betik veritabani olusturur ve siler. Yalnizca test sunucusunda calistirin.

SET NOCOUNT ON;
IF DB_ID('qs_demo') IS NOT NULL BEGIN ALTER DATABASE qs_demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_demo; END
CREATE DATABASE qs_demo;
GO
ALTER DATABASE qs_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, INTERVAL_LENGTH_MINUTES = 1, WAIT_STATS_CAPTURE_MODE = ON, DATA_FLUSH_INTERVAL_SECONDS = 60);
ALTER DATABASE qs_demo SET COMPATIBILITY_LEVEL = 150;
GO
USE qs_demo;
CREATE TABLE dbo.Siparis(id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, dolgu char(200) NOT NULL DEFAULT 'x');
;WITH n AS (SELECT TOP (200000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT dbo.Siparis(musteri_id, tutar) SELECT CASE WHEN i % 4 > 0 THEN 1 ELSE 2 + (i % 2000) END, i % 500 FROM n;
CREATE INDEX ix_musteri ON dbo.Siparis(musteri_id);
GO
CREATE PROCEDURE dbo.SiparisGetir @m int AS
BEGIN
  DECLARE @a int, @b decimal(18,2), @c char(200);
  SELECT @a = COUNT(*), @b = SUM(tutar), @c = MAX(dolgu) FROM dbo.Siparis WHERE musteri_id = @m;
END
GO
DECLARE @i int = 0; WHILE @i < 5 BEGIN EXEC dbo.SiparisGetir 1; SET @i += 1; END
GO
WAITFOR DELAY '00:01:10';
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC dbo.SiparisGetir 2;
DECLARE @i int = 0; WHILE @i < 5 BEGIN EXEC dbo.SiparisGetir 1; SET @i += 1; END
GO
DECLARE @i int = 0, @x int; WHILE @i < 30 BEGIN SELECT @x = COUNT(*) FROM dbo.Siparis WHERE id = @i + 10; SET @i += 1; END
GO
EXEC sys.sp_query_store_flush_db;
GO
-- hizli plani zorla, bir ad hoc sorguya hint ekle
DECLARE @q int, @p int;
SELECT TOP (1) @q = p.query_id, @p = p.plan_id
FROM sys.query_store_plan p JOIN sys.query_store_query q ON q.query_id = p.query_id
WHERE q.object_id = OBJECT_ID('dbo.SiparisGetir')
ORDER BY (SELECT AVG(rs.avg_duration) FROM sys.query_store_runtime_stats rs WHERE rs.plan_id = p.plan_id) ASC;
EXEC sys.sp_query_store_force_plan @q, @p;
DECLARE @h int;
SELECT TOP (1) @h = q.query_id FROM sys.query_store_query q JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id
WHERE t.query_sql_text LIKE '%WHERE id = @i + 10%' OR t.query_sql_text LIKE '%dbo.Siparis WHERE id = %' ORDER BY q.query_id DESC;
BEGIN TRY EXEC sys.sp_query_store_set_hints @h, N'OPTION (MAXDOP 1)'; END TRY BEGIN CATCH PRINT 'hint eklenemedi: ' + ERROR_MESSAGE(); END CATCH
GO
-- kapali ve dolu Query Store'lu iki ornek veritabani
USE master;
IF DB_ID('ornek_kapali') IS NOT NULL BEGIN ALTER DATABASE ornek_kapali SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ornek_kapali; END
CREATE DATABASE ornek_kapali;
ALTER DATABASE ornek_kapali SET QUERY_STORE = OFF;
IF DB_ID('ornek_dolu') IS NOT NULL BEGIN ALTER DATABASE ornek_dolu SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ornek_dolu; END
CREATE DATABASE ornek_dolu;
ALTER DATABASE ornek_dolu SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, MAX_STORAGE_SIZE_MB = 10, SIZE_BASED_CLEANUP_MODE = OFF, DATA_FLUSH_INTERVAL_SECONDS = 60);
GO
USE ornek_dolu;
GO
DECLARE @i int = 0, @s nvarchar(300), @x int;
WHILE @i < 20000 BEGIN SET @s = N'SELECT @r = COUNT(*) FROM sys.objects WHERE object_id = ' + CAST(@i AS nvarchar(10)) + N' OR name = N''o' + CAST(@i AS nvarchar(10)) + N''''; EXEC sp_executesql @s, N'@r int OUTPUT', @r = @x OUTPUT; SET @i += 1; END
EXEC sys.sp_query_store_flush_db;
GO
USE qs_demo;
GO
