
SET NOCOUNT ON;
SELECT @@VERSION AS surum;
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'psp_izle') DROP EVENT SESSION psp_izle ON SERVER;
GO
IF DB_ID('psp_lab') IS NOT NULL BEGIN ALTER DATABASE psp_lab SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE psp_lab; END
GO
CREATE DATABASE psp_lab;
GO
ALTER DATABASE psp_lab SET COMPATIBILITY_LEVEL = 160;
ALTER DATABASE psp_lab SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
CREATE EVENT SESSION psp_izle ON SERVER
ADD EVENT sqlserver.parameter_sensitive_plan_optimization (ACTION (sqlserver.database_name, sqlserver.sql_text) WHERE sqlserver.database_name = N'psp_lab'),
ADD EVENT sqlserver.parameter_sensitive_plan_optimization_skipped_reason (ACTION (sqlserver.database_name, sqlserver.sql_text) WHERE sqlserver.database_name = N'psp_lab')
ADD TARGET package0.ring_buffer (SET max_memory = 4096)
WITH (MAX_DISPATCH_LATENCY = 1 SECONDS, EVENT_RETENTION_MODE = NO_EVENT_LOSS);
GO
USE psp_lab;
GO
USE psp_lab;
GO
SELECT TOP (520000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn INTO dbo.sayi FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE dbo.xe_oku AS
BEGIN
  DECLARE @x xml = (SELECT CAST(t.target_data AS xml) FROM sys.dm_xe_session_targets t JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address WHERE s.name = 'psp_izle' AND t.target_name = 'ring_buffer');
  SELECT olay, neden, varyant_mi, variant_id, predicate, COUNT(*) AS adet, metin
  FROM (
    SELECT e.value('@name', 'varchar(80)') AS olay,
           ISNULL(e.value('(data[@name="reason"]/text)[1]', 'varchar(60)'), '-') AS neden,
           ISNULL(e.value('(data[@name="is_query_variant"]/value)[1]', 'varchar(10)'), '-') AS varyant_mi,
           ISNULL(CAST(e.value('(data[@name="query_variant_id"]/value)[1]', 'int') AS varchar(10)), '-') AS variant_id,
           ISNULL(CAST(e.value('(data[@name="predicate_count"]/value)[1]', 'int') AS varchar(10)), '-') AS predicate,
           LEFT(REPLACE(REPLACE(e.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(300)'), CHAR(13), ' '), CHAR(10), ' '), 60) AS metin
    FROM @x.nodes('/RingBufferTarget/event') x(e)
  ) k
  GROUP BY olay, neden, varyant_mi, variant_id, predicate, metin
  ORDER BY olay, neden;
END
GO
CREATE PROCEDURE dbo.plan_oku @parca nvarchar(100) AS
BEGIN
  EXEC sys.sp_query_store_flush_db;
  SELECT p.plan_type_desc, COUNT(*) AS plan_adedi
  FROM sys.query_store_plan p JOIN sys.query_store_query q ON q.query_id = p.query_id JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id
  WHERE t.query_sql_text LIKE N'%' + @parca + N'%' AND t.query_sql_text NOT LIKE N'%query_store_plan%' AND p.plan_type_desc IS NOT NULL
  GROUP BY p.plan_type_desc;
  SELECT COUNT(*) AS variant_kaydi FROM sys.query_store_query_variant v JOIN sys.query_store_query q ON q.query_id = v.parent_query_id JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id WHERE t.query_sql_text LIKE N'%' + @parca + N'%' AND t.query_sql_text NOT LIKE N'%query_store_plan%';
END
GO


PRINT '#### H500000_L1';
CREATE TABLE dbo.H500000_L1 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H500000_L1 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500000;
INSERT dbo.H500000_L1 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_H500000_L1 ON dbo.H500000_L1 (musteri_id);
UPDATE STATISTICS dbo.H500000_L1 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H500000_L1 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H500000_L1 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H500000_L1 @m = 2; EXEC dbo.P_H500000_L1 @m = 1; EXEC dbo.P_H500000_L1 @m = 3; EXEC dbo.P_H500000_L1 @m = 2; EXEC dbo.P_H500000_L1 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H500000_L1';
GO

PRINT '#### H500000_L2';
CREATE TABLE dbo.H500000_L2 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H500000_L2 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500000;
INSERT dbo.H500000_L2 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 10;
CREATE INDEX ix_H500000_L2 ON dbo.H500000_L2 (musteri_id);
UPDATE STATISTICS dbo.H500000_L2 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H500000_L2 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H500000_L2 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H500000_L2 @m = 2; EXEC dbo.P_H500000_L2 @m = 1; EXEC dbo.P_H500000_L2 @m = 3; EXEC dbo.P_H500000_L2 @m = 2; EXEC dbo.P_H500000_L2 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H500000_L2';
GO

PRINT '#### H500000_L3';
CREATE TABLE dbo.H500000_L3 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H500000_L3 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500000;
INSERT dbo.H500000_L3 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 15;
CREATE INDEX ix_H500000_L3 ON dbo.H500000_L3 (musteri_id);
UPDATE STATISTICS dbo.H500000_L3 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H500000_L3 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H500000_L3 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H500000_L3 @m = 2; EXEC dbo.P_H500000_L3 @m = 1; EXEC dbo.P_H500000_L3 @m = 3; EXEC dbo.P_H500000_L3 @m = 2; EXEC dbo.P_H500000_L3 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H500000_L3';
GO

PRINT '#### H500000_L5';
CREATE TABLE dbo.H500000_L5 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H500000_L5 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500000;
INSERT dbo.H500000_L5 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 25;
CREATE INDEX ix_H500000_L5 ON dbo.H500000_L5 (musteri_id);
UPDATE STATISTICS dbo.H500000_L5 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H500000_L5 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H500000_L5 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H500000_L5 @m = 2; EXEC dbo.P_H500000_L5 @m = 1; EXEC dbo.P_H500000_L5 @m = 3; EXEC dbo.P_H500000_L5 @m = 2; EXEC dbo.P_H500000_L5 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H500000_L5';
GO

PRINT '#### H500000_L10';
CREATE TABLE dbo.H500000_L10 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H500000_L10 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500000;
INSERT dbo.H500000_L10 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 50;
CREATE INDEX ix_H500000_L10 ON dbo.H500000_L10 (musteri_id);
UPDATE STATISTICS dbo.H500000_L10 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H500000_L10 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H500000_L10 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H500000_L10 @m = 2; EXEC dbo.P_H500000_L10 @m = 1; EXEC dbo.P_H500000_L10 @m = 3; EXEC dbo.P_H500000_L10 @m = 2; EXEC dbo.P_H500000_L10 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H500000_L10';
GO

PRINT '#### H500000_L20';
CREATE TABLE dbo.H500000_L20 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H500000_L20 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500000;
INSERT dbo.H500000_L20 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 100;
CREATE INDEX ix_H500000_L20 ON dbo.H500000_L20 (musteri_id);
UPDATE STATISTICS dbo.H500000_L20 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H500000_L20 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H500000_L20 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H500000_L20 @m = 2; EXEC dbo.P_H500000_L20 @m = 1; EXEC dbo.P_H500000_L20 @m = 3; EXEC dbo.P_H500000_L20 @m = 2; EXEC dbo.P_H500000_L20 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H500000_L20';
GO

PRINT '#### H500000_L100';
CREATE TABLE dbo.H500000_L100 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H500000_L100 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500000;
INSERT dbo.H500000_L100 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500;
CREATE INDEX ix_H500000_L100 ON dbo.H500000_L100 (musteri_id);
UPDATE STATISTICS dbo.H500000_L100 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H500000_L100 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H500000_L100 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H500000_L100 @m = 2; EXEC dbo.P_H500000_L100 @m = 1; EXEC dbo.P_H500000_L100 @m = 3; EXEC dbo.P_H500000_L100 @m = 2; EXEC dbo.P_H500000_L100 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H500000_L100';
GO

PRINT '#### H1000_L1';
CREATE TABLE dbo.H1000_L1 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H1000_L1 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 1000;
INSERT dbo.H1000_L1 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_H1000_L1 ON dbo.H1000_L1 (musteri_id);
UPDATE STATISTICS dbo.H1000_L1 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H1000_L1 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H1000_L1 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H1000_L1 @m = 2; EXEC dbo.P_H1000_L1 @m = 1; EXEC dbo.P_H1000_L1 @m = 3; EXEC dbo.P_H1000_L1 @m = 2; EXEC dbo.P_H1000_L1 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H1000_L1';
GO

PRINT '#### H10000_L1';
CREATE TABLE dbo.H10000_L1 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H10000_L1 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 10000;
INSERT dbo.H10000_L1 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_H10000_L1 ON dbo.H10000_L1 (musteri_id);
UPDATE STATISTICS dbo.H10000_L1 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H10000_L1 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H10000_L1 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H10000_L1 @m = 2; EXEC dbo.P_H10000_L1 @m = 1; EXEC dbo.P_H10000_L1 @m = 3; EXEC dbo.P_H10000_L1 @m = 2; EXEC dbo.P_H10000_L1 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H10000_L1';
GO

PRINT '#### H50000_L1';
CREATE TABLE dbo.H50000_L1 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H50000_L1 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 50000;
INSERT dbo.H50000_L1 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_H50000_L1 ON dbo.H50000_L1 (musteri_id);
UPDATE STATISTICS dbo.H50000_L1 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H50000_L1 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H50000_L1 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H50000_L1 @m = 2; EXEC dbo.P_H50000_L1 @m = 1; EXEC dbo.P_H50000_L1 @m = 3; EXEC dbo.P_H50000_L1 @m = 2; EXEC dbo.P_H50000_L1 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H50000_L1';
GO

PRINT '#### H100000_L1';
CREATE TABLE dbo.H100000_L1 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H100000_L1 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 100000;
INSERT dbo.H100000_L1 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_H100000_L1 ON dbo.H100000_L1 (musteri_id);
UPDATE STATISTICS dbo.H100000_L1 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H100000_L1 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H100000_L1 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H100000_L1 @m = 2; EXEC dbo.P_H100000_L1 @m = 1; EXEC dbo.P_H100000_L1 @m = 3; EXEC dbo.P_H100000_L1 @m = 2; EXEC dbo.P_H100000_L1 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H100000_L1';
GO

PRINT '#### H200000_L1';
CREATE TABLE dbo.H200000_L1 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.H200000_L1 (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 200000;
INSERT dbo.H200000_L1 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_H200000_L1 ON dbo.H200000_L1 (musteri_id);
UPDATE STATISTICS dbo.H200000_L1 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_H200000_L1 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.H200000_L1 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE psp_lab SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_H200000_L1 @m = 2; EXEC dbo.P_H200000_L1 @m = 1; EXEC dbo.P_H200000_L1 @m = 3; EXEC dbo.P_H200000_L1 @m = 2; EXEC dbo.P_H200000_L1 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'H200000_L1';
GO

USE master;
GO
DROP EVENT SESSION psp_izle ON SERVER;
GO
