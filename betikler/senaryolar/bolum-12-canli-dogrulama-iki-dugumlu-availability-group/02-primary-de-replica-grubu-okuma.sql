-- SQL Server Query Store Basucu Rehberi, Bolum 12, 'Canlı doğrulama, iki düğümlü Availability Group'
-- Yalnizca test ortaminda calistirin.

-- PRIMARY'de, secondary'de calisan sorgunun replica_group_id ile gorunmesi
EXEC sys.sp_query_store_flush_db;
SELECT CASE rs.replica_group_id WHEN 1 THEN 'PRIMARY' WHEN 2 THEN 'SECONDARY' WHEN 3 THEN 'GEO SECONDARY'
            WHEN 4 THEN 'GEO HA SECONDARY' ELSE CONCAT('GRUP_', rs.replica_group_id) END AS replica_tipi,
       rs.replica_group_id, q.query_id, p.plan_id, SUM(rs.count_executions) AS calisma,
       q.query_parameterization_type_desc AS tur, LEFT(t.query_sql_text, 80) AS metin
FROM sys.query_store_runtime_stats AS rs
JOIN sys.query_store_plan AS p ON p.plan_id = rs.plan_id
JOIN sys.query_store_query AS q ON q.query_id = p.query_id
JOIN sys.query_store_query_text AS t ON t.query_text_id = q.query_text_id
WHERE t.query_sql_text LIKE N'%AgIzleme%' AND t.query_sql_text NOT LIKE N'%query_store%'
GROUP BY rs.replica_group_id, q.query_id, p.plan_id, q.query_parameterization_type_desc, t.query_sql_text
ORDER BY rs.replica_group_id;
