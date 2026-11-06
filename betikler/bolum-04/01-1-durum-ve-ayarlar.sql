-- SQL Server Query Store Basucu Rehberi, Bolum 4
-- 1) durum ve ayarlar
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT actual_state_desc, desired_state_desc, readonly_reason,
       interval_length_minutes, max_storage_size_mb, query_capture_mode_desc,
       wait_stats_capture_mode_desc
FROM sys.database_query_store_options;
