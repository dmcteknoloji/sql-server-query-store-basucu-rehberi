-- Query Store Basucu Rehberi, Bolum 15
-- en cok tekrar eden sorgu sablonlari (ayni query_hash, farkli metin)
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT TOP (10) q.query_hash,
       COUNT(DISTINCT q.query_text_id) AS farkli_metin,
       COUNT(*)                        AS query_kaydi,
       MIN(LEFT(qt.query_sql_text, 80)) AS ornek_metin
FROM sys.query_store_query AS q
JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
GROUP BY q.query_hash
HAVING COUNT(DISTINCT q.query_text_id) > 1
ORDER BY COUNT(DISTINCT q.query_text_id) DESC;
