
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

USE qs_demo;
GO
PRINT '##### BLOK 1  03-query-store-nasil-calisir.md  -- DOGRULA Query Store dahili durumu (SQL Server 2022 ve sonrasi)';
GO

-- DOGRULA Query Store dahili durumu (SQL Server 2022 ve sonrasi)
SELECT pending_message_count, messaging_memory_used_mb
FROM sys.database_query_store_internal_state;
GO

USE qs_demo;
GO
PRINT '##### BLOK 2  04-aktif-etme.md  -- DOGRULA 1) durum ve ayarlar';
GO

-- DOGRULA 1) durum ve ayarlar
SELECT actual_state_desc, desired_state_desc, readonly_reason,
       interval_length_minutes, max_storage_size_mb, query_capture_mode_desc,
       wait_stats_capture_mode_desc
FROM sys.database_query_store_options;
GO

USE qs_demo;
GO
PRINT '##### BLOK 3  07-raporlar-ve-sorgular.md  -- DOGRULA son 24 saatte toplam sure ve calistirma sayisina gore ilk 10 sorgu';
GO

-- DOGRULA son 24 saatte toplam sure ve calistirma sayisina gore ilk 10 sorgu
SELECT TOP (10)
       q.query_id,
       OBJECT_NAME(q.object_id)                                       AS icerik_nesne,
       SUM(rs.count_executions)                                       AS calistirma,
       CAST(SUM(rs.avg_duration * rs.count_executions) / 1000.0 AS decimal(18,1)) AS toplam_sure_ms,
       CAST(SUM(rs.avg_duration * rs.count_executions)
            / NULLIF(SUM(rs.count_executions), 0) / 1000.0 AS decimal(18,2))      AS agirlikli_ort_ms,
       COUNT(DISTINCT p.plan_id)                                      AS plan_sayisi,
       LEFT(qt.query_sql_text, 80)                                    AS sorgu
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q               ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan AS p                ON p.query_id = q.query_id
JOIN sys.query_store_runtime_stats AS rs      ON rs.plan_id = p.plan_id
JOIN sys.query_store_runtime_stats_interval AS i ON i.runtime_stats_interval_id = rs.runtime_stats_interval_id
WHERE i.start_time >= DATEADD(HOUR, -24, SYSUTCDATETIME())
GROUP BY q.query_id, q.object_id, qt.query_sql_text
ORDER BY SUM(rs.avg_duration * rs.count_executions) DESC;
GO

USE qs_demo;
GO
PRINT '##### BLOK 4  07-raporlar-ve-sorgular.md  -- DOGRULA son bir saatte calisan son 10 sorgu';
GO

-- DOGRULA son bir saatte calisan son 10 sorgu
SELECT TOP (10)
       qt.query_sql_text, q.query_id, qt.query_text_id, p.plan_id, rs.last_execution_time
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q          ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p           ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats AS rs ON p.plan_id = rs.plan_id
WHERE rs.last_execution_time > DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY rs.last_execution_time DESC;
GO

USE qs_demo;
GO
PRINT '##### BLOK 5  07-raporlar-ve-sorgular.md  -- DOGRULA son 24 saatte toplam CPU suresine gore ilk 10 sorgu';
GO

-- DOGRULA son 24 saatte toplam CPU suresine gore ilk 10 sorgu
SELECT TOP (10)
       q.query_id,
       SUM(rs.count_executions)                                      AS calistirma,
       CAST(SUM(rs.avg_cpu_time * rs.count_executions) / 1000.0 AS decimal(18,1)) AS toplam_cpu_ms,
       CAST(SUM(rs.avg_logical_io_reads * rs.count_executions) AS bigint)          AS toplam_mantiksal_okuma,
       LEFT(qt.query_sql_text, 80)                                   AS sorgu
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q          ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan AS p           ON p.query_id = q.query_id
JOIN sys.query_store_runtime_stats AS rs ON rs.plan_id = p.plan_id
JOIN sys.query_store_runtime_stats_interval AS i ON i.runtime_stats_interval_id = rs.runtime_stats_interval_id
WHERE i.start_time >= DATEADD(HOUR, -24, SYSUTCDATETIME())
GROUP BY q.query_id, qt.query_sql_text
ORDER BY SUM(rs.avg_cpu_time * rs.count_executions) DESC;
GO

USE qs_demo;
GO
PRINT '##### BLOK 6  07-raporlar-ve-sorgular.md  -- DOGRULA birden fazla plani olan sorgular';
GO

-- DOGRULA birden fazla plani olan sorgular
SELECT q.query_id,
       OBJECT_NAME(q.object_id)        AS icerik_nesne,
       COUNT(DISTINCT p.plan_id)       AS plan_sayisi,
       STRING_AGG(CAST(p.plan_id AS varchar(12)), ',') AS plan_idleri,
       LEFT(qt.query_sql_text, 80)     AS sorgu
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p  ON p.query_id = q.query_id
GROUP BY q.query_id, q.object_id, qt.query_sql_text
HAVING COUNT(DISTINCT p.plan_id) > 1
ORDER BY plan_sayisi DESC;
GO

USE qs_demo;
GO
PRINT '##### BLOK 7  07-raporlar-ve-sorgular.md  -- DOGRULA ayni sorgunun planlari yan yana';
GO

-- DOGRULA ayni sorgunun planlari yan yana
SELECT p.query_id, p.plan_id,
       SUM(rs.count_executions) AS calistirma,
       CAST(SUM(rs.avg_duration * rs.count_executions) / NULLIF(SUM(rs.count_executions), 0) / 1000.0 AS decimal(18,2)) AS ort_sure_ms,
       CAST(SUM(rs.avg_cpu_time * rs.count_executions) / NULLIF(SUM(rs.count_executions), 0) / 1000.0 AS decimal(18,2)) AS ort_cpu_ms,
       MAX(p.last_compile_start_time) AS son_derleme,
       MAX(CAST(p.is_forced_plan AS int)) AS zorlanmis
FROM sys.query_store_plan AS p
JOIN sys.query_store_runtime_stats AS rs ON rs.plan_id = p.plan_id
WHERE p.query_id IN (SELECT query_id FROM sys.query_store_plan GROUP BY query_id HAVING COUNT(*) > 1)
GROUP BY p.query_id, p.plan_id
ORDER BY p.query_id, ort_sure_ms;
GO

USE qs_demo;
GO
PRINT '##### BLOK 8  07-raporlar-ve-sorgular.md  -- DOGRULA son 48 saatte plan degisikligiyle suresi 2 katindan fazla artan sorgular';
GO

-- DOGRULA son 48 saatte plan degisikligiyle suresi 2 katindan fazla artan sorgular
SELECT qt.query_sql_text, q.query_id,
       rs1.avg_duration AS ort_sure_1_us, p1.plan_id AS plan_1, rsi1.start_time AS aralik_1,
       rs2.avg_duration AS ort_sure_2_us, p2.plan_id AS plan_2, rsi2.start_time AS aralik_2
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q   ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p1   ON q.query_id = p1.query_id
JOIN sys.query_store_runtime_stats AS rs1 ON p1.plan_id = rs1.plan_id
JOIN sys.query_store_runtime_stats_interval AS rsi1 ON rsi1.runtime_stats_interval_id = rs1.runtime_stats_interval_id
JOIN sys.query_store_plan AS p2   ON q.query_id = p2.query_id
JOIN sys.query_store_runtime_stats AS rs2 ON p2.plan_id = rs2.plan_id
JOIN sys.query_store_runtime_stats_interval AS rsi2 ON rsi2.runtime_stats_interval_id = rs2.runtime_stats_interval_id
WHERE rsi1.start_time > DATEADD(HOUR, -48, GETUTCDATE())
  AND rsi2.start_time > rsi1.start_time
  AND p1.plan_id <> p2.plan_id
  AND rs2.avg_duration > 2 * rs1.avg_duration
ORDER BY q.query_id, rsi1.start_time, rsi2.start_time;
GO

USE qs_demo;
GO
PRINT '##### BLOK 9  07-raporlar-ve-sorgular.md  -- DOGRULA son 24 saatte toplam bekleme suresi en yuksek sorgular (SQL Server 2017 ve sonr';
GO

-- DOGRULA son 24 saatte toplam bekleme suresi en yuksek sorgular (SQL Server 2017 ve sonrasi)
SELECT TOP (10)
       q.query_id, p.plan_id, ws.wait_category_desc,
       SUM(ws.total_query_wait_time_ms) AS toplam_bekleme_ms
FROM sys.query_store_wait_stats AS ws
JOIN sys.query_store_plan AS p  ON ws.plan_id = p.plan_id
JOIN sys.query_store_query AS q ON p.query_id = q.query_id
JOIN sys.query_store_runtime_stats_interval AS i ON i.runtime_stats_interval_id = ws.runtime_stats_interval_id
WHERE i.start_time >= DATEADD(HOUR, -24, SYSUTCDATETIME())
GROUP BY q.query_id, p.plan_id, ws.wait_category_desc
ORDER BY SUM(ws.total_query_wait_time_ms) DESC;
GO

USE qs_demo;
GO
PRINT '##### BLOK 10  07-raporlar-ve-sorgular.md  -- DOGRULA durum ve boyut';
GO

-- DOGRULA durum ve boyut
SELECT actual_state_desc, desired_state_desc, readonly_reason,
       current_storage_size_mb, max_storage_size_mb,
       interval_length_minutes, stale_query_threshold_days,
       size_based_cleanup_mode_desc, query_capture_mode_desc
FROM sys.database_query_store_options;
GO

USE qs_demo;
GO
PRINT '##### BLOK 11  08-plan-regresyonu-ve-zorlama.md  -- DOGRULA zorlanan planlarin durumu';
GO

-- DOGRULA zorlanan planlarin durumu
SELECT p.plan_id, p.query_id, q.object_id AS icerik_nesne_id,
       p.is_forced_plan, p.force_failure_count, p.last_force_failure_reason_desc
FROM sys.query_store_plan AS p
JOIN sys.query_store_query AS q ON p.query_id = q.query_id
WHERE p.is_forced_plan = 1;
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 12  08b-plan-cache-izleme.md  -- DOGRULA variant plan var mi, Query Storeda dispatcher ve variant planlar';
GO

-- DOGRULA variant plan var mi, Query Storeda dispatcher ve variant planlar
SELECT q.object_id, p.plan_type_desc, COUNT(*) AS plan_adedi
FROM sys.query_store_plan AS p
JOIN sys.query_store_query AS q ON q.query_id = p.query_id
WHERE p.plan_type_desc IN (N'Dispatcher Plan', N'Query Variant Plan')
GROUP BY q.object_id, p.plan_type_desc;
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 13  08b-plan-cache-izleme.md  -- DOGRULA plan cache genel durum, tur bazinda';
GO

-- DOGRULA plan cache genel durum, tur bazinda
SELECT cp.objtype AS tur, cp.cacheobjtype, COUNT(*) AS plan_sayisi,
       CAST(SUM(CAST(cp.size_in_bytes AS bigint)) / 1048576.0 AS decimal(12,1)) AS toplam_mb,
       SUM(CASE WHEN cp.usecounts = 1 THEN 1 ELSE 0 END) AS tek_kullanimlik,
       CAST(SUM(CASE WHEN cp.usecounts = 1 THEN CAST(cp.size_in_bytes AS bigint) ELSE 0 END) / 1048576.0 AS decimal(12,1)) AS tek_kullanimlik_mb
FROM sys.dm_exec_cached_plans AS cp
GROUP BY cp.objtype, cp.cacheobjtype
ORDER BY toplam_mb DESC;
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 14  08b-plan-cache-izleme.md  -- DOGRULA tek kullanimlik plan orani';
GO

-- DOGRULA tek kullanimlik plan orani
SELECT CAST(SUM(CASE WHEN usecounts = 1 THEN CAST(size_in_bytes AS bigint) ELSE 0 END) * 100.0
            / NULLIF(SUM(CAST(size_in_bytes AS bigint)), 0) AS decimal(5,1)) AS tek_kullanimlik_yuzde_mb,
       CAST(SUM(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS decimal(5,1)) AS tek_kullanimlik_yuzde_adet
FROM sys.dm_exec_cached_plans
WHERE cacheobjtype IN ('Compiled Plan', 'Compiled Plan Stub');
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 15  08b-plan-cache-izleme.md  -- DOGRULA plan cache bellek kullanimi, cache store bazinda';
GO

-- DOGRULA plan cache bellek kullanimi, cache store bazinda
SELECT name AS cache_store, type, CAST(pages_kb / 1024.0 AS decimal(12,1)) AS mb, entries_count, entries_in_use_count
FROM sys.dm_os_memory_cache_counters
WHERE type IN ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP', 'CACHESTORE_PHDR')
ORDER BY pages_kb DESC;
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 16  08b-plan-cache-izleme.md  -- DOGRULA plan cache hit ratio';
GO

-- DOGRULA plan cache hit ratio
SELECT RTRIM(r.instance_name) AS cache_turu,
       CAST(100.0 * r.cntr_value / NULLIF(b.cntr_value, 0) AS decimal(5,1)) AS hit_ratio_yuzde
FROM sys.dm_os_performance_counters AS r
JOIN sys.dm_os_performance_counters AS b
  ON b.object_name = r.object_name AND b.instance_name = r.instance_name AND b.counter_name = 'Cache Hit Ratio Base'
WHERE r.object_name LIKE '%Plan Cache%' AND r.counter_name = 'Cache Hit Ratio'
ORDER BY r.instance_name;
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 17  08b-plan-cache-izleme.md  -- DOGRULA compile ve recompile toplamlari (sunucu baslangicindan beri)';
GO

-- DOGRULA compile ve recompile toplamlari (sunucu baslangicindan beri)
SELECT MAX(CASE WHEN counter_name = 'Batch Requests/sec' THEN cntr_value END) AS batch_toplam,
       MAX(CASE WHEN counter_name = 'SQL Compilations/sec' THEN cntr_value END) AS compile_toplam,
       MAX(CASE WHEN counter_name = 'SQL Re-Compilations/sec' THEN cntr_value END) AS recompile_toplam
FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%SQL Statistics%'
  AND counter_name IN ('Batch Requests/sec', 'SQL Compilations/sec', 'SQL Re-Compilations/sec');
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 18  08b-plan-cache-izleme.md  -- DOGRULA compile orani, 10 saniyelik olcum';
GO

-- DOGRULA compile orani, 10 saniyelik olcum
DECLARE @b1 bigint, @c1 bigint, @r1 bigint, @b2 bigint, @c2 bigint, @r2 bigint;
SELECT @b1 = MAX(CASE WHEN counter_name = 'Batch Requests/sec' THEN cntr_value END),
       @c1 = MAX(CASE WHEN counter_name = 'SQL Compilations/sec' THEN cntr_value END),
       @r1 = MAX(CASE WHEN counter_name = 'SQL Re-Compilations/sec' THEN cntr_value END)
FROM sys.dm_os_performance_counters WHERE object_name LIKE '%SQL Statistics%';
WAITFOR DELAY '00:00:10';
SELECT @b2 = MAX(CASE WHEN counter_name = 'Batch Requests/sec' THEN cntr_value END),
       @c2 = MAX(CASE WHEN counter_name = 'SQL Compilations/sec' THEN cntr_value END),
       @r2 = MAX(CASE WHEN counter_name = 'SQL Re-Compilations/sec' THEN cntr_value END)
FROM sys.dm_os_performance_counters WHERE object_name LIKE '%SQL Statistics%';
SELECT (@b2 - @b1) / 10.0 AS batch_sn, (@c2 - @c1) / 10.0 AS compile_sn, (@r2 - @r1) / 10.0 AS recompile_sn,
       CAST(100.0 * (@c2 - @c1) / NULLIF(@b2 - @b1, 0) AS decimal(6,1)) AS compile_yuzde_batch,
       CAST(100.0 * (@r2 - @r1) / NULLIF(@c2 - @c1, 0) AS decimal(6,1)) AS recompile_yuzde_compile;
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 19  08b-plan-cache-izleme.md  -- DOGRULA en cok yeniden derlenen planlar';
GO

-- DOGRULA en cok yeniden derlenen plan'lar
SELECT TOP (10) qs.plan_generation_num, qs.execution_count, qs.creation_time, qs.last_execution_time,
       DB_NAME(st.dbid) AS veritabani, OBJECT_NAME(st.objectid, st.dbid) AS nesne,
       LEFT(REPLACE(REPLACE(SUBSTRING(st.text, qs.statement_start_offset / 2 + 1, 120), CHAR(13), ' '), CHAR(10), ' '), 100) AS ifade
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY qs.plan_generation_num DESC;
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 20  08b-plan-cache-izleme.md  -- DOGRULA plan cache ne kadar eski';
GO

-- DOGRULA plan cache ne kadar eski
SELECT (SELECT sqlserver_start_time FROM sys.dm_os_sys_info) AS sunucu_baslangic,
       MIN(creation_time) AS en_eski_plan, MAX(creation_time) AS en_yeni_plan, COUNT(*) AS plan_sayisi
FROM sys.dm_exec_query_stats;
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 21  08b-plan-cache-izleme.md  -- DOGRULA bellek baskisiyla atilan plan kayitlari';
GO

-- DOGRULA bellek baskisiyla atilan plan kayitlari
SELECT name, type, clock_hand, clock_status, rounds_count, removed_all_rounds_count
FROM sys.dm_os_memory_cache_clock_hands
WHERE type IN ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP');
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 22  08b-plan-cache-izleme.md  -- DOGRULA ayni sablondan cok sayida plan (parametrelendirme adayi)';
GO

-- DOGRULA ayni sablondan cok sayida plan (parametrelendirme adayi)
SELECT TOP (10) qs.query_hash, COUNT(*) AS plan_sayisi, SUM(qs.execution_count) AS toplam_calisma,
       MIN(LEFT(REPLACE(REPLACE(st.text, CHAR(13), ' '), CHAR(10), ' '), 100)) AS ornek_metin
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
GROUP BY qs.query_hash
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;
GO

USE ornek_kapali;
GO
PRINT '##### BLOK 23  08b-plan-cache-izleme.md  -- DOGRULA optimize for ad hoc workloads ayari';
GO

-- DOGRULA optimize for ad hoc workloads ayari
SELECT name, value, value_in_use FROM sys.configurations WHERE name = N'optimize for ad hoc workloads';
GO

USE qs_demo;
GO
PRINT '##### BLOK 24  10-bekleme-istatistikleri.md  -- DOGRULA son 24 saatte bekleme kategorisine gore toplam bekleme (SQL Server 2017 ve sonr';
GO

-- DOGRULA son 24 saatte bekleme kategorisine gore toplam bekleme (SQL Server 2017 ve sonrasi)
SELECT ws.wait_category_desc,
       COUNT(DISTINCT ws.plan_id)        AS plan_sayisi,
       SUM(ws.total_query_wait_time_ms)  AS toplam_bekleme_ms
FROM sys.query_store_wait_stats AS ws
JOIN sys.query_store_runtime_stats_interval AS i ON i.runtime_stats_interval_id = ws.runtime_stats_interval_id
WHERE i.start_time >= DATEADD(HOUR, -24, SYSUTCDATETIME())
  AND ws.execution_type = 0
GROUP BY ws.wait_category_desc
ORDER BY SUM(ws.total_query_wait_time_ms) DESC;
GO

USE qs_demo;
GO
PRINT '##### BLOK 25  11-otomatik-ayar-yukseltme-replica.md  -- DOGRULA plan duzeltme onerileri, kazanc ve duzeltme betigi';
GO

-- DOGRULA plan duzeltme onerileri, kazanc ve duzeltme betigi
SELECT reason, score,
       script = JSON_VALUE(details, '$.implementationDetails.script'),
       planForceDetails.*,
       estimated_gain = (regressedPlanExecutionCount + recommendedPlanExecutionCount)
                        * (regressedPlanCpuTimeAverage - recommendedPlanCpuTimeAverage) / 1000000,
       error_prone = IIF(regressedPlanErrorCount > recommendedPlanErrorCount, 'YES', 'NO')
FROM sys.dm_db_tuning_recommendations
CROSS APPLY OPENJSON (details, '$.planForceDetails')
     WITH (query_id int '$.queryId',
           regressedPlanId int '$.regressedPlanId',
           recommendedPlanId int '$.recommendedPlanId',
           regressedPlanErrorCount int,
           recommendedPlanErrorCount int,
           regressedPlanExecutionCount int,
           regressedPlanCpuTimeAverage float,
           recommendedPlanExecutionCount int,
           recommendedPlanCpuTimeAverage float) AS planForceDetails;
GO

USE qs_demo;
GO
PRINT '##### BLOK 26  11-otomatik-ayar-yukseltme-replica.md  -- DOGRULA tum replicalar icin son 8 saatte CPUya gore ilk 50 sorgu';
GO

-- DOGRULA tum replica'lar icin son 8 saatte CPU'ya gore ilk 50 sorgu
DECLARE @hours int = 8;
SELECT TOP (50)
       qsq.query_id, qsp.plan_id,
       CASE qrs.replica_group_id WHEN 1 THEN 'PRIMARY' WHEN 2 THEN 'SECONDARY' WHEN 3 THEN 'GEO SECONDARY'
            WHEN 4 THEN 'GEO HA SECONDARY' ELSE CONCAT('NAMED REPLICA_', qrs.replica_group_id) END AS replica_tipi,
       SUM(qrs.count_executions) AS calistirma,
       SUM(qrs.count_executions * qrs.avg_cpu_time / 1000.0) AS toplam_cpu_ms,
       LEFT(qsqt.query_sql_text, 80) AS sorgu
FROM sys.query_store_runtime_stats_interval AS qsrsi
JOIN sys.query_store_runtime_stats AS qrs ON qrs.runtime_stats_interval_id = qsrsi.runtime_stats_interval_id
JOIN sys.query_store_plan AS qsp          ON qsp.plan_id = qrs.plan_id
JOIN sys.query_store_query AS qsq          ON qsq.query_id = qsp.query_id
JOIN sys.query_store_query_text AS qsqt    ON qsq.query_text_id = qsqt.query_text_id
WHERE qsrsi.start_time >= DATEADD(HOUR, -@hours, SYSUTCDATETIME())
GROUP BY qsq.query_id, qsp.plan_id, qrs.replica_group_id, qsqt.query_sql_text
ORDER BY SUM(qrs.count_executions * qrs.avg_cpu_time / 1000.0) DESC;
GO

USE qs_demo;
GO
PRINT '##### BLOK 27  12-isletme-ve-bakim.md  -- DOGRULA Query Store durumu, istenen ile gercek durum farki';
GO

-- DOGRULA Query Store durumu, istenen ile gercek durum farki
SELECT DB_NAME() AS veritabani,
       desired_state_desc, actual_state_desc, readonly_reason,
       current_storage_size_mb, max_storage_size_mb,
       CAST(100.0 * current_storage_size_mb / NULLIF(max_storage_size_mb, 0) AS decimal(5,1)) AS doluluk_yuzde
FROM sys.database_query_store_options;
GO

USE qs_demo;
GO
PRINT '##### BLOK 28  12b-ek-konular.md  -- DOGRULA sabitlemesi basarisiz olan planlar';
GO

-- DOGRULA sabitlemesi basarisiz olan planlar
SELECT p.query_id, p.plan_id, p.force_failure_count,
       p.last_force_failure_reason, p.last_force_failure_reason_desc
FROM sys.query_store_plan AS p
WHERE p.is_forced_plan = 1 AND p.last_force_failure_reason <> 0;
GO

USE qs_demo;
GO
PRINT '##### BLOK 29  12b-ek-konular.md  -- DOGRULA Query Store bellek kullanimi';
GO

-- DOGRULA Query Store bellek kullanimi
SELECT type, SUM(pages_kb) AS pages_kb
FROM sys.dm_os_memory_clerks
WHERE type LIKE '%QUERYDISKSTORE%' OR type LIKE '%QDS%'
GROUP BY type
ORDER BY pages_kb DESC;
GO

USE ornek_dolu;
GO
PRINT '##### BLOK 30  13-tuzaklar-ve-kontrol-listesi.md  -- DOGRULA ad hoc yuk suphesi: metin, sorgu ve plan sayilari';
GO

-- DOGRULA ad hoc yuk suphesi: metin, sorgu ve plan sayilari
SELECT COUNT(*)                     AS sorgu_metni_sayisi FROM sys.query_store_query_text;
SELECT COUNT(*)                     AS sorgu_sayisi      FROM sys.query_store_query;
SELECT COUNT(DISTINCT query_hash)   AS farkli_query_hash FROM sys.query_store_query;
SELECT COUNT(*)                     AS plan_sayisi       FROM sys.query_store_plan;
SELECT COUNT(DISTINCT query_plan_hash) AS farkli_plan_hash FROM sys.query_store_plan;
GO

USE ornek_dolu;
GO
PRINT '##### BLOK 31  13-tuzaklar-ve-kontrol-listesi.md  -- DOGRULA en cok tekrar eden sorgu sablonlari (ayni query_hash, farkli metin)';
GO

-- DOGRULA en cok tekrar eden sorgu sablonlari (ayni query_hash, farkli metin)
SELECT TOP (10) q.query_hash,
       COUNT(DISTINCT q.query_text_id) AS farkli_metin,
       COUNT(*)                        AS query_kaydi,
       MIN(LEFT(qt.query_sql_text, 80)) AS ornek_metin
FROM sys.query_store_query AS q
JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
GROUP BY q.query_hash
HAVING COUNT(DISTINCT q.query_text_id) > 1
ORDER BY COUNT(DISTINCT q.query_text_id) DESC;
GO

USE qs_demo;
GO
PRINT '##### BLOK 32  14-hazir-betikler.md  -- DOGRULA tum kullanici veritabanlarinda Query Store durumu (SQL Server 2017 ve sonrasi)';
GO

-- DOGRULA tum kullanici veritabanlarinda Query Store durumu (SQL Server 2017 ve sonrasi)
SET NOCOUNT ON;
DROP TABLE IF EXISTS #qs;
CREATE TABLE #qs (veritabani sysname, desired_state_desc nvarchar(60) NULL, actual_state_desc nvarchar(60) NULL, readonly_reason int NULL,
                  current_storage_size_mb bigint NULL, max_storage_size_mb bigint NULL, query_capture_mode_desc nvarchar(60) NULL, hata nvarchar(400) NULL);
DECLARE @db sysname, @sql nvarchar(max);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
  SELECT d.name FROM sys.databases AS d
  WHERE d.database_id > 4 AND d.state = 0 AND d.is_query_store_on = 1 AND d.source_database_id IS NULL
    AND NOT EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states AS s
                    WHERE s.database_id = d.database_id AND s.is_local = 1 AND s.is_primary_replica = 0);
OPEN c; FETCH NEXT FROM c INTO @db;
WHILE @@FETCH_STATUS = 0
BEGIN
  BEGIN TRY
    SET @sql = N'INSERT #qs (veritabani, desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb, max_storage_size_mb, query_capture_mode_desc) '
             + N'SELECT @d, desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb, max_storage_size_mb, query_capture_mode_desc FROM '
             + QUOTENAME(@db) + N'.sys.database_query_store_options';
    EXEC sys.sp_executesql @sql, N'@d sysname', @d = @db;
  END TRY
  BEGIN CATCH
    INSERT #qs (veritabani, hata) VALUES (@db, LEFT(ERROR_MESSAGE(), 400));
  END CATCH
  FETCH NEXT FROM c INTO @db;
END
CLOSE c; DEALLOCATE c;
IF NOT EXISTS (SELECT 1 FROM #qs)
    SELECT 'Query Store acik kullanici veritabani yok' AS sonuc;
ELSE
    SELECT * FROM #qs ORDER BY veritabani;
GO

USE qs_demo;
GO
PRINT '##### BLOK 33  14-hazir-betikler.md  -- DOGRULA sorunlu Query Store veritabanlari (durum farki ya da doluluk > 90)';
GO

-- DOGRULA sorunlu Query Store veritabanlari (durum farki ya da doluluk > 90)
SET NOCOUNT ON;
DROP TABLE IF EXISTS #qs;
CREATE TABLE #qs (veritabani sysname, desired_state_desc nvarchar(60) NULL, actual_state_desc nvarchar(60) NULL, readonly_reason int NULL,
                  current_storage_size_mb bigint NULL, max_storage_size_mb bigint NULL, query_capture_mode_desc nvarchar(60) NULL, hata nvarchar(400) NULL);
DECLARE @db sysname, @sql nvarchar(max);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
  SELECT d.name FROM sys.databases AS d
  WHERE d.database_id > 4 AND d.state = 0 AND d.is_query_store_on = 1 AND d.source_database_id IS NULL
    AND NOT EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states AS s
                    WHERE s.database_id = d.database_id AND s.is_local = 1 AND s.is_primary_replica = 0);
OPEN c; FETCH NEXT FROM c INTO @db;
WHILE @@FETCH_STATUS = 0
BEGIN
  BEGIN TRY
    SET @sql = N'INSERT #qs (veritabani, desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb, max_storage_size_mb, query_capture_mode_desc) '
             + N'SELECT @d, desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb, max_storage_size_mb, query_capture_mode_desc FROM '
             + QUOTENAME(@db) + N'.sys.database_query_store_options';
    EXEC sys.sp_executesql @sql, N'@d sysname', @d = @db;
  END TRY
  BEGIN CATCH
    INSERT #qs (veritabani, hata) VALUES (@db, LEFT(ERROR_MESSAGE(), 400));
  END CATCH
  FETCH NEXT FROM c INTO @db;
END
CLOSE c; DEALLOCATE c;
SELECT * FROM #qs
WHERE hata IS NOT NULL
   OR actual_state_desc <> desired_state_desc
   OR actual_state_desc = N'ERROR'
   OR (max_storage_size_mb > 0 AND 100.0 * current_storage_size_mb / max_storage_size_mb > 90)
ORDER BY veritabani;
GO

USE qs_demo;
GO
PRINT '##### BLOK 34  14-hazir-betikler.md  -- DOGRULA Query Store kapali kullanici veritabanlari icin acma komutlari (@calistir = 0 y';
GO

-- DOGRULA Query Store kapali kullanici veritabanlari icin acma komutlari (@calistir = 0 yalnizca yazdirir)
SET NOCOUNT ON;
DECLARE @calistir bit = 0, @en_fazla int = 10, @bekleme char(8) = '00:00:05', @tavan_mb int = 1000;
DECLARE @haric TABLE (name sysname);                -- satici veritabanlarini buraya ekleyin
DECLARE @db sysname, @cmd nvarchar(max), @adet int = 0;
DECLARE @bekleme_ayari nvarchar(60) = CASE WHEN CAST(SERVERPROPERTY('ProductMajorVersion') AS int) >= 14 THEN N', WAIT_STATS_CAPTURE_MODE = ON' ELSE N'' END;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
  SELECT d.name FROM sys.databases AS d
  WHERE d.database_id > 4 AND d.state = 0 AND d.is_read_only = 0 AND d.is_query_store_on = 0
        AND d.user_access = 0 AND d.is_distributor = 0 AND d.source_database_id IS NULL
        AND d.name NOT IN (SELECT name FROM @haric)
        AND NOT EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states AS s
                        WHERE s.database_id = d.database_id AND s.is_local = 1 AND s.is_primary_replica = 0)
  ORDER BY d.name;
OPEN c; FETCH NEXT FROM c INTO @db;
WHILE @@FETCH_STATUS = 0 AND @adet < @en_fazla
BEGIN
  SET @cmd = N'ALTER DATABASE ' + QUOTENAME(@db) + N' SET QUERY_STORE = ON ('
           + N'OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), '
           + N'DATA_FLUSH_INTERVAL_SECONDS = 900, MAX_STORAGE_SIZE_MB = ' + CAST(@tavan_mb AS nvarchar(10)) + N', INTERVAL_LENGTH_MINUTES = 60, '
           + N'SIZE_BASED_CLEANUP_MODE = AUTO, QUERY_CAPTURE_MODE = AUTO, MAX_PLANS_PER_QUERY = 200' + @bekleme_ayari + N')';
  PRINT @cmd;
  BEGIN TRY
    IF @calistir = 1 BEGIN EXEC sys.sp_executesql @cmd; WAITFOR DELAY @bekleme; END
  END TRY
  BEGIN CATCH
    PRINT N'HATA ' + @db + N': ' + LEFT(ERROR_MESSAGE(), 300);
  END CATCH
  SET @adet += 1;
  FETCH NEXT FROM c INTO @db;
END
CLOSE c; DEALLOCATE c;
SELECT @adet AS islenen_veritabani, @adet * @tavan_mb AS rezerve_toplam_mb;
GO

USE qs_demo;
GO
PRINT '##### BLOK 35  14-hazir-betikler.md  -- DOGRULA Query Store hint envanteri (SQL Server 2022 ve sonrasi)';
GO

-- DOGRULA Query Store hint envanteri (SQL Server 2022 ve sonrasi)
SELECT h.query_id, h.query_hint_text, h.source_desc, h.query_hint_failure_count,
       h.last_query_hint_failure_reason_desc, LEFT(qt.query_sql_text, 80) AS sorgu
FROM sys.query_store_query_hints AS h
JOIN sys.query_store_query AS q       ON q.query_id = h.query_id
JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
ORDER BY h.query_id;
GO

USE qs_demo;
GO
PRINT '##### BLOK 36  14-hazir-betikler.md  -- DOGRULA zorlanan planlar ve hata durumlari';
GO

-- DOGRULA zorlanan planlar ve hata durumlari
SELECT p.query_id, p.plan_id, p.force_failure_count, p.last_force_failure_reason_desc,
       p.last_compile_start_time, LEFT(qt.query_sql_text, 80) AS sorgu
FROM sys.query_store_plan AS p
JOIN sys.query_store_query AS q       ON q.query_id = p.query_id
JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
WHERE p.is_forced_plan = 1
ORDER BY p.force_failure_count DESC;
GO

USE qs_demo;
GO
PRINT '##### BLOK 37  14-hazir-betikler.md  -- DOGRULA ad hoc ve ic sorgulari Query Storedan temizle (son 5 dakikada calismayanlar)';
GO

-- DOGRULA ad hoc ve ic sorgulari Query Storedan temizle (son 5 dakikada calismayanlar)
SET NOCOUNT ON;
DECLARE @dakika int = 10080, @parti int = 200, @id bigint, @n int = 1, @silinen int = 0;
IF NOT EXISTS (SELECT 1 FROM sys.database_query_store_options WHERE actual_state_desc = N'READ_WRITE')
BEGIN RAISERROR(N'Query Store READ_WRITE degil, betik calismadi.', 16, 1); RETURN; END
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

USE qs_demo;
GO
PRINT '##### BLOK 38  14-hazir-betikler.md  -- DOGRULA son 24 saat ile onceki 24 saati karsilastir, ortalama suresi 2 kat artanlar';
GO

-- DOGRULA son 24 saat ile onceki 24 saati karsilastir, ortalama suresi 2 kat artanlar
WITH son AS (
  SELECT p.query_id, SUM(rs.avg_duration * rs.count_executions) / NULLIF(SUM(rs.count_executions), 0) AS ort_us,
         SUM(rs.count_executions) AS adet
  FROM sys.query_store_runtime_stats AS rs
  JOIN sys.query_store_plan AS p ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval AS i ON i.runtime_stats_interval_id = rs.runtime_stats_interval_id
  WHERE i.start_time >= DATEADD(HOUR, -24, SYSUTCDATETIME())
  GROUP BY p.query_id
), onceki AS (
  SELECT p.query_id, SUM(rs.avg_duration * rs.count_executions) / NULLIF(SUM(rs.count_executions), 0) AS ort_us,
         SUM(rs.count_executions) AS adet
  FROM sys.query_store_runtime_stats AS rs
  JOIN sys.query_store_plan AS p ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval AS i ON i.runtime_stats_interval_id = rs.runtime_stats_interval_id
  WHERE i.start_time >= DATEADD(HOUR, -48, SYSUTCDATETIME()) AND i.start_time < DATEADD(HOUR, -24, SYSUTCDATETIME())
  GROUP BY p.query_id
)
SELECT s.query_id, o.adet AS onceki_adet, s.adet AS son_adet,
       CAST(o.ort_us / 1000.0 AS decimal(18,2)) AS onceki_ort_ms,
       CAST(s.ort_us / 1000.0 AS decimal(18,2)) AS son_ort_ms,
       CAST(s.ort_us / NULLIF(o.ort_us, 0) AS decimal(10,2)) AS kat_artisi
FROM son AS s JOIN onceki AS o ON o.query_id = s.query_id
WHERE s.ort_us > 2 * o.ort_us
ORDER BY (s.ort_us - o.ort_us) * s.adet DESC;
GO

PRINT '##### BITTI';
GO
