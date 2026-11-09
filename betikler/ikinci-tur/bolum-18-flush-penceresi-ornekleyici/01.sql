-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Flush penceresi örnekleyici'
-- Test ortaminda calistirin.

SET NOCOUNT ON;
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
CREATE TABLE dbo.flush_spid (spid int);
GO
ALTER DATABASE qs_lab_flush SET QUERY_STORE CLEAR;
CHECKPOINT;
GO
USE qs_lab_flush;
DECLARE @i bigint = 700000000, @n int = 0, @s nvarchar(400);
WHILE @n < 60000 BEGIN
  SET @s = N'DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE k = ' + CAST((@i * 7919 + 13) % 1000 AS nvarchar(12)) + N' AND id > ' + CAST(@i AS nvarchar(12));
  EXEC (@s); SET @i += 1; SET @n += 1;
END
GO
SELECT COUNT(*) AS qs_query_sayisi FROM qs_lab_flush.sys.query_store_query;
SELECT current_storage_size_mb FROM qs_lab_flush.sys.database_query_store_options;
GO
