-- SQL Server Query Store Handbook, Chapter 18, 'Discovery-based collection of PSP events'
-- Run in a test environment only.

SET NOCOUNT ON;
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'psp_tum_olaylar')
    DROP EVENT SESSION psp_tum_olaylar ON SERVER;
GO
DECLARE @ef nvarchar(400) = CONVERT(nvarchar(400), SERVERPROPERTY('ErrorLogFileName'));
DECLARE @yol nvarchar(400) = LEFT(@ef, LEN(@ef) - CHARINDEX(N'\', REVERSE(@ef)) + 1);
DECLARE @olaylar nvarchar(max) = N'';
SELECT @olaylar += CASE WHEN @olaylar = N'' THEN N'' ELSE N',' + NCHAR(10) END
     + N'ADD EVENT ' + QUOTENAME(p.name) + N'.' + QUOTENAME(o.name)
     + N' (ACTION (sqlserver.session_id, sqlserver.sql_text))'
FROM sys.dm_xe_objects AS o
JOIN sys.dm_xe_packages AS p ON p.guid = o.package_guid
WHERE o.object_type = N'event'
  AND (o.name LIKE N'%parameter_sensitive%' OR o.name LIKE N'%query_variant%'
    OR o.name LIKE N'%multiplan%' OR o.name LIKE N'%dispatcher%'
    OR o.name LIKE N'%optional_parameter%' OR o.name LIKE N'%psp%');
IF @olaylar = N'' THROW 50001, N'Aranan adlarla hic olay bulunamadi.', 1;
DECLARE @sql nvarchar(max) =
    N'CREATE EVENT SESSION psp_tum_olaylar ON SERVER ' + NCHAR(10) + @olaylar + NCHAR(10)
  + N'ADD TARGET package0.ring_buffer (SET max_memory = 4096),' + NCHAR(10)
  + N'ADD TARGET package0.event_file (SET filename = N''' + @yol + N'psp_tum_olaylar.xel'', max_file_size = 50)' + NCHAR(10)
  + N'WITH (MAX_DISPATCH_LATENCY = 1 SECONDS, EVENT_RETENTION_MODE = NO_EVENT_LOSS, TRACK_CAUSALITY = ON);';
EXEC (@sql);
ALTER EVENT SESSION psp_tum_olaylar ON SERVER STATE = START;
GO
