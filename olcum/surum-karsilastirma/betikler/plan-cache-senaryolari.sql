SET NOCOUNT ON;
SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar(40)) AS surum;
GO
IF DB_ID('pc_demo') IS NOT NULL BEGIN ALTER DATABASE pc_demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE pc_demo; END
CREATE DATABASE pc_demo;
GO
USE pc_demo;
GO
CREATE TABLE dbo.T(id int IDENTITY PRIMARY KEY, k int NOT NULL, v char(100) NOT NULL DEFAULT 'x');
INSERT dbo.T(k) SELECT TOP (20000) ABS(CHECKSUM(NEWID())) % 1000 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
CREATE INDEX ix_k ON dbo.T(k);
GO
CREATE PROCEDURE dbo.Say @k int AS BEGIN DECLARE @a int; SELECT @a = COUNT(*) FROM dbo.T WHERE k = @k OR id = @k + 1; END
GO
CREATE TABLE dbo.Sayac(n int IDENTITY, ad varchar(30), batch bigint, comp bigint, recomp bigint);
GO
CREATE PROCEDURE dbo.SayacAl @ad varchar(30) AS
INSERT dbo.Sayac(ad, batch, comp, recomp)
SELECT @ad, MAX(CASE WHEN counter_name='Batch Requests/sec' THEN cntr_value END), MAX(CASE WHEN counter_name='SQL Compilations/sec' THEN cntr_value END), MAX(CASE WHEN counter_name='SQL Re-Compilations/sec' THEN cntr_value END)
FROM sys.dm_os_performance_counters WHERE object_name LIKE '%SQL Statistics%';
GO
DBCC FREEPROCCACHE;
GO
PRINT '##### SENARYOLAR';
EXEC dbo.SayacAl 'A_once';
GO
DECLARE @i int = 0, @s nvarchar(300), @x int;
WHILE @i < 2000 BEGIN SET @s = N'SELECT @r = COUNT(*) FROM dbo.T WHERE k = ' + CAST(@i % 1000 AS nvarchar(10)) + N' OR id = ' + CAST(@i + 5 AS nvarchar(10)); EXEC sp_executesql @s, N'@r int OUTPUT', @r = @x OUTPUT; SET @i += 1; END
GO
EXEC dbo.SayacAl 'A_sonra';
GO
EXEC dbo.SayacAl 'B_once';
GO
DECLARE @i int = 0, @x int;
WHILE @i < 2000 BEGIN EXEC sp_executesql N'SELECT @r = COUNT(*) FROM dbo.T WHERE k = @k OR id = @k + 1', N'@k int, @r int OUTPUT', @k = @i, @r = @x OUTPUT; SET @i += 1; END
GO
EXEC dbo.SayacAl 'B_sonra';
GO
EXEC dbo.SayacAl 'C_once';
GO
DECLARE @i int = 0;
WHILE @i < 2000 BEGIN EXEC dbo.Say @i; SET @i += 1; END
GO
EXEC dbo.SayacAl 'C_sonra';
GO
SELECT LEFT(a.ad, 1) AS senaryo, 2000 AS calistirma, b.comp - a.comp AS compile, b.recomp - a.recomp AS recompile
FROM dbo.Sayac a JOIN dbo.Sayac b ON b.ad = LEFT(a.ad, 1) + '_sonra' WHERE a.ad LIKE '%[_]once' ORDER BY a.n;
GO
PRINT '##### CACHE BLOKLARI';
GO
-- plan cache genel durum, tur bazinda
SELECT cp.objtype AS tur, cp.cacheobjtype, COUNT(*) AS plan_sayisi,
       CAST(SUM(CAST(cp.size_in_bytes AS bigint)) / 1048576.0 AS decimal(12,1)) AS toplam_mb,
       SUM(CASE WHEN cp.usecounts = 1 THEN 1 ELSE 0 END) AS tek_kullanimlik,
       CAST(SUM(CASE WHEN cp.usecounts = 1 THEN CAST(cp.size_in_bytes AS bigint) ELSE 0 END) / 1048576.0 AS decimal(12,1)) AS tek_kullanimlik_mb
FROM sys.dm_exec_cached_plans AS cp
GROUP BY cp.objtype, cp.cacheobjtype
ORDER BY toplam_mb DESC;
GO
-- tek kullanimlik plan orani
SELECT CAST(SUM(CASE WHEN usecounts = 1 THEN CAST(size_in_bytes AS bigint) ELSE 0 END) * 100.0
            / NULLIF(SUM(CAST(size_in_bytes AS bigint)), 0) AS decimal(5,1)) AS tek_kullanimlik_yuzde_mb,
       CAST(SUM(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS decimal(5,1)) AS tek_kullanimlik_yuzde_adet
FROM sys.dm_exec_cached_plans
WHERE cacheobjtype IN ('Compiled Plan', 'Compiled Plan Stub');
GO
-- plan cache bellek kullanimi, cache store bazinda
SELECT name AS cache_store, type, CAST(pages_kb / 1024.0 AS decimal(12,1)) AS mb, entries_count, entries_in_use_count
FROM sys.dm_os_memory_cache_counters
WHERE type IN ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP', 'CACHESTORE_PHDR')
ORDER BY pages_kb DESC;
GO
-- plan cache hit ratio
SELECT RTRIM(r.instance_name) AS cache_turu,
       CAST(100.0 * r.cntr_value / NULLIF(b.cntr_value, 0) AS decimal(5,1)) AS hit_ratio_yuzde
FROM sys.dm_os_performance_counters AS r
JOIN sys.dm_os_performance_counters AS b
  ON b.object_name = r.object_name AND b.instance_name = r.instance_name AND b.counter_name = 'Cache Hit Ratio Base'
WHERE r.object_name LIKE '%Plan Cache%' AND r.counter_name = 'Cache Hit Ratio'
ORDER BY r.instance_name;
GO
-- compile ve recompile toplamlari (sunucu baslangicindan beri)
SELECT MAX(CASE WHEN counter_name = 'Batch Requests/sec' THEN cntr_value END) AS batch_toplam,
       MAX(CASE WHEN counter_name = 'SQL Compilations/sec' THEN cntr_value END) AS compile_toplam,
       MAX(CASE WHEN counter_name = 'SQL Re-Compilations/sec' THEN cntr_value END) AS recompile_toplam
FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%SQL Statistics%'
  AND counter_name IN ('Batch Requests/sec', 'SQL Compilations/sec', 'SQL Re-Compilations/sec');
GO
-- compile orani, 10 saniyelik olcum
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
-- en cok yeniden derlenen plan'lar
SELECT TOP (10) qs.plan_generation_num, qs.execution_count, qs.creation_time, qs.last_execution_time,
       DB_NAME(st.dbid) AS veritabani, OBJECT_NAME(st.objectid, st.dbid) AS nesne,
       LEFT(REPLACE(REPLACE(SUBSTRING(st.text, qs.statement_start_offset / 2 + 1, 120), CHAR(13), ' '), CHAR(10), ' '), 100) AS ifade
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY qs.plan_generation_num DESC;
GO
-- plan cache ne kadar eski
SELECT (SELECT sqlserver_start_time FROM sys.dm_os_sys_info) AS sunucu_baslangic,
       MIN(creation_time) AS en_eski_plan, MAX(creation_time) AS en_yeni_plan, COUNT(*) AS plan_sayisi
FROM sys.dm_exec_query_stats;
GO
-- bellek baskisiyla atilan plan kayitlari
SELECT name, type, clock_hand, clock_status, rounds_count, removed_all_rounds_count
FROM sys.dm_os_memory_cache_clock_hands
WHERE type IN ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP');
GO
-- ayni sablondan cok sayida plan (parametrelendirme adayi)
SELECT TOP (10) qs.query_hash, COUNT(*) AS plan_sayisi, SUM(qs.execution_count) AS toplam_calisma,
       MIN(LEFT(REPLACE(REPLACE(st.text, CHAR(13), ' '), CHAR(10), ' '), 100)) AS ornek_metin
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
GROUP BY qs.query_hash
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;
GO
-- optimize for ad hoc workloads ayari
SELECT name, value, value_in_use FROM sys.configurations WHERE name = N'optimize for ad hoc workloads';
GO
PRINT '##### AD HOC AYARI: KAPALI';
GO
DBCC FREEPROCCACHE;
GO
DECLARE @i int = 0, @s nvarchar(300), @x int;
WHILE @i < 2000 BEGIN SET @s = N'SELECT @r = COUNT(*) FROM dbo.T WHERE k = ' + CAST(@i % 1000 AS nvarchar(10)) + N' OR id = ' + CAST(@i + 5 AS nvarchar(10)); EXEC sp_executesql @s, N'@r int OUTPUT', @r = @x OUTPUT; SET @i += 1; END
GO
SELECT 'ayar KAPALI' AS durum, cp.cacheobjtype, cp.objtype, COUNT(*) AS plan_sayisi, CAST(SUM(CAST(cp.size_in_bytes AS bigint))/1048576.0 AS decimal(10,2)) AS mb FROM sys.dm_exec_cached_plans cp WHERE cp.objtype IN ('Adhoc','Prepared') AND cp.cacheobjtype LIKE 'Compiled Plan%' GROUP BY cp.cacheobjtype, cp.objtype;
GO
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'optimize for ad hoc workloads', 1; RECONFIGURE;
GO
PRINT '##### AD HOC AYARI: ACIK';
DBCC FREEPROCCACHE;
GO
DECLARE @i int = 0, @s nvarchar(300), @x int;
WHILE @i < 2000 BEGIN SET @s = N'SELECT @r = COUNT(*) FROM dbo.T WHERE k = ' + CAST(@i % 1000 AS nvarchar(10)) + N' OR id = ' + CAST(@i + 5 AS nvarchar(10)); EXEC sp_executesql @s, N'@r int OUTPUT', @r = @x OUTPUT; SET @i += 1; END
GO
SELECT 'ayar ACIK' AS durum, cp.cacheobjtype, cp.objtype, COUNT(*) AS plan_sayisi, CAST(SUM(CAST(cp.size_in_bytes AS bigint))/1048576.0 AS decimal(10,2)) AS mb FROM sys.dm_exec_cached_plans cp WHERE cp.objtype IN ('Adhoc','Prepared') AND cp.cacheobjtype LIKE 'Compiled Plan%' GROUP BY cp.cacheobjtype, cp.objtype;
GO
EXEC sp_configure 'optimize for ad hoc workloads', 0; RECONFIGURE;
GO
PRINT '##### BITTI';
