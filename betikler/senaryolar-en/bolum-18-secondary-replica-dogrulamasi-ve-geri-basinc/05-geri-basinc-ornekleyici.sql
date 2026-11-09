-- SQL Server Query Store Handbook, Chapter 18, 'Secondary replica verification and backpressure'
-- Run in a test environment only.

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @n int = 0, @rol nvarchar(20), @bek bigint, @mb bigint, @gk bigint, @rk bigint, @fc bigint, @neg int, @g2 int;
WHILE @n < 60
BEGIN
    SELECT @rol = CASE WHEN sys.fn_hadr_is_primary_replica(N'qs_lab_ag') = 1 THEN N'PRIMARY' ELSE N'SECONDARY' END;
    EXEC sys.sp_executesql N'SELECT @a = pending_message_count, @b = messaging_memory_used_mb FROM qs_lab_ag.sys.database_query_store_internal_state',
         N'@a bigint OUTPUT, @b bigint OUTPUT', @a = @bek OUTPUT, @b = @mb OUTPUT;
    SELECT @gk = MAX(log_send_queue_size), @rk = MAX(redo_queue_size)
    FROM sys.dm_hadr_database_replica_states WHERE database_id = DB_ID(N'qs_lab_ag');
    SELECT @fc = SUM(cntr_value) FROM sys.dm_os_performance_counters WHERE object_name LIKE N'%Availability Replica%' AND counter_name LIKE N'Flow Control Time%';
    EXEC sys.sp_executesql N'SELECT @n = COUNT(*) FROM qs_lab_ag.sys.query_store_query WHERE query_id < 0', N'@n int OUTPUT', @n = @neg OUTPUT;
    EXEC sys.sp_executesql N'SELECT @n = COUNT(*) FROM qs_lab_ag.sys.query_store_runtime_stats WHERE replica_group_id = 2', N'@n int OUTPUT', @n = @g2 OUTPUT;
    SELECT CONVERT(varchar(19), SYSUTCDATETIME(), 120) AS zaman_utc, @n * 5 AS sn, @rol AS rol, @bek AS bekleyen, @mb AS bellek_mb, @gk AS gonderim_kb, @rk AS redo_kb, @fc AS flow_ms, @neg AS negatif_query, @g2 AS grup2_satir;
    SET @n += 1; WAITFOR DELAY '00:00:05';
END
