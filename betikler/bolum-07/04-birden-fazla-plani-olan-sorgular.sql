-- SQL Server Query Store Basucu Rehberi, Bolum 7
-- birden fazla plani olan sorgular
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT q.query_id,
       OBJECT_NAME(q.object_id)        AS icerik_nesne,
       COUNT(DISTINCT p.plan_id)       AS plan_sayisi,
       STRING_AGG(CAST(p.plan_id AS varchar(12)), ',') AS plan_idleri,
       LEFT(qt.query_sql_text, 80)     AS sorgu
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p  ON p.query_id = q.query_id
GROUP BY q.query_id, q.object_id, qt.query_sql_text
HAVING COUNT(DISTINCT p.plan_id) > 1
ORDER BY plan_sayisi DESC;
