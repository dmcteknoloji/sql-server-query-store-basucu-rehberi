-- SQL Server Query Store Basucu Rehberi, Bolum 14
-- sabitlemesi basarisiz olan planlar
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT p.query_id, p.plan_id, p.force_failure_count,
       p.last_force_failure_reason, p.last_force_failure_reason_desc
FROM sys.query_store_plan AS p
WHERE p.is_forced_plan = 1 AND p.last_force_failure_reason <> 0;
