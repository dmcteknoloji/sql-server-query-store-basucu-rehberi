-- SQL Server Query Store Basucu Rehberi, Bolum 7
-- durum ve boyut
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT actual_state_desc, desired_state_desc, readonly_reason,
       current_storage_size_mb, max_storage_size_mb,
       interval_length_minutes, stale_query_threshold_days,
       size_based_cleanup_mode_desc, query_capture_mode_desc
FROM sys.database_query_store_options;
