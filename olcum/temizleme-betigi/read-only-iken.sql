SET NOCOUNT ON;
IF DB_ID('lim_p') IS NOT NULL BEGIN ALTER DATABASE lim_p SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE lim_p; END
CREATE DATABASE lim_p;
GO
ALTER DATABASE lim_p SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
USE lim_p;
CREATE TABLE dbo.t (id int PRIMARY KEY, k int); INSERT dbo.t SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)), 1 FROM sys.all_objects;
GO
CREATE PROCEDURE dbo.p @k int AS BEGIN DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE k = @k; END
GO
EXEC dbo.p 1;
DECLARE @i int = 0, @s nvarchar(200); WHILE @i < 40 BEGIN SET @s = N'DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE id = ' + CAST(@i AS nvarchar(5)); EXEC (@s); SET @i += 1; END
EXEC sp_query_store_flush_db;
DECLARE @q bigint = (SELECT TOP 1 q.query_id FROM sys.query_store_query q WHERE q.object_id = OBJECT_ID('dbo.p') AND EXISTS (SELECT 1 FROM sys.query_store_plan p WHERE p.query_id = q.query_id));
DECLARE @pl bigint = (SELECT TOP 1 plan_id FROM sys.query_store_plan WHERE query_id = @q);
EXEC sp_query_store_force_plan @q, @pl;
ALTER DATABASE lim_p SET QUERY_STORE (OPERATION_MODE = READ_ONLY);
GO
SELECT actual_state_desc AS durum FROM sys.database_query_store_options;
SELECT COUNT(*) AS onceki_query FROM sys.query_store_query;
GO
-- ad hoc ve ic sorgulari Query Storedan temizle (varsayilan 7 gunden eskiler)
SET NOCOUNT ON;
DECLARE @dakika int = 0, @parti int = 200, @id bigint, @n int = 1, @silinen int = 0;
IF NOT EXISTS (SELECT 1 FROM sys.database_query_store_options WHERE actual_state_desc IN (N'READ_WRITE', N'READ_ONLY'))
BEGIN RAISERROR(N'Query Store READ_WRITE ya da READ_ONLY degil, betik calismadi.', 16, 1); RETURN; END
DROP TABLE IF EXISTS #sil;
CREATE TABLE #sil (query_id bigint PRIMARY KEY);
WHILE @n > 0
BEGIN
  TRUNCATE TABLE #sil;
  INSERT #sil (query_id)
  SELECT TOP (@parti) q.query_id
  FROM sys.query_store_query AS q
  WHERE (q.is_internal_query = 1 OR q.object_id = 0)
    AND q.last_execution_time < DATEADD(MINUTE, -@dakika, SYSDATETIMEOFFSET())
    AND NOT EXISTS (SELECT 1 FROM sys.query_store_plan AS fp WHERE fp.query_id = q.query_id AND fp.is_forced_plan = 1)
    AND NOT EXISTS (SELECT 1 FROM sys.query_store_query_hints AS h WHERE h.query_id = q.query_id)
    AND NOT EXISTS (SELECT 1 FROM sys.query_store_plan AS p JOIN sys.query_store_plan_feedback AS f ON f.plan_id = p.plan_id WHERE p.query_id = q.query_id)
  ORDER BY q.query_id;
  SET @n = @@ROWCOUNT;
  DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT query_id FROM #sil;
  OPEN c; FETCH NEXT FROM c INTO @id;
  WHILE @@FETCH_STATUS = 0
  BEGIN EXEC sys.sp_query_store_remove_query @id; SET @silinen += 1; FETCH NEXT FROM c INTO @id; END
  CLOSE c; DEALLOCATE c;
  IF @n > 0 WAITFOR DELAY '00:00:02';
END
SELECT @silinen AS silinen_sorgu_sayisi;

GO
SELECT COUNT(*) AS sonraki_query FROM sys.query_store_query;
SELECT COUNT(*) AS sabit_plan FROM sys.query_store_plan WHERE is_forced_plan = 1;
GO
