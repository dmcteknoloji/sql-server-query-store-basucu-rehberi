-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Flush penceresi örnekleyici'
-- Yalnizca test ortaminda calistirin.

SET NOCOUNT ON;
PRINT 'beklemeli_kuyruk_izleme';
DECLARE @i int = 0;
WHILE @i < 24
BEGIN
    SELECT @i * 15 AS doldurmadan_sonra_sn,
           (SELECT COUNT(*) FROM qs_lab_flush.sys.query_store_query) AS gorunen_query,
           (SELECT current_storage_size_mb FROM qs_lab_flush.sys.database_query_store_options) AS qs_mb;
    WAITFOR DELAY '00:00:15';
    SET @i += 1;
END
GO
USE qs_lab_flush;
SELECT SYSDATETIME() AS flush_basladi;
EXEC sys.sp_query_store_flush_db;
SELECT SYSDATETIME() AS flush_bitti;
SELECT COUNT(*) AS flush_sonrasi_query FROM sys.query_store_query;
GO
