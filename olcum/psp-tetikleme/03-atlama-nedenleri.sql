
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
CREATE TABLE dbo.Siparis (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
SELECT TOP (520000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn INTO #n FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c;
INSERT dbo.Siparis (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM #n WHERE rn <= 400000;
INSERT dbo.Siparis (musteri_id, tutar, durum) SELECT 2 + rn % 50, 10 + rn % 90, rn % 5 FROM #n WHERE rn <= 100000;
INSERT dbo.Siparis (musteri_id, tutar, durum) SELECT 100 + rn % 2000, 10 + rn % 90, rn % 5 FROM #n WHERE rn <= 20000;
CREATE INDEX ix_m ON dbo.Siparis (musteri_id);
CREATE INDEX ix_d ON dbo.Siparis (durum);
SELECT * INTO dbo.SiparisK FROM dbo.Siparis;
ALTER TABLE dbo.SiparisK ADD CONSTRAINT pk_sk PRIMARY KEY (id);
CREATE INDEX ix_mk ON dbo.SiparisK (musteri_id) INCLUDE (tutar, durum);
UPDATE STATISTICS dbo.Siparis WITH FULLSCAN; UPDATE STATISTICS dbo.SiparisK WITH FULLSCAN;
SELECT 'veri dagilimi' AS baslik, CASE WHEN musteri_id = 1 THEN 'yuksek (musteri 1)' WHEN musteri_id < 100 THEN 'orta (musteri 2-51)' ELSE 'dusuk (musteri 100-2099)' END AS sinif, COUNT(*) AS satir, COUNT(DISTINCT musteri_id) AS musteri FROM dbo.Siparis GROUP BY CASE WHEN musteri_id = 1 THEN 'yuksek (musteri 1)' WHEN musteri_id < 100 THEN 'orta (musteri 2-51)' ELSE 'dusuk (musteri 100-2099)' END ORDER BY 3 DESC;
GO
CREATE PROCEDURE dbo.Liste_Lookup @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = @m;
GO
CREATE PROCEDURE dbo.Liste_Kapsayan @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam FROM dbo.SiparisK WHERE musteri_id = @m;
GO
CREATE PROCEDURE dbo.Liste_Yerel @m int AS BEGIN DECLARE @x int = @m; SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = @x; END
GO
CREATE PROCEDURE dbo.Liste_Recompile @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = @m OPTION (RECOMPILE);
GO
CREATE PROCEDURE dbo.Liste_Esitsizlik @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id >= @m AND musteri_id < @m + 3;
GO
CREATE PROCEDURE dbo.Liste_Durum @d tinyint AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE durum = @d;
GO
CREATE PROCEDURE dbo.Liste_Hint @m int AS SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = @m OPTION (USE HINT ('DISABLE_PARAMETER_SNIFFING'));
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

PRINT '#### S1 kapsayan indeks (eski deneyimiz)';

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.Liste_Kapsayan @m = 1500;
EXEC dbo.Liste_Kapsayan @m = 1;
EXEC dbo.Liste_Kapsayan @m = 10;
EXEC dbo.Liste_Kapsayan @m = 1500;
EXEC dbo.Liste_Kapsayan @m = 1;
EXEC dbo.Liste_Kapsayan @m = 10;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'SiparisK';
GO

PRINT '#### S2 kapsamayan indeks, key lookup gerektirir';

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.Liste_Lookup @m = 1500;
EXEC dbo.Liste_Lookup @m = 1;
EXEC dbo.Liste_Lookup @m = 10;
EXEC dbo.Liste_Lookup @m = 1500;
EXEC dbo.Liste_Lookup @m = 1;
EXEC dbo.Liste_Lookup @m = 10;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'dbo].[Siparis';
GO

PRINT '#### S3 sp_executesql ile ayni sorgu';

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = @m', N'@m int', @m = 1500;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = @m', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = @m', N'@m int', @m = 10;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = @m', N'@m int', @m = 1500;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = @m', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = @m', N'@m int', @m = 10;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'dbo.Siparis WHERE musteri_id = @m';
GO

PRINT '#### S4 sabit degerli ad hoc (otomatik parametrelenir)';

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = 1500;
SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = 1;
SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = 10;
SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = 1500;
SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = 1;
SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id = 10;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'MAX(aciklama) AS ornek FROM dbo.Siparis WHERE musteri_id';
GO

PRINT '#### S5 yerel degisken';

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.Liste_Yerel @m = 1500;
EXEC dbo.Liste_Yerel @m = 1;
EXEC dbo.Liste_Yerel @m = 10;
EXEC dbo.Liste_Yerel @m = 1500;
EXEC dbo.Liste_Yerel @m = 1;
EXEC dbo.Liste_Yerel @m = 10;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'@x';
GO

PRINT '#### S6 OPTION (RECOMPILE)';

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.Liste_Recompile @m = 1500;
EXEC dbo.Liste_Recompile @m = 1;
EXEC dbo.Liste_Recompile @m = 10;
EXEC dbo.Liste_Recompile @m = 1500;
EXEC dbo.Liste_Recompile @m = 1;
EXEC dbo.Liste_Recompile @m = 10;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'RECOMPILE';
GO

PRINT '#### S7 esitsizlik koşulu';

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.Liste_Esitsizlik @m = 1500;
EXEC dbo.Liste_Esitsizlik @m = 1;
EXEC dbo.Liste_Esitsizlik @m = 10;
EXEC dbo.Liste_Esitsizlik @m = 1500;
EXEC dbo.Liste_Esitsizlik @m = 1;
EXEC dbo.Liste_Esitsizlik @m = 10;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'musteri_id >= @m';
GO

PRINT '#### S8 duzgun dagilan kolon (durum)';

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.Liste_Durum @d = 0;
EXEC dbo.Liste_Durum @d = 1;
EXEC dbo.Liste_Durum @d = 2;
EXEC dbo.Liste_Durum @d = 3;
EXEC dbo.Liste_Durum @d = 4;
EXEC dbo.Liste_Durum @d = 0;
EXEC dbo.Liste_Durum @d = 1;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'durum = @d';
GO

PRINT '#### S9 USE HINT DISABLE_PARAMETER_SNIFFING';

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.Liste_Hint @m = 1500;
EXEC dbo.Liste_Hint @m = 1;
EXEC dbo.Liste_Hint @m = 10;
EXEC dbo.Liste_Hint @m = 1500;
EXEC dbo.Liste_Hint @m = 1;
EXEC dbo.Liste_Hint @m = 10;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'DISABLE_PARAMETER_SNIFFING';
GO

PRINT '#### S10 database scoped config KAPALI';
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SENSITIVE_PLAN_OPTIMIZATION = OFF;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.Liste_Lookup @m = 1500;
EXEC dbo.Liste_Lookup @m = 1;
EXEC dbo.Liste_Lookup @m = 10;
EXEC dbo.Liste_Lookup @m = 1500;
EXEC dbo.Liste_Lookup @m = 1;
EXEC dbo.Liste_Lookup @m = 10;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'dbo].[Siparis';
GO

PRINT '#### S11 ayni config tekrar ACIK, S2 tekrari';
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SENSITIVE_PLAN_OPTIMIZATION = ON;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.Liste_Lookup @m = 1500;
EXEC dbo.Liste_Lookup @m = 1;
EXEC dbo.Liste_Lookup @m = 10;
EXEC dbo.Liste_Lookup @m = 1500;
EXEC dbo.Liste_Lookup @m = 1;
EXEC dbo.Liste_Lookup @m = 10;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'dbo].[Siparis';
GO

PRINT '#### S12 uyumluluk 150';
ALTER DATABASE qs_lab_psp SET COMPATIBILITY_LEVEL = 150;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE qs_lab_psp SET QUERY_STORE CLEAR ALL;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC dbo.Liste_Lookup @m = 1500;
EXEC dbo.Liste_Lookup @m = 1;
EXEC dbo.Liste_Lookup @m = 10;
EXEC dbo.Liste_Lookup @m = 1500;
EXEC dbo.Liste_Lookup @m = 1;
EXEC dbo.Liste_Lookup @m = 10;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_oku;
EXEC dbo.plan_oku N'dbo].[Siparis';
GO

USE master;
GO
DROP EVENT SESSION psp_izle ON SERVER;
GO
