SET NOCOUNT ON;
PRINT '##### E0 SURUM';
SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar(40)) AS surum, CAST(SERVERPROPERTY('Edition') AS varchar(60)) AS edition;
GO
PRINT '##### E1 SISTEM VERITABANLARINDA QUERY STORE';
SELECT name, compatibility_level AS uyumluluk, is_query_store_on FROM sys.databases ORDER BY database_id;
GO
IF DB_ID('qs_demo') IS NOT NULL BEGIN ALTER DATABASE qs_demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_demo; END
CREATE DATABASE qs_demo;
GO
PRINT '##### E2 YENI VERITABANI VARSAYILANLARI';
USE qs_demo;
SELECT actual_state_desc, desired_state_desc, readonly_reason, flush_interval_seconds AS flush_sn, interval_length_minutes AS aralik_dk,
       max_storage_size_mb AS maks_mb, stale_query_threshold_days AS saklama_gun, size_based_cleanup_mode_desc AS boyut_temizlik,
       query_capture_mode_desc AS yakalama, max_plans_per_query AS maks_plan
FROM sys.database_query_store_options;
GO
PRINT '##### E2b DIGER VARSAYILANLAR (2017 ve ustu)';
USE qs_demo;
BEGIN TRY
  EXEC('SELECT wait_stats_capture_mode_desc AS wait_stats FROM sys.database_query_store_options');
END TRY BEGIN CATCH PRINT 'wait_stats sutunu yok: ' + ERROR_MESSAGE(); END CATCH
BEGIN TRY
  EXEC('SELECT capture_policy_stale_threshold_hours AS stale_saat, capture_policy_execution_count AS exec_adedi, capture_policy_total_compile_cpu_time_ms AS derleme_cpu_ms, capture_policy_total_execution_cpu_time_ms AS calisma_cpu_ms FROM sys.database_query_store_options');
END TRY BEGIN CATCH PRINT 'capture_policy sutunlari yok: ' + ERROR_MESSAGE(); END CATCH
GO
PRINT '##### E3 AKTIF ETME';
USE master;
ALTER DATABASE qs_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, INTERVAL_LENGTH_MINUTES = 1, DATA_FLUSH_INTERVAL_SECONDS = 60, MAX_STORAGE_SIZE_MB = 100, WAIT_STATS_CAPTURE_MODE = ON);
GO
USE qs_demo;
SELECT actual_state_desc, desired_state_desc, interval_length_minutes AS aralik_dk, max_storage_size_mb AS maks_mb, query_capture_mode_desc AS yakalama FROM sys.database_query_store_options;
GO
PRINT '##### E4 MASTER ve TEMPDB ICIN AKTIF ETME DENEMESI';
BEGIN TRY ALTER DATABASE master SET QUERY_STORE = ON; PRINT 'master: HATA YOK (beklenmiyordu)'; END TRY BEGIN CATCH PRINT 'master: ' + CAST(ERROR_NUMBER() AS varchar(10)) + ' ' + ERROR_MESSAGE(); END CATCH
BEGIN TRY ALTER DATABASE tempdb SET QUERY_STORE = ON; PRINT 'tempdb: HATA YOK (beklenmiyordu)'; END TRY BEGIN CATCH PRINT 'tempdb: ' + CAST(ERROR_NUMBER() AS varchar(10)) + ' ' + ERROR_MESSAGE(); END CATCH
GO
PRINT '##### E5 PARAMETRE KOKLAMA ve PLAN REGRESYONU';
USE qs_demo;
ALTER DATABASE qs_demo SET COMPATIBILITY_LEVEL = 150;
GO
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
-- 1) buyuk musteriyle ilk derleme (tarama plani), 2) cache temizle, 3) kucuk musteriyle derle (seek+lookup), 4) buyuk musteri bu planla calissin
DECLARE @i int = 0;
WHILE @i < 5 BEGIN EXEC dbo.SiparisGetir 1; SET @i += 1; END
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC dbo.SiparisGetir 2;
DECLARE @i int = 0;
WHILE @i < 5 BEGIN EXEC dbo.SiparisGetir 1; SET @i += 1; END
GO
EXEC sys.sp_query_store_flush_db;
GO
PRINT '##### E6 AYNI SORGUDA IKI PLAN (sorgu_id, plan_id, calistirma, ortalama sure us)';
SELECT q.query_id, p.plan_id, SUM(rs.count_executions) AS calistirma, CAST(SUM(rs.avg_duration * rs.count_executions) / NULLIF(SUM(rs.count_executions),0) AS bigint) AS ort_sure_us, MAX(CAST(p.is_forced_plan AS int)) AS zorlandi
FROM sys.query_store_query q JOIN sys.query_store_plan p ON p.query_id = q.query_id JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
WHERE q.object_id = OBJECT_ID('dbo.SiparisGetir') AND q.query_id IN (SELECT query_id FROM sys.query_store_plan GROUP BY query_id HAVING COUNT(*) > 1)
GROUP BY q.query_id, p.plan_id ORDER BY q.query_id, p.plan_id;
GO
PRINT '##### E7 PLAN ZORLAMA';
DECLARE @q int, @pbest int;
SELECT TOP 1 @q = q.query_id FROM sys.query_store_query q WHERE q.object_id = OBJECT_ID('dbo.SiparisGetir') AND q.query_id IN (SELECT query_id FROM sys.query_store_plan GROUP BY query_id HAVING COUNT(*) > 1) ORDER BY q.query_id;
SELECT TOP 1 @pbest = p.plan_id FROM sys.query_store_plan p JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id WHERE p.query_id = @q GROUP BY p.plan_id ORDER BY SUM(rs.avg_duration * rs.count_executions) / NULLIF(SUM(rs.count_executions),0) ASC;
PRINT 'sorgu_id=' + CAST(@q AS varchar(10)) + ' en hizli plan=' + CAST(@pbest AS varchar(10));
EXEC sys.sp_query_store_force_plan @query_id = @q, @plan_id = @pbest;
SELECT p.plan_id, p.is_forced_plan, p.force_failure_count, p.last_force_failure_reason_desc FROM sys.query_store_plan p WHERE p.query_id = @q;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC dbo.SiparisGetir 2;
DECLARE @i int = 0;
WHILE @i < 5 BEGIN EXEC dbo.SiparisGetir 1; SET @i += 1; END
EXEC sys.sp_query_store_flush_db;
GO
PRINT '##### E7b ZORLAMADAN SONRA (kucuk musteriyle derlense de zorlanan plan kullaniliyor mu)';
SELECT q.query_id, p.plan_id, p.is_forced_plan, SUM(rs.count_executions) AS calistirma, CAST(SUM(rs.avg_duration * rs.count_executions) / NULLIF(SUM(rs.count_executions),0) AS bigint) AS ort_sure_us
FROM sys.query_store_query q JOIN sys.query_store_plan p ON p.query_id = q.query_id JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
WHERE q.object_id = OBJECT_ID('dbo.SiparisGetir') AND q.query_id IN (SELECT query_id FROM sys.query_store_plan GROUP BY query_id HAVING COUNT(*) > 1)
GROUP BY q.query_id, p.plan_id, p.is_forced_plan ORDER BY q.query_id, p.plan_id;
GO
PRINT '##### E8 QUERY STORE HINTS (2022 ve ustu)';
BEGIN TRY
  DECLARE @q2 int = (SELECT TOP 1 q.query_id FROM sys.query_store_query q WHERE q.object_id = OBJECT_ID('dbo.SiparisGetir') ORDER BY q.query_id);
  EXEC sys.sp_query_store_set_hints @query_id = @q2, @query_hints = N'OPTION(RECOMPILE)';
  SELECT query_id, query_hint_text, source_desc, query_hint_failure_count FROM sys.query_store_query_hints;
  EXEC sys.sp_query_store_clear_hints @query_id = @q2;
  SELECT COUNT(*) AS kalan_hint FROM sys.query_store_query_hints;
END TRY BEGIN CATCH PRINT 'hints yok: ' + CAST(ERROR_NUMBER() AS varchar(10)) + ' ' + ERROR_MESSAGE(); END CATCH
GO
PRINT '##### E9 WAIT STATS KATEGORILERI';
SELECT TOP 8 wait_category_desc, COUNT(*) AS satir, SUM(total_query_wait_time_ms) AS toplam_bekleme_ms FROM sys.query_store_wait_stats GROUP BY wait_category_desc ORDER BY SUM(total_query_wait_time_ms) DESC;
GO
PRINT '##### E10 YAKALAMA MODU KARSILASTIRMASI (300 farkli ad hoc sorgu, her biri 1 kez)';
USE qs_demo;
DECLARE @mode TABLE(mod varchar(10), yakalanan int);
DECLARE @modlar TABLE(m varchar(10)); INSERT @modlar VALUES ('ALL'),('AUTO'),('NONE');
DECLARE @m varchar(10), @sql nvarchar(max), @i int;
DECLARE c CURSOR FOR SELECT m FROM @modlar;
OPEN c; FETCH NEXT FROM c INTO @m;
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @sql = N'ALTER DATABASE qs_demo SET QUERY_STORE CLEAR; ALTER DATABASE qs_demo SET QUERY_STORE (QUERY_CAPTURE_MODE = ' + @m + N')';
  EXEC(@sql);
  SET @i = 0;
  WHILE @i < 300 BEGIN SET @sql = N'SELECT COUNT(*) FROM dbo.Siparis WHERE id = ' + CAST(@i + 1000 AS nvarchar(10)); EXEC(@sql); SET @i += 1; END
  EXEC sys.sp_query_store_flush_db;
  INSERT @mode SELECT @m, COUNT(*) FROM sys.query_store_query_text WHERE query_sql_text LIKE N'%FROM dbo.Siparis WHERE id = %';
  FETCH NEXT FROM c INTO @m;
END
CLOSE c; DEALLOCATE c;
SELECT * FROM @mode;
GO
PRINT '##### E11 CUSTOM YAKALAMA (2019 ve ustu)';
BEGIN TRY
  ALTER DATABASE qs_demo SET QUERY_STORE (QUERY_CAPTURE_MODE = CUSTOM, QUERY_CAPTURE_POLICY = (STALE_CAPTURE_POLICY_THRESHOLD = 24 HOURS, EXECUTION_COUNT = 30, TOTAL_COMPILE_CPU_TIME_MS = 1000, TOTAL_EXECUTION_CPU_TIME_MS = 100));
  EXEC('SELECT query_capture_mode_desc, capture_policy_stale_threshold_hours AS saat, capture_policy_execution_count AS adet, capture_policy_total_compile_cpu_time_ms AS derleme_ms, capture_policy_total_execution_cpu_time_ms AS calisma_ms FROM sys.database_query_store_options');
END TRY BEGIN CATCH PRINT 'custom yok: ' + CAST(ERROR_NUMBER() AS varchar(10)) + ' ' + ERROR_MESSAGE(); END CATCH
GO
PRINT '##### E12 KOTA DOLUNCA READ_ONLY (maks 10 MB, 20000 farkli sorgu)';
USE qs_demo;
ALTER DATABASE qs_demo SET QUERY_STORE CLEAR;
ALTER DATABASE qs_demo SET QUERY_STORE (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, SIZE_BASED_CLEANUP_MODE = OFF, MAX_STORAGE_SIZE_MB = 10, DATA_FLUSH_INTERVAL_SECONDS = 60);
GO
DECLARE @i int = 0, @sql nvarchar(max);
WHILE @i < 20000
BEGIN
  SET @sql = N'SELECT COUNT(*), ' + CAST(@i AS nvarchar(10)) + N' AS k FROM dbo.Siparis WHERE musteri_id = ' + CAST(@i % 2000 + 2 AS nvarchar(10)) + N' AND tutar > ' + CAST(@i AS nvarchar(10));
  EXEC(@sql);
  SET @i += 1;
  IF @i % 5000 = 0 EXEC sys.sp_query_store_flush_db;
END
EXEC sys.sp_query_store_flush_db;
GO
WAITFOR DELAY '00:00:05';
SELECT actual_state_desc, desired_state_desc, readonly_reason, current_storage_size_mb AS simdiki_mb, max_storage_size_mb AS maks_mb FROM sys.database_query_store_options;
GO
PRINT '##### E13 GERI ALMA: boyut artir + CLEAR + READ_WRITE';
ALTER DATABASE qs_demo SET QUERY_STORE (MAX_STORAGE_SIZE_MB = 200, SIZE_BASED_CLEANUP_MODE = AUTO);
ALTER DATABASE qs_demo SET QUERY_STORE (OPERATION_MODE = READ_WRITE);
GO
SELECT actual_state_desc, desired_state_desc, readonly_reason, current_storage_size_mb AS simdiki_mb, max_storage_size_mb AS maks_mb FROM sys.database_query_store_options;
GO
PRINT '##### E14 TUTARLILIK KONTROLU (2017 ve ustu)';
BEGIN TRY
  ALTER DATABASE qs_demo SET QUERY_STORE = OFF;
  EXEC qs_demo.sys.sp_query_store_consistency_check;
  ALTER DATABASE qs_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
  SELECT actual_state_desc FROM sys.database_query_store_options;
  PRINT 'consistency_check calisti';
END TRY BEGIN CATCH PRINT 'consistency_check yok: ' + CAST(ERROR_NUMBER() AS varchar(10)) + ' ' + ERROR_MESSAGE(); END CATCH
GO
PRINT '##### E15 KATALOG GORUNUMLERI';
SELECT name FROM sys.all_objects WHERE name LIKE 'query_store%' OR name LIKE 'database_query_store%' OR name LIKE 'sp_query_store%' ORDER BY name;
GO
PRINT '##### BITTI';
