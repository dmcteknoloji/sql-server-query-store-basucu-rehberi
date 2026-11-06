SET NOCOUNT ON;
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'qs_flush_izle') DROP EVENT SESSION qs_flush_izle ON SERVER;
GO
CREATE EVENT SESSION qs_flush_izle ON SERVER
ADD EVENT qds.query_store_background_task_persist_started,
ADD EVENT qds.query_store_background_task_persist_finished,
ADD EVENT qds.query_store_async_queue_diagnostics,
ADD EVENT qds.query_store_db_diagnostics,
ADD EVENT qds.query_store_spinlock_stats,
ADD EVENT qds.query_store_buffered_items_over_memory_limit
ADD TARGET package0.ring_buffer (SET max_memory = 51200)
WITH (MAX_DISPATCH_LATENCY = 1 SECONDS);
GO
ALTER DATABASE qs_lab_flush SET QUERY_STORE (DATA_FLUSH_INTERVAL_SECONDS = 60);
ALTER DATABASE qs_lab_flush SET QUERY_STORE CLEAR;
USE qs_lab_flush;
CHECKPOINT;
GO
ALTER EVENT SESSION qs_flush_izle ON SERVER STATE = START;
GO
