SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
DECLARE @x xml = (SELECT CAST(t.target_data AS xml) FROM sys.dm_xe_session_targets t JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address WHERE s.name = 'qs_flush_izle' AND t.target_name = 'ring_buffer');
SELECT olay, COUNT(*) AS adet FROM (SELECT e.value('@name', 'varchar(90)') AS olay FROM @x.nodes('/RingBufferTarget/event') x(e)) k GROUP BY olay ORDER BY olay;
SELECT e.value('@name', 'varchar(90)') AS olay, e.value('@timestamp', 'varchar(30)') AS ts, REPLACE(REPLACE(CAST(e.query('for $d in data return concat(string($d/@name), "=", string(($d/value)[1]), " ")') AS nvarchar(1200)), CHAR(13), ' '), CHAR(10), ' ') AS alanlar
FROM @x.nodes('/RingBufferTarget/event') x(e) WHERE e.value('@name', 'varchar(90)') IN ('query_store_background_task_persist_started', 'query_store_background_task_persist_finished', 'query_store_buffered_items_over_memory_limit') ORDER BY e.value('@timestamp', 'varchar(30)');
SELECT TOP (4) e.value('@name', 'varchar(90)') AS olay, e.value('@timestamp', 'varchar(30)') AS ts, REPLACE(REPLACE(CAST(e.query('for $d in data return concat(string($d/@name), "=", string(($d/value)[1]), " ")') AS nvarchar(1500)), CHAR(13), ' '), CHAR(10), ' ') AS alanlar
FROM @x.nodes('/RingBufferTarget/event') x(e) WHERE e.value('@name', 'varchar(90)') IN ('query_store_async_queue_diagnostics') ORDER BY e.value('@timestamp', 'varchar(30)') DESC;
SELECT TOP (3) e.value('@name', 'varchar(90)') AS olay, e.value('@timestamp', 'varchar(30)') AS ts, REPLACE(REPLACE(CAST(e.query('for $d in data return concat(string($d/@name), "=", string(($d/value)[1]), " ")') AS nvarchar(1800)), CHAR(13), ' '), CHAR(10), ' ') AS alanlar
FROM @x.nodes('/RingBufferTarget/event') x(e) WHERE e.value('@name', 'varchar(90)') IN ('query_store_db_diagnostics', 'query_store_spinlock_stats') ORDER BY e.value('@timestamp', 'varchar(30)') DESC;
GO
DROP EVENT SESSION qs_flush_izle ON SERVER;
GO
