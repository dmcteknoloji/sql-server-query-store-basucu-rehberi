SET NOCOUNT ON;
USE qs_lab_flush;
GO
-- Faz B: bellekte biriken Query Store verisinin elle diske yazilmasi ve checkpoint
ALTER DATABASE qs_lab_flush SET QUERY_STORE CLEAR;
CHECKPOINT;
GO
DECLARE @i bigint = 900000000, @n int = 0, @s nvarchar(400);
WHILE @n < 60000 BEGIN
  SET @s = N'DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE k = ' + CAST((@i * 7919 + 13) % 1000 AS nvarchar(12)) + N' AND id > ' + CAST(@i AS nvarchar(12));
  EXEC (@s); SET @i += 1; SET @n += 1;
END
GO
DECLARE @t0 datetime2(3), @y bigint, @b bigint, @st bigint, @mb int, @kirli bigint;
DECLARE @y0 bigint, @b0 bigint, @s0 bigint;
SELECT @y0 = num_of_writes, @b0 = num_of_bytes_written, @s0 = io_stall_write_ms FROM sys.dm_io_virtual_file_stats(DB_ID('qs_lab_flush'), 1);
SELECT @kirli = COUNT(*) FROM sys.dm_os_buffer_descriptors WHERE database_id = DB_ID('qs_lab_flush') AND is_modified = 1;
SELECT @mb = current_storage_size_mb FROM sys.database_query_store_options;
INSERT dbo.o_fazb VALUES ('60.000 farkli query sonrasi, flush oncesi', 0, 0, 0, 0, @mb, @kirli);
SET @t0 = SYSDATETIME();
EXEC sys.sp_query_store_flush_db;
DECLARE @bit datetime2(3) = SYSDATETIME();
SELECT @y = num_of_writes, @b = num_of_bytes_written, @st = io_stall_write_ms FROM sys.dm_io_virtual_file_stats(DB_ID('qs_lab_flush'), 1);
SELECT @mb = current_storage_size_mb FROM sys.database_query_store_options;
SELECT @kirli = COUNT(*) FROM sys.dm_os_buffer_descriptors WHERE database_id = DB_ID('qs_lab_flush') AND is_modified = 1;
INSERT dbo.o_fazb VALUES ('sp_query_store_flush_db', DATEDIFF(MILLISECOND, @t0, @bit), @y - @y0, CAST((@b - @b0) / 1048576.0 AS decimal(12,2)), @st - @s0, @mb, @kirli);
SET @y0 = @y; SET @b0 = @b; SET @s0 = @st;
SET @t0 = SYSDATETIME();
CHECKPOINT;
SET @bit = SYSDATETIME();
SELECT @y = num_of_writes, @b = num_of_bytes_written, @st = io_stall_write_ms FROM sys.dm_io_virtual_file_stats(DB_ID('qs_lab_flush'), 1);
SELECT @kirli = COUNT(*) FROM sys.dm_os_buffer_descriptors WHERE database_id = DB_ID('qs_lab_flush') AND is_modified = 1;
INSERT dbo.o_fazb VALUES ('CHECKPOINT (flush sonrasi)', DATEDIFF(MILLISECOND, @t0, @bit), @y - @y0, CAST((@b - @b0) / 1048576.0 AS decimal(12,2)), @st - @s0, @mb, @kirli);
GO
SELECT adim, sure_ms, yazma_adedi, yazilan_mb, stall_ms, qs_mb, kirli_sayfa FROM dbo.o_fazb ORDER BY (SELECT NULL);
GO
