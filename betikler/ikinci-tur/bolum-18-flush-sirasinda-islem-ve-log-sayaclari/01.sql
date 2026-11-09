-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Flush sırasında işlem ve log sayaçları'
-- Test ortaminda calistirin.

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SELECT @@VERSION AS surum;
GO
IF DB_ID('qs_lab_flush') IS NOT NULL BEGIN ALTER DATABASE qs_lab_flush SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_lab_flush; END
GO
CREATE DATABASE qs_lab_flush;
GO
ALTER DATABASE qs_lab_flush SET RECOVERY SIMPLE;
ALTER DATABASE qs_lab_flush SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60);
GO
USE qs_lab_flush;
CREATE TABLE dbo.t (id int NOT NULL PRIMARY KEY, k int NOT NULL, v char(100) NOT NULL DEFAULT 'x');
INSERT dbo.t (id, k) SELECT TOP (200000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)), ABS(CHECKSUM(NEWID())) % 1000 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
CREATE INDEX ix_k ON dbo.t(k);
CREATE TABLE dbo.sayac (an varchar(10), sayac nvarchar(60), deger bigint);
GO
ALTER DATABASE qs_lab_flush SET QUERY_STORE CLEAR;
CHECKPOINT;
GO
USE qs_lab_flush;
DECLARE @i bigint = 800000000, @n int = 0, @s nvarchar(400);
WHILE @n < 60000 BEGIN
  SET @s = N'DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE k = ' + CAST((@i * 7919 + 13) % 1000 AS nvarchar(12)) + N' AND id > ' + CAST(@i AS nvarchar(12));
  EXEC (@s); SET @i += 1; SET @n += 1;
END
GO
-- once: sayaclar
INSERT dbo.sayac
SELECT 'once', RTRIM(counter_name), cntr_value FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%:Databases%' AND instance_name = 'qs_lab_flush'
  AND counter_name IN (N'Transactions/sec', N'Log Flushes/sec', N'Log Bytes Flushed/sec', N'Log Flush Waits/sec', N'Log Flush Write Time (ms)');
INSERT dbo.sayac SELECT 'once', 'log_num_of_writes', num_of_writes FROM sys.dm_io_virtual_file_stats(DB_ID(), 2);
INSERT dbo.sayac SELECT 'once', 'log_bytes_written', num_of_bytes_written FROM sys.dm_io_virtual_file_stats(DB_ID(), 2);
INSERT dbo.sayac SELECT 'once', 'qs_query', COUNT(*) FROM sys.query_store_query;
GO
DECLARE @t0 datetime2 = SYSDATETIME();
EXEC sys.sp_query_store_flush_db;
SELECT DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) AS flush_ms;
GO
INSERT dbo.sayac
SELECT 'sonra', RTRIM(counter_name), cntr_value FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%:Databases%' AND instance_name = 'qs_lab_flush'
  AND counter_name IN (N'Transactions/sec', N'Log Flushes/sec', N'Log Bytes Flushed/sec', N'Log Flush Waits/sec', N'Log Flush Write Time (ms)');
INSERT dbo.sayac SELECT 'sonra', 'log_num_of_writes', num_of_writes FROM sys.dm_io_virtual_file_stats(DB_ID(), 2);
INSERT dbo.sayac SELECT 'sonra', 'log_bytes_written', num_of_bytes_written FROM sys.dm_io_virtual_file_stats(DB_ID(), 2);
INSERT dbo.sayac SELECT 'sonra', 'qs_query', COUNT(*) FROM sys.query_store_query;
GO
SELECT s.sayac, s.deger AS once, k.deger AS sonra, k.deger - s.deger AS fark
FROM dbo.sayac s JOIN dbo.sayac k ON k.sayac = s.sayac AND k.an = 'sonra' WHERE s.an = 'once' ORDER BY s.sayac;
