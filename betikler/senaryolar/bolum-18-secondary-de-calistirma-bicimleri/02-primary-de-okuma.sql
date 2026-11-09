-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Secondaryde çalıştırma biçimleri'
-- Yalnizca test ortaminda calistirin.

SET NOCOUNT ON;
USE qs_lab_ag;
EXEC sys.sp_query_store_flush_db;
SELECT q.query_id,
       CASE WHEN q.query_id < 0 THEN N'gecici kimlik' ELSE N'kalici kimlik' END AS kimlik,
       q.query_parameterization_type_desc AS tur,
       SUM(CASE WHEN rs.replica_group_id = 2 THEN rs.count_executions ELSE 0 END) AS secondary_calisma,
       LEFT(t.query_sql_text, 90) AS metin
FROM sys.query_store_query_text AS t
JOIN sys.query_store_query AS q ON q.query_text_id = t.query_text_id
LEFT JOIN sys.query_store_plan AS p ON p.query_id = q.query_id
LEFT JOIN sys.query_store_runtime_stats AS rs ON rs.plan_id = p.plan_id
WHERE t.query_sql_text LIKE N'%ag\_v[1-8]\_%' ESCAPE N'\'
GROUP BY q.query_id, q.query_parameterization_type_desc, t.query_sql_text
ORDER BY t.query_sql_text;
