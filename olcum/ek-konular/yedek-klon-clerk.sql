SET NOCOUNT ON;
IF DB_ID('ek_demo') IS NOT NULL BEGIN ALTER DATABASE ek_demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ek_demo; END
IF DB_ID('ek_kopya') IS NOT NULL BEGIN ALTER DATABASE ek_kopya SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ek_kopya; END
IF DB_ID('ek_clone') IS NOT NULL BEGIN ALTER DATABASE ek_clone SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ek_clone; END
GO
SET NOCOUNT ON;
SELECT @@VERSION AS surum;
GO
CREATE DATABASE ek_demo;
GO
ALTER DATABASE ek_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
USE ek_demo;
CREATE TABLE dbo.t (id int IDENTITY PRIMARY KEY, k int, d char(200) DEFAULT 'x');
INSERT dbo.t (k) SELECT TOP (50000) ABS(CHECKSUM(NEWID())) % 1000 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
CREATE INDEX ix_k ON dbo.t(k);
GO
CREATE PROCEDURE dbo.p @k int AS SELECT COUNT(*) AS n FROM dbo.t WHERE k = @k;
GO
EXEC dbo.p 5; EXEC dbo.p 5; EXEC dbo.p 7;
EXEC sp_query_store_flush_db;
GO
-- plan sabitle
DECLARE @q bigint, @p bigint;
SELECT TOP 1 @q = q.query_id, @p = p.plan_id FROM sys.query_store_query q JOIN sys.query_store_plan p ON p.query_id=q.query_id WHERE q.object_id = OBJECT_ID('dbo.p');
EXEC sp_query_store_force_plan @q, @p;
SELECT 'sabit' AS adim, @q AS query_id, @p AS plan_id;
GO
-- index'i sil, tekrar derlet
DROP INDEX ix_k ON dbo.t;
EXEC sp_recompile 'dbo.p';
EXEC dbo.p 5;
EXEC sp_query_store_flush_db;
GO
SELECT plan_id, is_forced_plan, force_failure_count, last_force_failure_reason, last_force_failure_reason_desc, plan_forcing_type_desc FROM sys.query_store_plan WHERE is_forced_plan = 1;
GO
-- Query Store bellek ve bekleme
SELECT type, pages_kb FROM sys.dm_os_memory_clerks WHERE type LIKE '%QUERYDISKSTORE%' OR type LIKE '%QDS%';
GO
SELECT wait_type, waiting_tasks_count FROM sys.dm_os_wait_stats WHERE wait_type LIKE 'QDS%' ORDER BY wait_type;
GO
SELECT name FROM sys.dm_xe_objects WHERE object_type='event' AND name LIKE 'query_store%' ORDER BY name;
GO
SELECT name FROM sys.dm_xe_objects WHERE object_type='event' AND name LIKE 'qds%' ORDER BY name;
GO
DECLARE @yedek nvarchar(400) = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS nvarchar(300)) + N'\ek.bak';
DECLARE @veri nvarchar(400) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS nvarchar(300));
DECLARE @s nvarchar(max) = N'BACKUP DATABASE ek_demo TO DISK = N''' + @yedek + N''' WITH INIT, COPY_ONLY';
EXEC (@s);
SET @s = N'RESTORE DATABASE ek_kopya FROM DISK = N''' + @yedek + N''' WITH MOVE ''ek_demo'' TO N''' + @veri + N'ek_kopya.mdf'', MOVE ''ek_demo_log'' TO N''' + @veri + N'ek_kopya.ldf''';
EXEC (@s);
GO
SELECT d.name, o.desired_state_desc, o.actual_state_desc FROM sys.databases d CROSS APPLY (SELECT desired_state_desc, actual_state_desc FROM ek_kopya.sys.database_query_store_options) o WHERE d.name = 'ek_kopya';
GO
SELECT p.plan_id, p.is_forced_plan, p.last_force_failure_reason_desc FROM ek_kopya.sys.query_store_plan p WHERE p.is_forced_plan = 1;
GO
SELECT COUNT(*) AS kopyada_query_sayisi FROM ek_kopya.sys.query_store_query;
GO
DBCC CLONEDATABASE (ek_demo, ek_clone) WITH NO_STATISTICS;
GO
SELECT desired_state_desc, actual_state_desc FROM ek_clone.sys.database_query_store_options;
GO
SELECT COUNT(*) AS clone_query_sayisi FROM ek_clone.sys.query_store_query;
SELECT is_forced_plan, COUNT(*) AS adet FROM ek_clone.sys.query_store_plan GROUP BY is_forced_plan;
GO
IF DB_ID('ek_demo') IS NOT NULL BEGIN ALTER DATABASE ek_demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ek_demo; END
IF DB_ID('ek_kopya') IS NOT NULL BEGIN ALTER DATABASE ek_kopya SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ek_kopya; END
IF DB_ID('ek_clone') IS NOT NULL BEGIN ALTER DATABASE ek_clone SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE ek_clone; END
GO
