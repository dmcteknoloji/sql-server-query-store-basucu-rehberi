-- SQL Server Query Store Basucu Rehberi, Bolum 9, 'Otomatik parametrelendirme'
-- Test ortaminda calistirin.

-- Query Store'da parametrelendirme turu dagilimi
SELECT q.query_parameterization_type_desc AS tur, COUNT(*) AS query_sayisi
FROM sys.query_store_query AS q
GROUP BY q.query_parameterization_type_desc
ORDER BY query_sayisi DESC;
