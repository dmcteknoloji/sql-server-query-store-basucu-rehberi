-- SQL Server Query Store Basucu Rehberi, Bolum 9
-- compile orani, 10 saniyelik olcum
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

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
