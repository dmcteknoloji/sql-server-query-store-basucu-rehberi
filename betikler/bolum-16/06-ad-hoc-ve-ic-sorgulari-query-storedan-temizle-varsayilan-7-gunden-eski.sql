-- Query Store Basucu Rehberi, Bolum 16
-- ad hoc ve ic sorgulari Query Storedan temizle (varsayilan 7 gunden eskiler)
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SET NOCOUNT ON;
DECLARE @dakika int = 10080, @parti int = 200, @id bigint, @n int = 1, @silinen int = 0;
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
