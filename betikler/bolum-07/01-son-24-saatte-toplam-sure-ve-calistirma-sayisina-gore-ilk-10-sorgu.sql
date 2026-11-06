-- Query Store Basucu Rehberi, Bolum 7
-- son 24 saatte toplam sure ve calistirma sayisina gore ilk 10 sorgu
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

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
