-- Query Store Basucu Rehberi, Bolum 16
-- zorlanan planlar ve hata durumlari
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT p.query_id, p.plan_id, p.force_failure_count, p.last_force_failure_reason_desc,
       p.last_compile_start_time, LEFT(qt.query_sql_text, 80) AS sorgu
FROM sys.query_store_plan AS p
JOIN sys.query_store_query AS q       ON q.query_id = p.query_id
JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
WHERE p.is_forced_plan = 1
ORDER BY p.force_failure_count DESC;
