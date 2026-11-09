-- SQL Server Query Store Handbook, Chapter 18, 'Discovery-based collection of PSP events'
-- Run in a test environment only.

SET NOCOUNT ON;
USE qs_lab_psp;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
GO
EXEC dbo.PspOzet @m = 7; EXEC dbo.PspOzet @m = 1; EXEC dbo.PspOzet @m = 2;
EXEC dbo.PspOzet @m = 7; EXEC dbo.PspOzet @m = 1; EXEC dbo.PspOzet @m = 2;
GO
WAITFOR DELAY '00:00:03';
GO
SET QUOTED_IDENTIFIER ON;
-- Source 1, ring buffer
DECLARE @x xml = (SELECT CAST(t.target_data AS xml)
                  FROM sys.dm_xe_session_targets AS t
                  JOIN sys.dm_xe_sessions AS s ON s.address = t.event_session_address
                  WHERE s.name = N'psp_tum_olaylar' AND t.target_name = N'ring_buffer');
SELECT N'ring_buffer' AS kaynak, k.paket, k.olay, COUNT(*) AS adet
FROM (SELECT e.value('@package', 'varchar(60)') AS paket, e.value('@name', 'varchar(120)') AS olay
      FROM @x.nodes('/RingBufferTarget/event') AS x(e)) AS k
GROUP BY k.paket, k.olay
ORDER BY adet DESC;
-- Source 2, event_file
DECLARE @ef nvarchar(400) = CONVERT(nvarchar(400), SERVERPROPERTY('ErrorLogFileName'));
DECLARE @yol nvarchar(400) = LEFT(@ef, LEN(@ef) - CHARINDEX(N'\', REVERSE(@ef)) + 1);
DECLARE @dosya nvarchar(450) = @yol + N'psp_tum_olaylar*.xel';
SELECT N'event_file' AS kaynak, f.object_name AS olay, COUNT(*) AS adet
FROM sys.fn_xe_file_target_read_file(@dosya, NULL, NULL, NULL) AS f
GROUP BY f.object_name ORDER BY adet DESC;
-- Source 3, Query Store (evidence independent of the event)
EXEC sys.sp_query_store_flush_db;
SELECT p.plan_type_desc, COUNT(*) AS adet
FROM sys.query_store_plan AS p
JOIN sys.query_store_query AS q ON q.query_id = p.query_id
WHERE q.object_id = OBJECT_ID(N'dbo.PspOzet')
   OR q.query_id IN (SELECT query_variant_query_id FROM sys.query_store_query_variant)
GROUP BY p.plan_type_desc;
GO
