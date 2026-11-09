-- SQL Server Query Store Handbook, Chapter 18, 'Index maintenance and forced plan'
-- Run in a test environment only.

SET NOCOUNT ON;
IF DB_ID(N'qs_lab_idx') IS NOT NULL BEGIN ALTER DATABASE qs_lab_idx SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_lab_idx; END
CREATE DATABASE qs_lab_idx;
ALTER DATABASE qs_lab_idx SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
USE qs_lab_idx;
GO
CREATE TABLE dbo.IdxT (id int IDENTITY PRIMARY KEY, k int NOT NULL, pad char(100) NOT NULL DEFAULT 'x');
INSERT dbo.IdxT (k) SELECT TOP (200000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 1000 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
CREATE INDEX ix_k ON dbo.IdxT (k);
GO
CREATE PROCEDURE dbo.IdxOzet @k int AS SELECT COUNT(*) AS adet, MAX(pad) AS ornek FROM dbo.IdxT WHERE k = @k;
GO
EXEC dbo.IdxOzet @k = 5; EXEC dbo.IdxOzet @k = 5;
EXEC sys.sp_query_store_flush_db;
DECLARE @q bigint = (SELECT TOP (1) query_id FROM sys.query_store_query WHERE object_id = OBJECT_ID(N'dbo.IdxOzet'));
DECLARE @p bigint = (SELECT TOP (1) plan_id FROM sys.query_store_plan WHERE query_id = @q ORDER BY plan_id);
EXEC sys.sp_query_store_force_plan @query_id = @q, @plan_id = @p;
GO
DROP TABLE IF EXISTS #aksiyon, #sonuc;
CREATE TABLE #aksiyon (sira int, ad varchar(50), ddl nvarchar(400), onarim nvarchar(400));
INSERT #aksiyon VALUES
 (1, 'REORGANIZE',            N'ALTER INDEX ix_k ON dbo.IdxT REORGANIZE', NULL),
 (2, 'REBUILD offline',       N'ALTER INDEX ix_k ON dbo.IdxT REBUILD', NULL),
 (3, 'REBUILD ONLINE',        N'ALTER INDEX ix_k ON dbo.IdxT REBUILD WITH (ONLINE = ON)', NULL),
 (4, 'DROP_EXISTING ayni',    N'CREATE INDEX ix_k ON dbo.IdxT (k) WITH (DROP_EXISTING = ON)', NULL),
 (5, 'DROP + CREATE ayni ad', N'DROP INDEX ix_k ON dbo.IdxT; CREATE INDEX ix_k ON dbo.IdxT (k)', NULL),
 (6, 'UPDATE STATISTICS FULL',N'UPDATE STATISTICS dbo.IdxT ix_k WITH FULLSCAN', NULL),
 (7, 'DISABLE',               N'ALTER INDEX ix_k ON dbo.IdxT DISABLE', N'ALTER INDEX ix_k ON dbo.IdxT REBUILD');
CREATE TABLE #sonuc (sira int, ad varchar(50), is_forced_plan bit, force_failure_count bigint, son_hata nvarchar(128),
                     plan_sayisi int, count_compiles bigint);
DECLARE @s int, @a varchar(50), @d nvarchar(400), @o nvarchar(400);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT sira, ad, ddl, onarim FROM #aksiyon ORDER BY sira;
OPEN c; FETCH NEXT FROM c INTO @s, @a, @d, @o;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC (@d);
    EXEC dbo.IdxOzet @k = 5; EXEC dbo.IdxOzet @k = 5; EXEC dbo.IdxOzet @k = 5;
    EXEC sys.sp_query_store_flush_db;
    INSERT #sonuc
    SELECT @s, @a, MAX(CAST(p.is_forced_plan AS int)), MAX(p.force_failure_count),
           MAX(CASE WHEN p.is_forced_plan = 1 THEN p.last_force_failure_reason_desc END),
           COUNT(DISTINCT p.plan_id), MAX(p.count_compiles)
    FROM sys.query_store_plan AS p JOIN sys.query_store_query AS q ON q.query_id = p.query_id
    WHERE q.object_id = OBJECT_ID(N'dbo.IdxOzet');
    IF @o IS NOT NULL EXEC (@o);
    FETCH NEXT FROM c INTO @s, @a, @d, @o;
END
CLOSE c; DEALLOCATE c;
SELECT * FROM #sonuc ORDER BY sira;
GO
