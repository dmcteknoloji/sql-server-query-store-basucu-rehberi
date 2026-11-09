-- SQL Server Query Store Handbook, Chapter 9, 'Automatic parameterization'
-- Run in a test environment only.

-- Distribution of parameterization types in Query Store
SELECT q.query_parameterization_type_desc AS tur, COUNT(*) AS query_sayisi
FROM sys.query_store_query AS q
GROUP BY q.query_parameterization_type_desc
ORDER BY query_sayisi DESC;
