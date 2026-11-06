-- Query Store Basucu Rehberi, Bolum 3
-- Query Store dahili durumu (SQL Server 2022 ve sonrasi)
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT pending_message_count, messaging_memory_used_mb
FROM sys.database_query_store_internal_state;
