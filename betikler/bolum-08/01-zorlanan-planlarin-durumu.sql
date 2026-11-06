-- Query Store Basucu Rehberi, Bolum 8
-- zorlanan planlarin durumu
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT p.plan_id, p.query_id, q.object_id AS icerik_nesne_id,
       p.is_forced_plan, p.force_failure_count, p.last_force_failure_reason_desc
FROM sys.query_store_plan AS p
JOIN sys.query_store_query AS q ON p.query_id = q.query_id
WHERE p.is_forced_plan = 1;
