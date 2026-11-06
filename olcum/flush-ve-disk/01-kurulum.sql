SET NOCOUNT ON;
SELECT @@VERSION AS surum;
GO
IF DB_ID('qs_lab_flush') IS NOT NULL BEGIN ALTER DATABASE qs_lab_flush SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_lab_flush; END
GO
CREATE DATABASE qs_lab_flush ON PRIMARY (NAME = fl_d, FILENAME = 'F:\data\qs_lab_flush.mdf', SIZE = 4096MB, FILEGROWTH = 0)
LOG ON (NAME = fl_l, FILENAME = 'F:\data\qs_lab_flush.ldf', SIZE = 1024MB, FILEGROWTH = 0);
GO
ALTER DATABASE qs_lab_flush SET RECOVERY SIMPLE;
ALTER DATABASE qs_lab_flush SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 3000, SIZE_BASED_CLEANUP_MODE = AUTO);
GO
USE qs_lab_flush;
CREATE TABLE dbo.t (id int NOT NULL PRIMARY KEY, k int NOT NULL, v char(100) NOT NULL DEFAULT 'x');
INSERT dbo.t (id, k) SELECT TOP (200000) ROW_NUMBER() OVER (ORDER BY (SELECT 1)), ABS(CHECKSUM(NEWID())) % 1000 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
CREATE INDEX ix_k ON dbo.t(k);
CREATE TABLE dbo.o_tput (spid int, sn datetime2(0), n int);
CREATE TABLE dbo.o_io (sn datetime2(0), yazma bigint, bayt bigint, stall_ms bigint, qs_mb int, w_pageiolatch bigint, w_writelog bigint, w_qds bigint, w_qds_persist bigint, w_io_comp bigint, w_chkpt bigint, bekleyen_io int);
CREATE TABLE dbo.o_probe (sn datetime2(0), ms float);
CREATE TABLE dbo.o_disk (sn datetime2(0), kuyruk float, yazma_ms float, mbps float, iops float);
CREATE TABLE dbo.o_faz (ad varchar(40), bas datetime2(3), bit datetime2(3));
CREATE TABLE dbo.o_wait (snap varchar(10), wait_type nvarchar(120), wait_ms bigint, sayi bigint);
CREATE TABLE dbo.o_fazb (adim varchar(60), sure_ms bigint, yazma_adedi bigint, yazilan_mb decimal(12,2), stall_ms bigint, qs_mb int, kirli_sayfa bigint);
GO
