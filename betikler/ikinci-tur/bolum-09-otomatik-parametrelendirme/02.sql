-- SQL Server Query Store Basucu Rehberi, Bolum 9, 'Otomatik parametrelendirme'
-- Test ortaminda calistirin.

SELECT TOP (20) q.query_id, q.query_parameterization_type_desc AS tur,
       SUM(rs.count_executions) AS calisma,
       MIN(rs.min_duration) / 1000.0 AS en_kucuk_ms,
       MAX(rs.max_duration) / 1000.0 AS en_buyuk_ms,
       CAST(MAX(rs.max_duration) * 1.0 / NULLIF(MIN(NULLIF(rs.min_duration, 0)), 0) AS decimal(18,1)) AS dalgalanma_orani,
       COUNT(DISTINCT p.plan_id) AS plan_sayisi,
       LEFT(t.query_sql_text, 120) AS metin
FROM sys.query_store_query q
JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id
JOIN sys.query_store_plan p ON p.query_id = q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
WHERE q.query_parameterization_type_desc = N'Forced'
GROUP BY q.query_id, q.query_parameterization_type_desc, t.query_sql_text
HAVING SUM(rs.count_executions) >= 20
ORDER BY dalgalanma_orani DESC;
