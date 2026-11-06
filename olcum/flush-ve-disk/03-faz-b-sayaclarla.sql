SET NOCOUNT ON;
USE qs_lab_flush;
GO
DROP TABLE IF EXISTS dbo.o_sayac;
CREATE TABLE dbo.o_sayac (adim varchar(40), sayac varchar(60), deger bigint, zaman datetime2(3));
GO
ALTER DATABASE qs_lab_flush SET QUERY_STORE (DATA_FLUSH_INTERVAL_SECONDS = 900);
ALTER DATABASE qs_lab_flush SET QUERY_STORE CLEAR;
CHECKPOINT;
GO
INSERT dbo.o_sayac SELECT 'a_baslangic', RTRIM(counter_name), cntr_value, SYSDATETIME() FROM sys.dm_os_performance_counters WHERE object_name LIKE '%Query Store%' AND RTRIM(instance_name) = 'qs_lab_flush';
INSERT dbo.o_sayac SELECT 'a_baslangic', 'io_yazma_bayt', num_of_bytes_written, SYSDATETIME() FROM sys.dm_io_virtual_file_stats(DB_ID('qs_lab_flush'), 1);
GO
DECLARE @i bigint = 700000000, @n int = 0, @s nvarchar(400);
WHILE @n < 60000 BEGIN
  SET @s = N'DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE k = ' + CAST((@i * 7919 + 13) % 1000 AS nvarchar(12)) + N' AND id > ' + CAST(@i AS nvarchar(12));
  EXEC (@s); SET @i += 1; SET @n += 1;
END
GO
INSERT dbo.o_sayac SELECT 'b_doldurma_sonrasi', RTRIM(counter_name), cntr_value, SYSDATETIME() FROM sys.dm_os_performance_counters WHERE object_name LIKE '%Query Store%' AND RTRIM(instance_name) = 'qs_lab_flush';
INSERT dbo.o_sayac SELECT 'b_doldurma_sonrasi', 'io_yazma_bayt', num_of_bytes_written, SYSDATETIME() FROM sys.dm_io_virtual_file_stats(DB_ID('qs_lab_flush'), 1);
INSERT dbo.o_sayac SELECT 'b_doldurma_sonrasi', 'qs_mb', current_storage_size_mb, SYSDATETIME() FROM sys.database_query_store_options;
GO
EXEC sys.sp_query_store_flush_db;
GO
INSERT dbo.o_sayac SELECT 'c_flush_sonrasi', RTRIM(counter_name), cntr_value, SYSDATETIME() FROM sys.dm_os_performance_counters WHERE object_name LIKE '%Query Store%' AND RTRIM(instance_name) = 'qs_lab_flush';
INSERT dbo.o_sayac SELECT 'c_flush_sonrasi', 'io_yazma_bayt', num_of_bytes_written, SYSDATETIME() FROM sys.dm_io_virtual_file_stats(DB_ID('qs_lab_flush'), 1);
INSERT dbo.o_sayac SELECT 'c_flush_sonrasi', 'qs_mb', current_storage_size_mb, SYSDATETIME() FROM sys.database_query_store_options;
GO
SELECT 'a_baslangic' AS adim, MIN(zaman) AS t FROM dbo.o_sayac WHERE adim = 'a_baslangic' UNION ALL SELECT adim, MIN(zaman) FROM dbo.o_sayac WHERE adim <> 'a_baslangic' GROUP BY adim ORDER BY 2;
SELECT x.sayac,
  MAX(CASE WHEN adim = 'b_doldurma_sonrasi' THEN deger END) - MAX(CASE WHEN adim = 'a_baslangic' THEN deger END) AS doldurma_farki,
  MAX(CASE WHEN adim = 'c_flush_sonrasi' THEN deger END) - MAX(CASE WHEN adim = 'b_doldurma_sonrasi' THEN deger END) AS flush_farki,
  MAX(CASE WHEN adim = 'c_flush_sonrasi' THEN deger END) AS son_deger
FROM dbo.o_sayac x GROUP BY x.sayac ORDER BY x.sayac;
GO
