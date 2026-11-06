-- Query Store Basucu Rehberi, Bolum 9
-- plan cache bellek kullanimi, cache store bazinda
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT name AS cache_store, type, CAST(pages_kb / 1024.0 AS decimal(12,1)) AS mb, entries_count, entries_in_use_count
FROM sys.dm_os_memory_cache_counters
WHERE type IN ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP', 'CACHESTORE_PHDR')
ORDER BY pages_kb DESC;
