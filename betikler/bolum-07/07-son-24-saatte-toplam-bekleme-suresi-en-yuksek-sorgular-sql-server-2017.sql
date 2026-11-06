-- Query Store Basucu Rehberi, Bolum 7
-- son 24 saatte toplam bekleme suresi en yuksek sorgular (SQL Server 2017 ve sonrasi)
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

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
