SET NOCOUNT ON;
IF DB_ID('qs_lab_read_only') IS NOT NULL BEGIN ALTER DATABASE qs_lab_read_only SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_lab_read_only; END
CREATE DATABASE qs_lab_read_only;
GO
ALTER DATABASE qs_lab_read_only SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
USE qs_lab_read_only;
CREATE TABLE dbo.t (id int PRIMARY KEY, k int); INSERT dbo.t SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)), 1 FROM sys.all_objects;
GO
CREATE PROCEDURE dbo.p1 @k int AS BEGIN DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE k = @k; END
GO
CREATE PROCEDURE dbo.p2 @k int AS BEGIN DECLARE @c int; SELECT @c = MAX(id) FROM dbo.t WHERE k = @k; END
GO
CREATE PROCEDURE dbo.p3 @k int AS BEGIN DECLARE @c int; SELECT @c = MIN(id) FROM dbo.t WHERE k = @k; END
GO
EXEC dbo.p1 1; EXEC dbo.p2 1; EXEC dbo.p3 1; EXEC sp_query_store_flush_db;
DECLARE @query_id_1 bigint = (SELECT TOP 1 q.query_id FROM sys.query_store_query q WHERE q.object_id = OBJECT_ID('dbo.p1') AND EXISTS (SELECT 1 FROM sys.query_store_plan p WHERE p.query_id = q.query_id));
DECLARE @query_id_2 bigint = (SELECT TOP 1 q.query_id FROM sys.query_store_query q WHERE q.object_id = OBJECT_ID('dbo.p2') AND EXISTS (SELECT 1 FROM sys.query_store_plan p WHERE p.query_id = q.query_id));
DECLARE @query_id_3 bigint = (SELECT TOP 1 q.query_id FROM sys.query_store_query q WHERE q.object_id = OBJECT_ID('dbo.p3') AND EXISTS (SELECT 1 FROM sys.query_store_plan p WHERE p.query_id = q.query_id));
DECLARE @plan_id_2 bigint = (SELECT TOP 1 plan_id FROM sys.query_store_plan WHERE query_id = @query_id_2);
ALTER DATABASE qs_lab_read_only SET QUERY_STORE (OPERATION_MODE = READ_ONLY);
SELECT actual_state_desc FROM sys.database_query_store_options;
BEGIN TRY EXEC sp_query_store_force_plan @query_id_2, @plan_id_2; SELECT 'READ_ONLY force_plan: basarili' AS sonuc; END TRY BEGIN CATCH SELECT 'READ_ONLY force_plan' AS islem, ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS mesaj; END CATCH
SELECT 'sabit plan sayisi' AS olcum, COUNT(*) AS deger FROM sys.query_store_plan WHERE is_forced_plan = 1;
BEGIN TRY EXEC sp_query_store_remove_query @query_id_3; SELECT 'READ_ONLY remove_query: basarili' AS sonuc; END TRY BEGIN CATCH SELECT 'READ_ONLY remove_query' AS islem, ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS mesaj; END CATCH
SELECT 'q3 hala var mi' AS olcum, COUNT(*) AS deger FROM sys.query_store_query WHERE query_id = @query_id_3;
BEGIN TRY EXEC sp_query_store_set_hints @query_id_1, N'OPTION (MAXDOP 1)'; SELECT 'READ_ONLY set_hints: basarili' AS sonuc; END TRY BEGIN CATCH SELECT 'READ_ONLY set_hints' AS islem, ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS mesaj; END CATCH
SELECT 'hint sayisi' AS olcum, COUNT(*) AS deger FROM sys.query_store_query_hints;
GO
