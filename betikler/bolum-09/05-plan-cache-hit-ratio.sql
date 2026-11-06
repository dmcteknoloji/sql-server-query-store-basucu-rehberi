-- Query Store Basucu Rehberi, Bolum 9
-- plan cache hit ratio
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT RTRIM(r.instance_name) AS cache_turu,
       CAST(100.0 * r.cntr_value / NULLIF(b.cntr_value, 0) AS decimal(5,1)) AS hit_ratio_yuzde
FROM sys.dm_os_performance_counters AS r
JOIN sys.dm_os_performance_counters AS b
  ON b.object_name = r.object_name AND b.instance_name = r.instance_name AND b.counter_name = 'Cache Hit Ratio Base'
WHERE r.object_name LIKE '%Plan Cache%' AND r.counter_name = 'Cache Hit Ratio'
ORDER BY r.instance_name;
