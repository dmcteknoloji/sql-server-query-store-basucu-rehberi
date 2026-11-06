SET NOCOUNT ON;
SELECT @@VERSION AS surum;
GO
PRINT '#### 1. OPPO atlama nedenleri ve fold tipleri';
SELECT m.name AS harita, m.map_key, m.map_value FROM sys.dm_xe_map_values m WHERE m.name IN ('opo_skipped_reason_enum','multiplan_opo_fold_type_enum') ORDER BY m.name, m.map_key;
GO
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'psp_filtresiz') DROP EVENT SESSION psp_filtresiz ON SERVER;
GO
CREATE EVENT SESSION psp_filtresiz ON SERVER
ADD EVENT sqlserver.parameter_sensitive_plan_optimization,
ADD EVENT sqlserver.parameter_sensitive_plan_optimization_skipped_reason
ADD TARGET package0.ring_buffer (SET max_memory = 4096)
WITH (MAX_DISPATCH_LATENCY = 1 SECONDS, EVENT_RETENTION_MODE = NO_EVENT_LOSS);
GO
USE qs_lab_psp;
GO
PRINT '#### 2. 2025, ayni calistirmada XE ve Query Store';
ALTER DATABASE qs_lab_psp SET COMPATIBILITY_LEVEL = 160;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER EVENT SESSION psp_filtresiz ON SERVER STATE = START;
GO
EXEC dbo.PspOzet @m = 7; EXEC dbo.PspOzet @m = 1; EXEC dbo.PspOzet @m = 2; EXEC dbo.PspOzet @m = 7; EXEC dbo.PspOzet @m = 1; EXEC dbo.PspOzet @m = 2;
GO
WAITFOR DELAY '00:00:02';
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @x xml = (SELECT CAST(t.target_data AS xml) FROM sys.dm_xe_session_targets t JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address WHERE s.name = 'psp_filtresiz' AND t.target_name = 'ring_buffer');
SELECT 'XE toplam olay' AS olcum, COUNT(*) AS adet FROM @x.nodes('/RingBufferTarget/event') x(e);
SELECT olay, neden, COUNT(*) AS adet FROM (SELECT e.value('@name', 'varchar(90)') AS olay, ISNULL(e.value('(data[@name="reason"]/text)[1]', 'varchar(60)'), '-') AS neden FROM @x.nodes('/RingBufferTarget/event') x(e)) k GROUP BY olay, neden ORDER BY 1, 2;
EXEC sys.sp_query_store_flush_db;
SELECT 'Query Store' AS olcum, p.plan_type_desc, COUNT(*) AS adet FROM sys.query_store_plan p JOIN sys.query_store_query q ON q.query_id = p.query_id WHERE q.object_id = OBJECT_ID('dbo.PspOzet') OR q.query_id IN (SELECT query_variant_query_id FROM sys.query_store_query_variant) GROUP BY p.plan_type_desc;
GO
USE master;
DROP EVENT SESSION psp_filtresiz ON SERVER;
GO
USE qs_lab_psp;
GO
PRINT '#### 3. OPPO, hint olan (Ara3) ve olmayan (Ara1) prosedur, iki tekrar';
ALTER DATABASE qs_lab_psp SET COMPATIBILITY_LEVEL = 170;
GO
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
EXEC dbo.Ara1 @musteri = 1, @durum = NULL; EXEC dbo.Ara1 @musteri = NULL, @durum = 3; EXEC dbo.Ara1 @musteri = 7, @durum = 2; EXEC dbo.Ara1 @musteri = NULL, @durum = NULL;
EXEC dbo.Ara3 @musteri = 1, @durum = NULL; EXEC dbo.Ara3 @musteri = NULL, @durum = 3; EXEC dbo.Ara3 @musteri = 7, @durum = 2; EXEC dbo.Ara3 @musteri = NULL, @durum = NULL;
EXEC sys.sp_query_store_flush_db;
SELECT OBJECT_NAME(q.object_id) AS prosedur, p.plan_type_desc, COUNT(*) AS plan_adedi FROM sys.query_store_plan p JOIN sys.query_store_query q ON q.query_id = p.query_id WHERE q.object_id IN (OBJECT_ID('dbo.Ara1'), OBJECT_ID('dbo.Ara3')) AND p.plan_type_desc IS NOT NULL GROUP BY OBJECT_NAME(q.object_id), p.plan_type_desc ORDER BY 1, 2;
SELECT OBJECT_NAME(q.object_id) AS prosedur, COUNT(*) AS variant_kaydi FROM sys.query_store_query_variant v JOIN sys.query_store_query q ON q.query_id = v.parent_query_id WHERE q.object_id IN (OBJECT_ID('dbo.Ara1'), OBJECT_ID('dbo.Ara3')) GROUP BY OBJECT_NAME(q.object_id) ORDER BY 1;
GO
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
EXEC dbo.Ara1 @musteri = 1, @durum = NULL; EXEC dbo.Ara1 @musteri = NULL, @durum = 3; EXEC dbo.Ara1 @musteri = 7, @durum = 2; EXEC dbo.Ara1 @musteri = NULL, @durum = NULL;
EXEC dbo.Ara3 @musteri = 1, @durum = NULL; EXEC dbo.Ara3 @musteri = NULL, @durum = 3; EXEC dbo.Ara3 @musteri = 7, @durum = 2; EXEC dbo.Ara3 @musteri = NULL, @durum = NULL;
EXEC sys.sp_query_store_flush_db;
SELECT OBJECT_NAME(q.object_id) AS prosedur, p.plan_type_desc, COUNT(*) AS plan_adedi FROM sys.query_store_plan p JOIN sys.query_store_query q ON q.query_id = p.query_id WHERE q.object_id IN (OBJECT_ID('dbo.Ara1'), OBJECT_ID('dbo.Ara3')) AND p.plan_type_desc IS NOT NULL GROUP BY OBJECT_NAME(q.object_id), p.plan_type_desc ORDER BY 1, 2;
SELECT OBJECT_NAME(q.object_id) AS prosedur, COUNT(*) AS variant_kaydi FROM sys.query_store_query_variant v JOIN sys.query_store_query q ON q.query_id = v.parent_query_id WHERE q.object_id IN (OBJECT_ID('dbo.Ara1'), OBJECT_ID('dbo.Ara3')) GROUP BY OBJECT_NAME(q.object_id) ORDER BY 1;
GO
