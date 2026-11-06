-- SQL Server Query Store Basucu Rehberi, Bolum 16
-- Query Store hint envanteri (SQL Server 2022 ve sonrasi)
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT h.query_id, h.query_hint_text, h.source_desc, h.query_hint_failure_count,
       h.last_query_hint_failure_reason_desc, LEFT(qt.query_sql_text, 80) AS sorgu
FROM sys.query_store_query_hints AS h
JOIN sys.query_store_query AS q       ON q.query_id = h.query_id
JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
ORDER BY h.query_id;
