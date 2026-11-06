-- Query Store Basucu Rehberi, Bolum 14
-- Query Store bellek kullanimi
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT type, SUM(pages_kb) AS pages_kb
FROM sys.dm_os_memory_clerks
WHERE type LIKE '%QUERYDISKSTORE%' OR type LIKE '%QDS%'
GROUP BY type
ORDER BY pages_kb DESC;
