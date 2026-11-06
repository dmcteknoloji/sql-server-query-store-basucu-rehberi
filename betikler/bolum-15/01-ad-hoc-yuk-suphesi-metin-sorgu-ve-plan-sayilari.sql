-- Query Store Basucu Rehberi, Bolum 15
-- ad hoc yuk suphesi: metin, sorgu ve plan sayilari
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT COUNT(*)                     AS sorgu_metni_sayisi FROM sys.query_store_query_text;
SELECT COUNT(*)                     AS sorgu_sayisi      FROM sys.query_store_query;
SELECT COUNT(DISTINCT query_hash)   AS farkli_query_hash FROM sys.query_store_query;
SELECT COUNT(*)                     AS plan_sayisi       FROM sys.query_store_plan;
SELECT COUNT(DISTINCT query_plan_hash) AS farkli_plan_hash FROM sys.query_store_plan;
