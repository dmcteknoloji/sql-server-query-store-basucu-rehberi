-- SQL Server Query Store Basucu Rehberi, Bolum 9
-- ayni sablondan cok sayida plan (parametrelendirme adayi)
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT TOP (10) qs.query_hash, COUNT(*) AS plan_sayisi, SUM(qs.execution_count) AS toplam_calisma,
       MIN(LEFT(REPLACE(REPLACE(st.text, CHAR(13), ' '), CHAR(10), ' '), 100)) AS ornek_metin
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
GROUP BY qs.query_hash
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;
