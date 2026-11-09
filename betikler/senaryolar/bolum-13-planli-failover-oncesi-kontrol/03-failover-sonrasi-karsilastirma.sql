-- SQL Server Query Store Basucu Rehberi, Bolum 13, 'Planlı failover öncesi kontrol'
-- Yalnizca test ortaminda calistirin.

SELECT e.query_id, e.plan_id, e.query_plan_hash,
       CASE WHEN p.is_forced_plan = 1 THEN N'yerinde' ELSE N'EKSIK' END AS durum,
       p.force_failure_count, p.last_force_failure_reason_desc
FROM dbo.qs_failover_envanter AS e
LEFT JOIN sys.query_store_plan AS p ON p.plan_id = e.plan_id AND p.query_plan_hash = e.query_plan_hash
WHERE e.tur = 'FORCED_PLAN' AND e.snapshot_id = (SELECT TOP (1) snapshot_id FROM dbo.qs_failover_envanter ORDER BY alinma_zamani_utc DESC);
