-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Native procedure ve istatistik toplama'
-- Yalnizca test ortaminda calistirin.

DECLARE @yol nvarchar(260) = CONVERT(nvarchar(260), SERVERPROPERTY('InstanceDefaultDataPath'));
IF DB_ID(N'qs_lab_xtp') IS NOT NULL BEGIN ALTER DATABASE qs_lab_xtp SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_lab_xtp; END
EXEC (N'CREATE DATABASE qs_lab_xtp ON PRIMARY (NAME = qs_lab_xtp_d, FILENAME = N''' + @yol + N'qs_lab_xtp.mdf''),
        FILEGROUP fg_xtp CONTAINS MEMORY_OPTIMIZED_DATA (NAME = qs_lab_xtp_x, FILENAME = N''' + @yol + N'qs_lab_xtp_x'')
        LOG ON (NAME = qs_lab_xtp_l, FILENAME = N''' + @yol + N'qs_lab_xtp.ldf'')');
ALTER DATABASE qs_lab_xtp SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
USE qs_lab_xtp;
GO
CREATE TABLE dbo.XtpSiparis (id int NOT NULL PRIMARY KEY NONCLUSTERED, musteri_id int NOT NULL INDEX ix_m NONCLUSTERED, tutar decimal(10,2) NOT NULL)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY);
GO
INSERT dbo.XtpSiparis (id, musteri_id, tutar)
SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 100, 10
FROM sys.all_objects a CROSS JOIN sys.all_objects b;
GO
CREATE PROCEDURE dbo.XtpOzet @m int WITH NATIVE_COMPILATION, SCHEMABINDING AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')
    SELECT COUNT(*) AS adet FROM dbo.XtpSiparis WHERE musteri_id = @m;
END;
GO
-- Olcum yardimcisi, 200.000 cagri ve sure
CREATE PROCEDURE dbo.XtpKos @ad varchar(40) AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @t0 datetime2 = SYSDATETIME(), @i int = 0;
    WHILE @i < 200000 BEGIN EXEC dbo.XtpOzet @m = 7; SET @i += 1; END
    SELECT @ad AS kosul, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) AS gecen_ms;
END;
GO
DECLARE @db int = DB_ID(), @obj int = OBJECT_ID(N'dbo.XtpOzet'), @c bit;
-- Kosul 1, varsayilan (istatistik kapali)
EXEC dbo.XtpKos @ad = 'kosul1_varsayilan';
EXEC sys.sp_query_store_flush_db;
SELECT 'kosul1' AS kosul, COUNT(*) AS qs_runtime_satiri FROM sys.query_store_runtime_stats rs
JOIN sys.query_store_plan p ON p.plan_id = rs.plan_id WHERE p.is_natively_compiled = 1;
-- Kosul 2, yalniz bu procedure icin sorgu istatistigi acik
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 1, @database_id = @db, @xtp_object_id = @obj;
EXEC sys.sp_xtp_control_query_exec_stats @database_id = @db, @xtp_object_id = @obj, @old_collection_value = @c OUTPUT;
SELECT @c AS toplama_acik_mi;
EXEC dbo.XtpKos @ad = 'kosul2_sorgu_istatistigi_acik';
EXEC sys.sp_query_store_flush_db;
SELECT 'kosul2' AS kosul, COUNT(*) AS qs_runtime_satiri, SUM(rs.count_executions) AS calisma,
       MAX(rs.avg_query_max_used_memory) AS bellek_sayfasi
FROM sys.query_store_runtime_stats rs JOIN sys.query_store_plan p ON p.plan_id = rs.plan_id WHERE p.is_natively_compiled = 1;
-- Kapat
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 0, @database_id = @db, @xtp_object_id = @obj;
EXEC dbo.XtpKos @ad = 'kosul3_tekrar_kapali';
GO
