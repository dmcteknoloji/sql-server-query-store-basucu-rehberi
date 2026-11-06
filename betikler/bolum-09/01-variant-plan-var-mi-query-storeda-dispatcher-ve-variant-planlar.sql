-- Query Store Basucu Rehberi, Bolum 9
-- variant plan var mi, Query Storeda dispatcher ve variant planlar
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

-- (SQL Server 2022 ve sonrasi)
SELECT q.object_id, p.plan_type_desc, COUNT(*) AS plan_adedi
FROM sys.query_store_plan AS p
JOIN sys.query_store_query AS q ON q.query_id = p.query_id
WHERE p.plan_type_desc IN (N'Dispatcher Plan', N'Query Variant Plan')
GROUP BY q.object_id, p.plan_type_desc;
