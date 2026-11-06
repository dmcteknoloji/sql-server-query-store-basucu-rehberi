
SET NOCOUNT ON;
SELECT @@VERSION AS surum;
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'psp_izle') DROP EVENT SESSION psp_izle ON SERVER;
GO
IF DB_ID('qs_lab_psp') IS NOT NULL BEGIN ALTER DATABASE qs_lab_psp SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_lab_psp; END
GO
CREATE DATABASE qs_lab_psp;
GO
ALTER DATABASE qs_lab_psp SET COMPATIBILITY_LEVEL = 160;
ALTER DATABASE qs_lab_psp SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
CREATE EVENT SESSION psp_izle ON SERVER
ADD EVENT sqlserver.parameter_sensitive_plan_optimization (ACTION (sqlserver.database_name, sqlserver.sql_text) WHERE sqlserver.database_name = N'qs_lab_psp'),
ADD EVENT sqlserver.parameter_sensitive_plan_optimization_skipped_reason (ACTION (sqlserver.database_name, sqlserver.sql_text) WHERE sqlserver.database_name = N'qs_lab_psp')
ADD TARGET package0.ring_buffer (SET max_memory = 4096)
WITH (MAX_DISPATCH_LATENCY = 1 SECONDS, EVENT_RETENTION_MODE = NO_EVENT_LOSS);
GO
USE qs_lab_psp;
GO
USE qs_lab_psp;
GO
SELECT TOP (1100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn INTO dbo.sayi FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c;
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


PRINT '#### SINIR_99999_1';
CREATE TABLE dbo.SINIR_99999_1 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.SINIR_99999_1 (musteri_id, tutar, durum) SELECT 1 + (rn % 1), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 99999;
INSERT dbo.SINIR_99999_1 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_SINIR_99999_1 ON dbo.SINIR_99999_1 (musteri_id);
UPDATE STATISTICS dbo.SINIR_99999_1 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_SINIR_99999_1 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.SINIR_99999_1 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_SINIR_99999_1 @m = 2; EXEC dbo.P_SINIR_99999_1 @m = 1; EXEC dbo.P_SINIR_99999_1 @m = 3; EXEC dbo.P_SINIR_99999_1 @m = 2; EXEC dbo.P_SINIR_99999_1 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'SINIR_99999_1';
GO

PRINT '#### SINIR_100000_1';
CREATE TABLE dbo.SINIR_100000_1 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.SINIR_100000_1 (musteri_id, tutar, durum) SELECT 1 + (rn % 1), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 100000;
INSERT dbo.SINIR_100000_1 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_SINIR_100000_1 ON dbo.SINIR_100000_1 (musteri_id);
UPDATE STATISTICS dbo.SINIR_100000_1 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_SINIR_100000_1 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.SINIR_100000_1 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_SINIR_100000_1 @m = 2; EXEC dbo.P_SINIR_100000_1 @m = 1; EXEC dbo.P_SINIR_100000_1 @m = 3; EXEC dbo.P_SINIR_100000_1 @m = 2; EXEC dbo.P_SINIR_100000_1 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'SINIR_100000_1';
GO

PRINT '#### MUTLAK_1000000_10';
CREATE TABLE dbo.MUTLAK_1000000_10 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.MUTLAK_1000000_10 (musteri_id, tutar, durum) SELECT 1 + (rn % 1), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 1000000;
INSERT dbo.MUTLAK_1000000_10 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 50;
CREATE INDEX ix_MUTLAK_1000000_10 ON dbo.MUTLAK_1000000_10 (musteri_id);
UPDATE STATISTICS dbo.MUTLAK_1000000_10 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_MUTLAK_1000000_10 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.MUTLAK_1000000_10 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_MUTLAK_1000000_10 @m = 2; EXEC dbo.P_MUTLAK_1000000_10 @m = 1; EXEC dbo.P_MUTLAK_1000000_10 @m = 3; EXEC dbo.P_MUTLAK_1000000_10 @m = 2; EXEC dbo.P_MUTLAK_1000000_10 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'MUTLAK_1000000_10';
GO

PRINT '#### MUTLAK_999990_10';
CREATE TABLE dbo.MUTLAK_999990_10 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.MUTLAK_999990_10 (musteri_id, tutar, durum) SELECT 1 + (rn % 1), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 999990;
INSERT dbo.MUTLAK_999990_10 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 50;
CREATE INDEX ix_MUTLAK_999990_10 ON dbo.MUTLAK_999990_10 (musteri_id);
UPDATE STATISTICS dbo.MUTLAK_999990_10 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_MUTLAK_999990_10 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.MUTLAK_999990_10 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_MUTLAK_999990_10 @m = 2; EXEC dbo.P_MUTLAK_999990_10 @m = 1; EXEC dbo.P_MUTLAK_999990_10 @m = 3; EXEC dbo.P_MUTLAK_999990_10 @m = 2; EXEC dbo.P_MUTLAK_999990_10 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'MUTLAK_999990_10';
GO

PRINT '#### MUTLAK_1000000_11';
CREATE TABLE dbo.MUTLAK_1000000_11 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.MUTLAK_1000000_11 (musteri_id, tutar, durum) SELECT 1 + (rn % 1), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 1000000;
INSERT dbo.MUTLAK_1000000_11 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 55;
CREATE INDEX ix_MUTLAK_1000000_11 ON dbo.MUTLAK_1000000_11 (musteri_id);
UPDATE STATISTICS dbo.MUTLAK_1000000_11 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_MUTLAK_1000000_11 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.MUTLAK_1000000_11 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_MUTLAK_1000000_11 @m = 2; EXEC dbo.P_MUTLAK_1000000_11 @m = 1; EXEC dbo.P_MUTLAK_1000000_11 @m = 3; EXEC dbo.P_MUTLAK_1000000_11 @m = 2; EXEC dbo.P_MUTLAK_1000000_11 @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'MUTLAK_1000000_11';
GO

PRINT '#### UC_KATMAN';
CREATE TABLE dbo.UC_KATMAN (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.UC_KATMAN (musteri_id, tutar, durum) SELECT 1 + (rn % 1), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500000;
INSERT dbo.UC_KATMAN (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 25000;
INSERT dbo.UC_KATMAN (musteri_id, tutar, durum) SELECT 7 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_UC_KATMAN ON dbo.UC_KATMAN (musteri_id);
UPDATE STATISTICS dbo.UC_KATMAN WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_UC_KATMAN @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.UC_KATMAN WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.P_UC_KATMAN @m = 7; EXEC dbo.P_UC_KATMAN @m = 1; EXEC dbo.P_UC_KATMAN @m = 3; EXEC dbo.P_UC_KATMAN @m = 7; EXEC dbo.P_UC_KATMAN @m = 1;
GO
WAITFOR DELAY '00:00:01';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'UC_KATMAN';
GO


USE master;
GO
DROP EVENT SESSION psp_izle ON SERVER;
GO
