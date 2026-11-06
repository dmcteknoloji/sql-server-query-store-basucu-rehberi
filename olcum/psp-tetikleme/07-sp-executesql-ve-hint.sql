SET NOCOUNT ON;
SELECT @@VERSION AS surum;
GO
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'psp_izle') DROP EVENT SESSION psp_izle ON SERVER;
GO
CREATE EVENT SESSION psp_izle ON SERVER
ADD EVENT sqlserver.parameter_sensitive_plan_optimization (ACTION (sqlserver.database_name, sqlserver.sql_text) WHERE sqlserver.database_name = N'qs_lab_psp'),
ADD EVENT sqlserver.parameter_sensitive_plan_optimization_skipped_reason (ACTION (sqlserver.database_name, sqlserver.sql_text) WHERE sqlserver.database_name = N'qs_lab_psp')
ADD TARGET package0.ring_buffer (SET max_memory = 4096)
WITH (MAX_DISPATCH_LATENCY = 1 SECONDS, EVENT_RETENTION_MODE = NO_EVENT_LOSS);
GO
USE qs_lab_psp;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE dbo.xe_ozet AS
BEGIN
  DECLARE @x xml = (SELECT CAST(t.target_data AS xml) FROM sys.dm_xe_session_targets t JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address WHERE s.name = 'psp_izle' AND t.target_name = 'ring_buffer');
  SELECT olay, atlama_nedeni, variant_id, COUNT(*) AS adet FROM (
    SELECT e.value('@name', 'varchar(80)') AS olay, ISNULL(e.value('(data[@name="reason"]/text)[1]', 'varchar(60)'), '-') AS atlama_nedeni,
           ISNULL(CAST(e.value('(data[@name="query_variant_id"]/value)[1]', 'int') AS varchar(10)), '-') AS variant_id,
           e.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(400)') AS m
    FROM @x.nodes('/RingBufferTarget/event') x(e)) k
  WHERE m LIKE N'%PspSiparis%' AND m NOT LIKE N'%ring_buffer%' AND m NOT LIKE N'%xe_ozet%'
  GROUP BY olay, atlama_nedeni, variant_id ORDER BY olay, variant_id;
END
GO
CREATE PROCEDURE dbo.kos AS
BEGIN
  ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
  BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
  ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
  DECLARE @i int = 0, @m int;
  WHILE @i < 6 BEGIN
    SET @m = CHOOSE(@i + 1, 7, 1, 2, 7, 1, 2);
    EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m', N'@m int', @m = @m;
    SET @i += 1;
  END
  WAITFOR DELAY '00:00:02';
END
GO
PRINT '#### A. sp_executesql, parametreli (PSP acik, kural disi bir sey yok)';
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
EXEC dbo.kos;
EXEC dbo.xe_ozet;
EXEC sys.sp_query_store_flush_db;
SELECT p.plan_type_desc, COUNT(*) AS plan_adedi FROM sys.query_store_plan p JOIN sys.query_store_query q ON q.query_id = p.query_id JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id WHERE t.query_sql_text LIKE N'%PspSiparis%' AND t.query_sql_text NOT LIKE N'%query_store%' AND p.plan_type_desc IS NOT NULL GROUP BY p.plan_type_desc;
GO
DECLARE @query_id int = (SELECT TOP (1) v.parent_query_id FROM sys.query_store_query_variant v);
SELECT @query_id AS ana_query_id;
-- ana query (dispatcher) uzerine Query Store hint dene
PRINT '#### B1. hint adi belgede gecen ad: DISABLE_PARAMETER_SENSITIVE_PLAN_OPTIMIZATION';
EXEC sys.sp_query_store_set_hints @query_id = @query_id, @query_hints = N'OPTION (USE HINT (''DISABLE_PARAMETER_SENSITIVE_PLAN_OPTIMIZATION''))';
SELECT query_id, query_hint_text, last_query_hint_failure_reason, last_query_hint_failure_reason_desc, query_hint_failure_count, source_desc FROM sys.query_store_query_hints WHERE query_id = @query_id;
EXEC dbo.kos;
EXEC dbo.xe_ozet;
EXEC sys.sp_query_store_clear_hints @query_id = @query_id;
PRINT '#### B2. hint DISABLE_PARAMETER_SNIFFING';
EXEC sys.sp_query_store_set_hints @query_id = @query_id, @query_hints = N'OPTION (USE HINT (''DISABLE_PARAMETER_SNIFFING''))';
SELECT query_id, query_hint_text, last_query_hint_failure_reason_desc, query_hint_failure_count FROM sys.query_store_query_hints WHERE query_id = @query_id;
GO
EXEC dbo.kos;
EXEC dbo.xe_ozet;
GO
DECLARE @query_id int = (SELECT TOP (1) q.query_id FROM sys.query_store_query q JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id WHERE t.query_sql_text LIKE N'%PspSiparis WHERE musteri_id = @m%' AND t.query_sql_text NOT LIKE N'%query_store%' ORDER BY q.query_id);
EXEC sys.sp_query_store_clear_hints @query_id = @query_id;
SELECT COUNT(*) AS kalan_hint FROM sys.query_store_query_hints;
GO
PRINT '#### C. hint olmadan tekrar (kontrol)';
EXEC dbo.kos;
EXEC dbo.xe_ozet;
GO
USE master;
GO
DROP EVENT SESSION psp_izle ON SERVER;
GO
