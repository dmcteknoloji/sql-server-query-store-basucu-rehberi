-- SQL Server Query Store Basucu Rehberi, Bolum 9
-- bellek baskisiyla atilan plan kayitlari
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT name, type, clock_hand, clock_status, rounds_count, removed_all_rounds_count
FROM sys.dm_os_memory_cache_clock_hands
WHERE type IN ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP');
