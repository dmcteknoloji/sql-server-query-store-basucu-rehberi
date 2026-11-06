-- Query Store Basucu Rehberi, Bolum 9
-- en cok yeniden derlenen plan'lar
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT TOP (10) qs.plan_generation_num, qs.execution_count, qs.creation_time, qs.last_execution_time,
       DB_NAME(st.dbid) AS veritabani, OBJECT_NAME(st.objectid, st.dbid) AS nesne,
       LEFT(REPLACE(REPLACE(SUBSTRING(st.text, qs.statement_start_offset / 2 + 1, 120), CHAR(13), ' '), CHAR(10), ' '), 100) AS ifade
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY qs.plan_generation_num DESC;
