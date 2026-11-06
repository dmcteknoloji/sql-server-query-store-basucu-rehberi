
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


PRINT '#### B_100000_1';
CREATE TABLE dbo.B_100000_1 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.B_100000_1 (musteri_id, tutar, durum) SELECT 1 + (rn % 1), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 100000;
INSERT dbo.B_100000_1 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_B_100000_1 ON dbo.B_100000_1 (musteri_id);
UPDATE STATISTICS dbo.B_100000_1 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_B_100000_1 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.B_100000_1 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
GO
EXEC dbo.P_B_100000_1 @m = 7; EXEC dbo.P_B_100000_1 @m = 1; EXEC dbo.P_B_100000_1 @m = 2; EXEC dbo.P_B_100000_1 @m = 7; EXEC dbo.P_B_100000_1 @m = 1; EXEC dbo.P_B_100000_1 @m = 2;
GO
EXEC sys.sp_query_store_flush_db;
SELECT 'B_100000_1' AS tablo, v.query_variant_query_id AS qid, SUBSTRING(t.query_sql_text, CHARINDEX('QueryVariantID', t.query_sql_text), 14) AS variant, RIGHT(REPLACE(t.query_sql_text, CHAR(10), ' '), 18) AS sinirlar,
  (SELECT TOP (1) CAST(rs.avg_duration AS decimal(18,0)) FROM sys.query_store_plan p JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id WHERE p.query_id = v.query_variant_query_id ORDER BY rs.runtime_stats_id DESC) AS ort_mikrosn
FROM sys.query_store_query_variant v JOIN sys.query_store_query q ON q.query_id = v.query_variant_query_id JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id ORDER BY v.query_variant_query_id;
GO

PRINT '#### B_500000_1';
CREATE TABLE dbo.B_500000_1 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.B_500000_1 (musteri_id, tutar, durum) SELECT 1 + (rn % 1), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500000;
INSERT dbo.B_500000_1 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_B_500000_1 ON dbo.B_500000_1 (musteri_id);
UPDATE STATISTICS dbo.B_500000_1 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_B_500000_1 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.B_500000_1 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
GO
EXEC dbo.P_B_500000_1 @m = 7; EXEC dbo.P_B_500000_1 @m = 1; EXEC dbo.P_B_500000_1 @m = 2; EXEC dbo.P_B_500000_1 @m = 7; EXEC dbo.P_B_500000_1 @m = 1; EXEC dbo.P_B_500000_1 @m = 2;
GO
EXEC sys.sp_query_store_flush_db;
SELECT 'B_500000_1' AS tablo, v.query_variant_query_id AS qid, SUBSTRING(t.query_sql_text, CHARINDEX('QueryVariantID', t.query_sql_text), 14) AS variant, RIGHT(REPLACE(t.query_sql_text, CHAR(10), ' '), 18) AS sinirlar,
  (SELECT TOP (1) CAST(rs.avg_duration AS decimal(18,0)) FROM sys.query_store_plan p JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id WHERE p.query_id = v.query_variant_query_id ORDER BY rs.runtime_stats_id DESC) AS ort_mikrosn
FROM sys.query_store_query_variant v JOIN sys.query_store_query q ON q.query_id = v.query_variant_query_id JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id ORDER BY v.query_variant_query_id;
GO

PRINT '#### B_1000000_10';
CREATE TABLE dbo.B_1000000_10 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.B_1000000_10 (musteri_id, tutar, durum) SELECT 1 + (rn % 1), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 1000000;
INSERT dbo.B_1000000_10 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 50;
CREATE INDEX ix_B_1000000_10 ON dbo.B_1000000_10 (musteri_id);
UPDATE STATISTICS dbo.B_1000000_10 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_B_1000000_10 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.B_1000000_10 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
GO
EXEC dbo.P_B_1000000_10 @m = 7; EXEC dbo.P_B_1000000_10 @m = 1; EXEC dbo.P_B_1000000_10 @m = 2; EXEC dbo.P_B_1000000_10 @m = 7; EXEC dbo.P_B_1000000_10 @m = 1; EXEC dbo.P_B_1000000_10 @m = 2;
GO
EXEC sys.sp_query_store_flush_db;
SELECT 'B_1000000_10' AS tablo, v.query_variant_query_id AS qid, SUBSTRING(t.query_sql_text, CHARINDEX('QueryVariantID', t.query_sql_text), 14) AS variant, RIGHT(REPLACE(t.query_sql_text, CHAR(10), ' '), 18) AS sinirlar,
  (SELECT TOP (1) CAST(rs.avg_duration AS decimal(18,0)) FROM sys.query_store_plan p JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id WHERE p.query_id = v.query_variant_query_id ORDER BY rs.runtime_stats_id DESC) AS ort_mikrosn
FROM sys.query_store_query_variant v JOIN sys.query_store_query q ON q.query_id = v.query_variant_query_id JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id ORDER BY v.query_variant_query_id;
GO

PRINT '#### B_UC_katman_1M';
CREATE TABLE dbo.B_UC_katman_1M (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.B_UC_katman_1M (musteri_id, tutar, durum) SELECT 1 + (rn % 1), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 1000000;
INSERT dbo.B_UC_katman_1M (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 100000;
INSERT dbo.B_UC_katman_1M (musteri_id, tutar, durum) SELECT 7 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_B_UC_katman_1M ON dbo.B_UC_katman_1M (musteri_id);
UPDATE STATISTICS dbo.B_UC_katman_1M WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_B_UC_katman_1M @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.B_UC_katman_1M WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
GO
EXEC dbo.P_B_UC_katman_1M @m = 7; EXEC dbo.P_B_UC_katman_1M @m = 1; EXEC dbo.P_B_UC_katman_1M @m = 2; EXEC dbo.P_B_UC_katman_1M @m = 7; EXEC dbo.P_B_UC_katman_1M @m = 1; EXEC dbo.P_B_UC_katman_1M @m = 2;
GO
EXEC sys.sp_query_store_flush_db;
SELECT 'B_UC_katman_1M' AS tablo, v.query_variant_query_id AS qid, SUBSTRING(t.query_sql_text, CHARINDEX('QueryVariantID', t.query_sql_text), 14) AS variant, RIGHT(REPLACE(t.query_sql_text, CHAR(10), ' '), 18) AS sinirlar,
  (SELECT TOP (1) CAST(rs.avg_duration AS decimal(18,0)) FROM sys.query_store_plan p JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id WHERE p.query_id = v.query_variant_query_id ORDER BY rs.runtime_stats_id DESC) AS ort_mikrosn
FROM sys.query_store_query_variant v JOIN sys.query_store_query q ON q.query_id = v.query_variant_query_id JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id ORDER BY v.query_variant_query_id;
GO

PRINT '#### B_orta_100';
CREATE TABLE dbo.B_orta_100 (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
INSERT dbo.B_orta_100 (musteri_id, tutar, durum) SELECT 1 + (rn % 1), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500000;
INSERT dbo.B_orta_100 (musteri_id, tutar, durum) SELECT 2 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 500;
INSERT dbo.B_orta_100 (musteri_id, tutar, durum) SELECT 7 + (rn % 5), 10 + rn % 90, rn % 5 FROM dbo.sayi WHERE rn <= 5;
CREATE INDEX ix_B_orta_100 ON dbo.B_orta_100 (musteri_id);
UPDATE STATISTICS dbo.B_orta_100 WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.P_B_orta_100 @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.B_orta_100 WHERE musteri_id = @m;
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
GO
EXEC dbo.P_B_orta_100 @m = 7; EXEC dbo.P_B_orta_100 @m = 1; EXEC dbo.P_B_orta_100 @m = 2; EXEC dbo.P_B_orta_100 @m = 7; EXEC dbo.P_B_orta_100 @m = 1; EXEC dbo.P_B_orta_100 @m = 2;
GO
EXEC sys.sp_query_store_flush_db;
SELECT 'B_orta_100' AS tablo, v.query_variant_query_id AS qid, SUBSTRING(t.query_sql_text, CHARINDEX('QueryVariantID', t.query_sql_text), 14) AS variant, RIGHT(REPLACE(t.query_sql_text, CHAR(10), ' '), 18) AS sinirlar,
  (SELECT TOP (1) CAST(rs.avg_duration AS decimal(18,0)) FROM sys.query_store_plan p JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id WHERE p.query_id = v.query_variant_query_id ORDER BY rs.runtime_stats_id DESC) AS ort_mikrosn
FROM sys.query_store_query_variant v JOIN sys.query_store_query q ON q.query_id = v.query_variant_query_id JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id ORDER BY v.query_variant_query_id;
GO

USE master;
GO
DROP EVENT SESSION psp_izle ON SERVER;
GO
