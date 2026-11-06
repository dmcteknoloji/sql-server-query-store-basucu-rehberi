-- Query Store Basucu Rehberi, Bolum 11
-- son 24 saatte bekleme kategorisine gore toplam bekleme (SQL Server 2017 ve sonrasi)
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT ws.wait_category_desc,
       COUNT(DISTINCT ws.plan_id)        AS plan_sayisi,
       SUM(ws.total_query_wait_time_ms)  AS toplam_bekleme_ms
FROM sys.query_store_wait_stats AS ws
JOIN sys.query_store_runtime_stats_interval AS i ON i.runtime_stats_interval_id = ws.runtime_stats_interval_id
WHERE i.start_time >= DATEADD(HOUR, -24, SYSUTCDATETIME())
  AND ws.execution_type = 0
GROUP BY ws.wait_category_desc
ORDER BY SUM(ws.total_query_wait_time_ms) DESC;
