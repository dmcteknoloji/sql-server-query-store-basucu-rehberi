SET NOCOUNT ON;
IF DB_ID('lc') IS NOT NULL BEGIN ALTER DATABASE lc SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE lc; END
GO
CREATE DATABASE lc;
GO
ALTER DATABASE lc SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, DATA_FLUSH_INTERVAL_SECONDS = 60);
GO
USE lc;
CREATE TABLE dbo.Siparis (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, d char(100) NOT NULL DEFAULT 'x');
INSERT dbo.Siparis (musteri_id) SELECT TOP (400000) 1 FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c;
INSERT dbo.Siparis (musteri_id) SELECT TOP (20000) 2 + ABS(CHECKSUM(NEWID())) % 2000 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
CREATE INDEX ix_m ON dbo.Siparis(musteri_id);
GO
CREATE PROCEDURE dbo.SiparisGetir @m int, @n int = 1 AS
BEGIN
  DECLARE @t datetime2(7) = SYSDATETIME(), @i int = 0, @a int, @b bigint;
  WHILE @i < @n BEGIN SELECT @a = COUNT(*), @b = SUM(LEN(d)) FROM dbo.Siparis WHERE musteri_id = @m; SET @i += 1; END
  SELECT CAST(DATEDIFF_BIG(MICROSECOND, @t, SYSDATETIME()) / 1000.0 / @n AS decimal(12,2)) AS ort_ms;
END
GO
CREATE PROCEDURE dbo.kullanilan AS
BEGIN
  DECLARE @q bigint = (SELECT TOP 1 query_id FROM sys.query_store_query_text t JOIN sys.query_store_query q ON q.query_text_id = t.query_text_id WHERE t.query_sql_text LIKE N'%SUM(LEN(d))%' AND q.object_id = OBJECT_ID('dbo.SiparisGetir'));
  SELECT TOP (1) p.plan_id, CASE WHEN p.query_plan LIKE N'%Clustered Index Scan%' THEN N'tarama' ELSE N'seek+lookup' END AS plan_tipi, p.is_forced_plan
  FROM sys.dm_exec_query_stats qs CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
  JOIN sys.query_store_plan p ON p.query_plan_hash = qs.query_plan_hash AND p.query_id = @q
  WHERE t.objectid = OBJECT_ID('dbo.SiparisGetir') AND t.dbid = DB_ID() ORDER BY qs.creation_time DESC;
END
GO
PRINT '== plan uretimi';
EXEC sp_recompile 'dbo.SiparisGetir'; EXEC dbo.SiparisGetir @m = 1;
EXEC sp_recompile 'dbo.SiparisGetir'; EXEC dbo.SiparisGetir @m = 700;
EXEC sp_query_store_flush_db;
GO
SELECT p.plan_id, CASE WHEN p.query_plan LIKE N'%Clustered Index Scan%' THEN N'tarama' ELSE N'seek+lookup' END AS plan_tipi
FROM sys.query_store_plan p JOIN sys.query_store_query q ON q.query_id = p.query_id WHERE q.object_id = OBJECT_ID('dbo.SiparisGetir') AND (p.query_plan LIKE N'%Clustered Index Scan%' OR p.query_plan LIKE N'%Index Seek%') ORDER BY p.plan_id;
GO
DECLARE @q bigint = (SELECT TOP 1 query_id FROM sys.query_store_query_text t JOIN sys.query_store_query q ON q.query_text_id = t.query_text_id WHERE t.query_sql_text LIKE N'%SUM(LEN(d))%' AND q.object_id = OBJECT_ID('dbo.SiparisGetir'));
DECLARE @ptarama bigint = (SELECT TOP 1 plan_id FROM sys.query_store_plan WHERE query_id = @q AND query_plan LIKE N'%Clustered Index Scan%' ORDER BY plan_id);
DECLARE @pseek bigint = (SELECT TOP 1 plan_id FROM sys.query_store_plan WHERE query_id = @q AND query_plan NOT LIKE N'%Clustered Index Scan%' ORDER BY plan_id);
SELECT @q AS query_id, @ptarama AS plan_tarama, @pseek AS plan_seek;
CREATE TABLE #m (plan_tipi nvarchar(20), parametre nvarchar(20), ort_ms decimal(12,2));
CREATE TABLE #r (ort_ms decimal(12,2));
-- plan x parametre matrisi
DECLARE @pl bigint, @ad nvarchar(20);
DECLARE c CURSOR LOCAL FOR SELECT @ptarama, N'tarama' UNION ALL SELECT @pseek, N'seek+lookup';
OPEN c; FETCH NEXT FROM c INTO @pl, @ad;
WHILE @@FETCH_STATUS = 0
BEGIN
  EXEC sp_query_store_force_plan @q, @pl;
  EXEC sp_recompile 'dbo.SiparisGetir'; EXEC dbo.SiparisGetir @m = 700; 
  INSERT #r EXEC dbo.SiparisGetir @m = 700, @n = 20; INSERT #m SELECT @ad, N'kucuk musteri', ort_ms FROM #r; DELETE #r;
  INSERT #r EXEC dbo.SiparisGetir @m = 1, @n = 3;    INSERT #m SELECT @ad, N'buyuk musteri', ort_ms FROM #r; DELETE #r;
  EXEC sp_query_store_unforce_plan @q, @pl;
  FETCH NEXT FROM c INTO @pl, @ad;
END
CLOSE c; DEALLOCATE c;
SELECT * FROM #m;
GO
PRINT '== yasam dongusu (tarama plani sabit)';
DECLARE @q bigint = (SELECT TOP 1 query_id FROM sys.query_store_query_text t JOIN sys.query_store_query q ON q.query_text_id = t.query_text_id WHERE t.query_sql_text LIKE N'%SUM(LEN(d))%' AND q.object_id = OBJECT_ID('dbo.SiparisGetir'));
DECLARE @ptarama bigint = (SELECT TOP 1 plan_id FROM sys.query_store_plan WHERE query_id = @q AND query_plan LIKE N'%Clustered Index Scan%' ORDER BY plan_id);
EXEC sp_query_store_force_plan @q, @ptarama;
CREATE TABLE ##yd (durum nvarchar(30), kullanilan_plan bigint, plan_tipi nvarchar(20), sabit_mi bit);
EXEC sp_recompile 'dbo.SiparisGetir'; EXEC dbo.SiparisGetir @m = 700;
INSERT ##yd (kullanilan_plan, plan_tipi, sabit_mi) EXEC dbo.kullanilan; UPDATE ##yd SET durum = N'READ_WRITE' WHERE durum IS NULL;
GO
ALTER DATABASE lc SET QUERY_STORE (OPERATION_MODE = READ_ONLY);
GO
EXEC sp_recompile 'dbo.SiparisGetir'; EXEC dbo.SiparisGetir @m = 700;
INSERT ##yd (kullanilan_plan, plan_tipi, sabit_mi) EXEC dbo.kullanilan; UPDATE ##yd SET durum = N'READ_ONLY' WHERE durum IS NULL;
GO
ALTER DATABASE lc SET QUERY_STORE = OFF;
GO
EXEC sp_recompile 'dbo.SiparisGetir'; EXEC dbo.SiparisGetir @m = 700;
INSERT ##yd (kullanilan_plan, plan_tipi, sabit_mi) EXEC dbo.kullanilan; UPDATE ##yd SET durum = N'OFF' WHERE durum IS NULL;
GO
ALTER DATABASE lc SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
GO
EXEC sp_recompile 'dbo.SiparisGetir'; EXEC dbo.SiparisGetir @m = 700;
INSERT ##yd (kullanilan_plan, plan_tipi, sabit_mi) EXEC dbo.kullanilan; UPDATE ##yd SET durum = N'tekrar READ_WRITE' WHERE durum IS NULL;
SELECT * FROM ##yd;
GO
PRINT '== sabit plan varken remove_query';
DECLARE @q bigint = (SELECT TOP 1 query_id FROM sys.query_store_query_text t JOIN sys.query_store_query q ON q.query_text_id = t.query_text_id WHERE t.query_sql_text LIKE N'%SUM(LEN(d))%' AND q.object_id = OBJECT_ID('dbo.SiparisGetir'));
BEGIN TRY EXEC sp_query_store_remove_query @q; SELECT N'silindi' AS sonuc; END TRY BEGIN CATCH SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS mesaj; END CATCH
SELECT COUNT(*) AS sabit_plan_sayisi FROM sys.query_store_plan WHERE is_forced_plan = 1;
GO
PRINT '== CLEAR sonrasi';
ALTER DATABASE lc SET QUERY_STORE CLEAR;
SELECT (SELECT COUNT(*) FROM sys.query_store_plan WHERE is_forced_plan = 1) AS sabit_plan_sayisi, (SELECT COUNT(*) FROM sys.query_store_query) AS query_sayisi;
GO
