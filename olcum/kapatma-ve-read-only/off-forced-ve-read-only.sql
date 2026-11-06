SET NOCOUNT ON;
DECLARE @i int = 0;
-- kurulum: iki veritabani, bir kapanis yontemi icin
IF DB_ID('lim_f') IS NOT NULL BEGIN ALTER DATABASE lim_f SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE lim_f; END
IF DB_ID('lim_o') IS NOT NULL BEGIN ALTER DATABASE lim_o SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE lim_o; END
IF DB_ID('lim_r') IS NOT NULL BEGIN ALTER DATABASE lim_r SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE lim_r; END
CREATE DATABASE lim_f; CREATE DATABASE lim_o; CREATE DATABASE lim_r;
GO
ALTER DATABASE lim_f SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, DATA_FLUSH_INTERVAL_SECONDS = 900);
ALTER DATABASE lim_o SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, DATA_FLUSH_INTERVAL_SECONDS = 900);
ALTER DATABASE lim_r SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, DATA_FLUSH_INTERVAL_SECONDS = 900);
GO
USE lim_f;
CREATE TABLE dbo.t (id int PRIMARY KEY, k int); INSERT dbo.t SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)), 1 FROM sys.all_objects;
GO
CREATE PROCEDURE dbo.p @k int AS BEGIN DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE k = @k; END
GO
EXEC dbo.p 1; EXEC sp_query_store_flush_db;
DECLARE @i int = 0, @s nvarchar(200); WHILE @i < 60 BEGIN EXEC dbo.p 1; SET @s = N'DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE id = ' + CAST(@i AS nvarchar(5)) + N' AND k = 1'; EXEC (@s); SET @i += 1; END
SELECT 'lim_f OFF(FORCED) oncesi' AS adim, (SELECT COUNT(*) FROM sys.query_store_query) AS query_sayisi, (SELECT SUM(count_executions) FROM sys.query_store_runtime_stats) AS toplam_calistirma;
GO
ALTER DATABASE lim_f SET QUERY_STORE = OFF (FORCED);
ALTER DATABASE lim_f SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
GO
SELECT 'lim_f OFF(FORCED) sonrasi' AS adim, (SELECT COUNT(*) FROM sys.query_store_query) AS query_sayisi, (SELECT SUM(count_executions) FROM sys.query_store_runtime_stats) AS toplam_calistirma;
GO
USE lim_o;
CREATE TABLE dbo.t (id int PRIMARY KEY, k int); INSERT dbo.t SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)), 1 FROM sys.all_objects;
GO
CREATE PROCEDURE dbo.p @k int AS BEGIN DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE k = @k; END
GO
EXEC dbo.p 1; EXEC sp_query_store_flush_db;
DECLARE @i int = 0, @s nvarchar(200); WHILE @i < 60 BEGIN EXEC dbo.p 1; SET @s = N'DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE id = ' + CAST(@i AS nvarchar(5)) + N' AND k = 1'; EXEC (@s); SET @i += 1; END
SELECT 'lim_o OFF oncesi' AS adim, (SELECT COUNT(*) FROM sys.query_store_query) AS query_sayisi, (SELECT SUM(count_executions) FROM sys.query_store_runtime_stats) AS toplam_calistirma;
GO
ALTER DATABASE lim_o SET QUERY_STORE = OFF;
ALTER DATABASE lim_o SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
GO
SELECT 'lim_o OFF sonrasi' AS adim, (SELECT COUNT(*) FROM sys.query_store_query) AS query_sayisi, (SELECT SUM(count_executions) FROM sys.query_store_runtime_stats) AS toplam_calistirma;
GO
USE lim_r;
CREATE TABLE dbo.t (id int PRIMARY KEY, k int); INSERT dbo.t SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)), 1 FROM sys.all_objects;
GO
CREATE PROCEDURE dbo.p1 @k int AS BEGIN DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE k = @k; END
GO
CREATE PROCEDURE dbo.p2 @k int AS BEGIN DECLARE @c int; SELECT @c = MAX(id) FROM dbo.t WHERE k = @k; END
GO
EXEC dbo.p1 1; EXEC dbo.p2 1; EXEC sp_query_store_flush_db;
DECLARE @q1 bigint = (SELECT TOP 1 q.query_id FROM sys.query_store_query q WHERE q.object_id = OBJECT_ID('dbo.p1') AND EXISTS (SELECT 1 FROM sys.query_store_plan p WHERE p.query_id = q.query_id));
DECLARE @q2 bigint = (SELECT TOP 1 q.query_id FROM sys.query_store_query q WHERE q.object_id = OBJECT_ID('dbo.p2') AND EXISTS (SELECT 1 FROM sys.query_store_plan p WHERE p.query_id = q.query_id));
DECLARE @p1 bigint = (SELECT TOP 1 plan_id FROM sys.query_store_plan WHERE query_id = @q1);
DECLARE @p2 bigint = (SELECT TOP 1 plan_id FROM sys.query_store_plan WHERE query_id = @q2);
EXEC sp_query_store_force_plan @q1, @p1;
SELECT @q1 AS q1, @p1 AS p1, @q2 AS q2, @p2 AS p2;
ALTER DATABASE lim_r SET QUERY_STORE (OPERATION_MODE = READ_ONLY);
SELECT actual_state_desc FROM sys.database_query_store_options;
BEGIN TRY EXEC sp_query_store_set_hints @q2, N'OPTION (MAXDOP 1)'; SELECT 'READ_ONLY set_hints: basarili' AS sonuc; END TRY BEGIN CATCH SELECT 'READ_ONLY set_hints' AS islem, ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS mesaj; END CATCH
BEGIN TRY EXEC sp_query_store_force_plan @q2, @p2; SELECT 'READ_ONLY force_plan: basarili' AS sonuc; END TRY BEGIN CATCH SELECT 'READ_ONLY force_plan' AS islem, ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS mesaj; END CATCH
BEGIN TRY EXEC sp_query_store_remove_query @q2; SELECT 'READ_ONLY remove_query: basarili' AS sonuc; END TRY BEGIN CATCH SELECT 'READ_ONLY remove_query' AS islem, ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS mesaj; END CATCH
BEGIN TRY EXEC sp_query_store_unforce_plan @q1, @p1; SELECT 'READ_ONLY unforce_plan: basarili' AS sonuc; END TRY BEGIN CATCH SELECT 'READ_ONLY unforce_plan' AS islem, ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS mesaj; END CATCH
GO
