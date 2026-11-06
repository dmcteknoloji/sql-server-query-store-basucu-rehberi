SET NOCOUNT ON;
PRINT '@@SURUM';
SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar(30)) AS build, CAST(SERVERPROPERTY('ProductUpdateLevel') AS varchar(20)) AS cu;
GO
PRINT '@@NESNE';
SELECT name FROM sys.all_objects WHERE name LIKE '%query_store%' OR name LIKE '%query[_]variant%' OR name LIKE 'sp_query_store%' OR name LIKE '%tuning_recommendations%' ORDER BY name;
GO
PRINT '@@KOLON';
SELECT o.name + '.' + c.name AS kolon FROM sys.all_objects o JOIN sys.all_columns c ON c.object_id = o.object_id WHERE o.name LIKE 'query_store%' OR o.name LIKE 'database_query_store%' ORDER BY 1;
GO
PRINT '@@XE';
SELECT name FROM sys.dm_xe_objects WHERE object_type = 'event' AND (name LIKE 'query_store%' OR name LIKE 'qds%') ORDER BY name;
GO
PRINT '@@XEKOLON';
SELECT o.name + '.' + c.name AS kolon FROM sys.dm_xe_objects o JOIN sys.dm_xe_object_columns c ON c.object_name = o.name WHERE o.object_type='event' AND o.name LIKE 'query_store%' AND c.column_type = 'data' ORDER BY 1;
GO
PRINT '@@BEKLEME';
SELECT wait_type FROM sys.dm_os_wait_stats WHERE wait_type LIKE 'QDS%' ORDER BY wait_type;
GO
PRINT '@@CLERK';
SELECT DISTINCT type FROM sys.dm_os_memory_clerks WHERE type LIKE '%QUERYDISKSTORE%' OR type LIKE '%QDS%' ORDER BY type;
GO
PRINT '@@SCOPED';
SELECT name FROM sys.database_scoped_configurations ORDER BY name;
GO
PRINT '@@VARSAYILAN';
CREATE DATABASE cu_demo;
GO
SELECT * FROM cu_demo.sys.database_query_store_options;
GO
USE cu_demo;
PRINT '@@DAVRANIS';
CREATE TABLE dbo.t (id int IDENTITY PRIMARY KEY, k int, d char(200) DEFAULT 'x');
INSERT dbo.t (k) SELECT TOP (50000) ABS(CHECKSUM(NEWID())) % 1000 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
CREATE INDEX ix_k ON dbo.t(k);
GO
CREATE PROCEDURE dbo.p @k int AS SELECT COUNT(*) AS n FROM dbo.t WHERE k = @k;
GO
EXEC dbo.p 5; EXEC dbo.p 5;
EXEC sp_query_store_flush_db;
GO
DECLARE @q bigint, @p bigint;
SELECT TOP 1 @q = q.query_id, @p = p.plan_id FROM sys.query_store_query q JOIN sys.query_store_plan p ON p.query_id=q.query_id WHERE q.object_id = OBJECT_ID('dbo.p');
EXEC sp_query_store_force_plan @q, @p;
EXEC sp_query_store_set_hints @q, N'OPTION (MAXDOP 1)';
SELECT 'sabit+hint tamam' AS sonuc;
GO
DROP INDEX ix_k ON dbo.t;
EXEC sp_recompile 'dbo.p';
EXEC dbo.p 5;
EXEC sp_query_store_flush_db;
GO
SELECT last_force_failure_reason_desc AS neden, force_failure_count AS adet FROM sys.query_store_plan WHERE is_forced_plan = 1;
SELECT query_hint_text FROM sys.query_store_query_hints;
GO
PRINT '@@CAPTURE';
ALTER DATABASE cu_demo SET QUERY_STORE (QUERY_CAPTURE_MODE = CUSTOM, QUERY_CAPTURE_POLICY = (STALE_CAPTURE_POLICY_THRESHOLD = 24 HOURS, EXECUTION_COUNT = 30, TOTAL_COMPILE_CPU_TIME_MS = 1000, TOTAL_EXECUTION_CPU_TIME_MS = 100));
SELECT query_capture_mode_desc, capture_policy_execution_count, capture_policy_total_compile_cpu_time_ms FROM sys.database_query_store_options;
GO
