-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Flush penceresi örnekleyici'
-- Yalnizca test ortaminda calistirin.

SET NOCOUNT ON;
USE qs_lab_flush;
INSERT dbo.flush_spid VALUES (@@SPID);
SELECT SYSDATETIME() AS flush_basladi, @@SPID AS spid;
GO
EXEC sys.sp_query_store_flush_db;
GO
SELECT SYSDATETIME() AS flush_bitti;
GO
