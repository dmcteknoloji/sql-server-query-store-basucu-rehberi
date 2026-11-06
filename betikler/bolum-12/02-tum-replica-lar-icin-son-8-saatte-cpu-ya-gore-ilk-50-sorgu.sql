-- SQL Server Query Store Basucu Rehberi, Bolum 12
-- tum replica'lar icin son 8 saatte CPU'ya gore ilk 50 sorgu
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

-- (SQL Server 2025 ve sonrasi)
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
