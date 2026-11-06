-- SQL Server Query Store Basucu Rehberi, Bolum 9
-- plan cache genel durum, tur bazinda
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT cp.objtype AS tur, cp.cacheobjtype, COUNT(*) AS plan_sayisi,
       CAST(SUM(CAST(cp.size_in_bytes AS bigint)) / 1048576.0 AS decimal(12,1)) AS toplam_mb,
       SUM(CASE WHEN cp.usecounts = 1 THEN 1 ELSE 0 END) AS tek_kullanimlik,
       CAST(SUM(CASE WHEN cp.usecounts = 1 THEN CAST(cp.size_in_bytes AS bigint) ELSE 0 END) / 1048576.0 AS decimal(12,1)) AS tek_kullanimlik_mb
FROM sys.dm_exec_cached_plans AS cp
GROUP BY cp.objtype, cp.cacheobjtype
ORDER BY toplam_mb DESC;
