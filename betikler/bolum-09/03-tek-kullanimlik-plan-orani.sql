-- SQL Server Query Store Basucu Rehberi, Bolum 9
-- tek kullanimlik plan orani
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT CAST(SUM(CASE WHEN usecounts = 1 THEN CAST(size_in_bytes AS bigint) ELSE 0 END) * 100.0
            / NULLIF(SUM(CAST(size_in_bytes AS bigint)), 0) AS decimal(5,1)) AS tek_kullanimlik_yuzde_mb,
       CAST(SUM(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS decimal(5,1)) AS tek_kullanimlik_yuzde_adet
FROM sys.dm_exec_cached_plans
WHERE cacheobjtype IN ('Compiled Plan', 'Compiled Plan Stub');
