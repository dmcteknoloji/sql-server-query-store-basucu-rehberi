-- SQL Server Query Store Basucu Rehberi, Bolum 7
-- ayni sorgunun planlari yan yana
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

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
