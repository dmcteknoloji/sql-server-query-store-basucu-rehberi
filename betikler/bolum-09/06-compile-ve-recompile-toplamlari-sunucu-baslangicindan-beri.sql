-- SQL Server Query Store Basucu Rehberi, Bolum 9
-- compile ve recompile toplamlari (sunucu baslangicindan beri)
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT MAX(CASE WHEN counter_name = 'Batch Requests/sec' THEN cntr_value END) AS batch_toplam,
       MAX(CASE WHEN counter_name = 'SQL Compilations/sec' THEN cntr_value END) AS compile_toplam,
       MAX(CASE WHEN counter_name = 'SQL Re-Compilations/sec' THEN cntr_value END) AS recompile_toplam
FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%SQL Statistics%'
  AND counter_name IN ('Batch Requests/sec', 'SQL Compilations/sec', 'SQL Re-Compilations/sec');
