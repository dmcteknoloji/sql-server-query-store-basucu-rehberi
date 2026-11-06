-- SQL Server Query Store Basucu Rehberi, Bolum 13
-- Query Store durumu, istenen ile gercek durum farki
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT DB_NAME() AS veritabani,
       desired_state_desc, actual_state_desc, readonly_reason,
       current_storage_size_mb, max_storage_size_mb,
       CAST(100.0 * current_storage_size_mb / NULLIF(max_storage_size_mb, 0) AS decimal(5,1)) AS doluluk_yuzde
FROM sys.database_query_store_options;
