SET NOCOUNT ON;
DECLARE @son datetime2(0) = DATEADD(SECOND, $(SURE), SYSDATETIME());
WHILE SYSDATETIME() < @son BEGIN
  INSERT dbo.o_io
  SELECT SYSDATETIME(), f.num_of_writes, f.num_of_bytes_written, f.io_stall_write_ms,
     (SELECT current_storage_size_mb FROM sys.database_query_store_options),
     (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type LIKE 'PAGEIOLATCH%'),
     (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type = 'WRITELOG'),
     (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type LIKE 'QDS%' AND wait_type <> 'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP'),
     (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type = 'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP'),
     (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type IN ('IO_COMPLETION', 'ASYNC_IO_COMPLETION')),
     (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type LIKE 'CHKPT%'),
     (SELECT COUNT(*) FROM sys.dm_io_pending_io_requests)
  FROM sys.dm_io_virtual_file_stats(DB_ID('qs_lab_flush'), 1) f;
  WAITFOR DELAY '00:00:01';
END
