-- PSP (Parameter Sensitive Plan) tetikleme laboratuvari
-- SQL Server 2022 ve sonrasi. Test ortaminda calistirin, qs_lab_psp veritabanini siler ve yeniden olusturur.
-- Veri: musteri 1 icin 500.000 satir, musteri 2-6 icin 5.000'er satir, musteri 7-11 icin 1'er satir.
-- Beklenti: en yuksek ve en dusuk EQUAL_ROWS orani 100.000'in ustunde oldugu icin PSP devreye girer.
SET NOCOUNT ON;
SELECT @@VERSION AS surum;
GO
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'psp_izle') DROP EVENT SESSION psp_izle ON SERVER;
IF DB_ID('qs_lab_psp') IS NOT NULL BEGIN ALTER DATABASE qs_lab_psp SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_lab_psp; END
GO
CREATE DATABASE qs_lab_psp;
GO
ALTER DATABASE qs_lab_psp SET COMPATIBILITY_LEVEL = 160;
ALTER DATABASE qs_lab_psp SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
-- Genisletilmis olay oturumu: PSP uygulandiginda ve atlandiginda (nedeniyle birlikte)
CREATE EVENT SESSION psp_izle ON SERVER
ADD EVENT sqlserver.parameter_sensitive_plan_optimization (ACTION (sqlserver.database_name, sqlserver.sql_text) WHERE sqlserver.database_name = N'qs_lab_psp'),
ADD EVENT sqlserver.parameter_sensitive_plan_optimization_skipped_reason (ACTION (sqlserver.database_name, sqlserver.sql_text) WHERE sqlserver.database_name = N'qs_lab_psp')
ADD TARGET package0.ring_buffer (SET max_memory = 4096)
WITH (MAX_DISPATCH_LATENCY = 1 SECONDS, EVENT_RETENTION_MODE = NO_EVENT_LOSS);
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
USE qs_lab_psp;
GO
CREATE TABLE dbo.PspSiparis (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL, durum tinyint NOT NULL, aciklama char(100) NOT NULL DEFAULT 'x');
SELECT TOP (500000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn INTO #sayi FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c;
INSERT dbo.PspSiparis (musteri_id, tutar, durum) SELECT 1, 10 + rn % 90, rn % 5 FROM #sayi;                         -- yuksek sinif
INSERT dbo.PspSiparis (musteri_id, tutar, durum) SELECT 2 + rn % 5, 10 + rn % 90, rn % 5 FROM #sayi WHERE rn <= 25000;  -- orta sinif, 5 musteri x 5.000
INSERT dbo.PspSiparis (musteri_id, tutar, durum) SELECT 7 + rn % 5, 10 + rn % 90, rn % 5 FROM #sayi WHERE rn <= 5;      -- dusuk sinif, 5 musteri x 1
CREATE INDEX ix_psp_musteri ON dbo.PspSiparis (musteri_id);   -- kapsamayan indeks, key lookup gerektirir
UPDATE STATISTICS dbo.PspSiparis WITH FULLSCAN;
GO
CREATE PROCEDURE dbo.PspOzet @m int AS
SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m;
GO

PRINT '#### 1. ADAY KONTROLU, histogramda en yuksek ve en dusuk EQUAL_ROWS orani';
SELECT s.name AS istatistik, COUNT(*) AS histogram_adimi, MAX(h.equal_rows) AS en_yuksek_eq, MIN(NULLIF(h.equal_rows, 0)) AS en_dusuk_eq,
       CAST(MAX(h.equal_rows) / MIN(NULLIF(h.equal_rows, 0)) AS decimal(18,0)) AS oran,
       CASE WHEN MAX(h.equal_rows) / MIN(NULLIF(h.equal_rows, 0)) >= 100000 THEN 'ESIK ASILDI' ELSE 'ESIK ALTINDA' END AS karar
FROM sys.stats s
JOIN sys.stats_columns sc ON sc.object_id = s.object_id AND sc.stats_id = s.stats_id AND sc.stats_column_id = 1
JOIN sys.columns c ON c.object_id = sc.object_id AND c.column_id = sc.column_id AND c.name = N'musteri_id'
CROSS APPLY sys.dm_db_stats_histogram(s.object_id, s.stats_id) h
WHERE s.object_id = OBJECT_ID(N'dbo.PspSiparis')
GROUP BY s.name;
GO
PRINT '#### 2. CAGRILAR, once nadir (dusuk) parametre, sonra yuksek ve orta';
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC dbo.PspOzet @m = 7;
EXEC dbo.PspOzet @m = 1;
EXEC dbo.PspOzet @m = 2;
EXEC dbo.PspOzet @m = 7;
EXEC dbo.PspOzet @m = 1;
EXEC dbo.PspOzet @m = 2;
GO
WAITFOR DELAY '00:00:02';
SET QUOTED_IDENTIFIER ON;
GO
PRINT '#### 3. XE OLAYLARI, dispatcher (variant_id 0) ve her varyant icin bir olay beklenir';
DECLARE @x xml = (SELECT CAST(t.target_data AS xml) FROM sys.dm_xe_session_targets t JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address WHERE s.name = 'psp_izle' AND t.target_name = 'ring_buffer');
SELECT e.value('@name', 'varchar(80)') AS olay,
       ISNULL(e.value('(data[@name="reason"]/text)[1]', 'varchar(60)'), '-') AS atlama_nedeni,
       ISNULL(CAST(e.value('(data[@name="query_variant_id"]/value)[1]', 'int') AS varchar(10)), '-') AS variant_id,
       ISNULL(e.value('(data[@name="is_query_variant"]/value)[1]', 'varchar(10)'), '-') AS varyant_mi,
       ISNULL(CAST(e.value('(data[@name="predicate_count"]/value)[1]', 'int') AS varchar(10)), '-') AS predicate_sayisi
FROM @x.nodes('/RingBufferTarget/event') x(e)
WHERE e.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(400)') LIKE N'%PspOzet%' AND e.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(400)') NOT LIKE N'%ring_buffer%'
ORDER BY e.value('@timestamp', 'datetime2');
GO
PRINT '#### 4. QUERY STORE, plan tipleri ve varyant eslemesi';
EXEC sys.sp_query_store_flush_db;
SELECT p.plan_type_desc, COUNT(*) AS plan_adedi
FROM sys.query_store_plan p JOIN sys.query_store_query q ON q.query_id = p.query_id
WHERE q.object_id = OBJECT_ID(N'dbo.PspOzet') OR q.query_id IN (SELECT query_variant_query_id FROM sys.query_store_query_variant)
GROUP BY p.plan_type_desc;
SELECT v.parent_query_id, v.query_variant_query_id, v.dispatcher_plan_id FROM sys.query_store_query_variant v ORDER BY v.query_variant_query_id;
GO
PRINT '#### 5. PLAN SEKLI, her plan icin seek, lookup ve scan operatorleri';
SELECT p.plan_id, p.query_id, p.plan_type_desc,
       CASE WHEN CAST(p.query_plan AS nvarchar(max)) LIKE N'%PhysicalOp="Index Seek"%' THEN 'seek' ELSE '-' END AS seek,
       CASE WHEN CAST(p.query_plan AS nvarchar(max)) LIKE N'%PhysicalOp="Key Lookup"%' OR CAST(p.query_plan AS nvarchar(max)) LIKE N'%Lookup="1"%' THEN 'lookup' ELSE '-' END AS lookup,
       CASE WHEN CAST(p.query_plan AS nvarchar(max)) LIKE N'%PhysicalOp="Clustered Index Scan"%' THEN 'scan' ELSE '-' END AS tarama,
       (SELECT TOP (1) CAST(rs.avg_duration AS decimal(18,0)) FROM sys.query_store_runtime_stats rs WHERE rs.plan_id = p.plan_id ORDER BY rs.runtime_stats_id DESC) AS ort_sure_mikrosn
FROM sys.query_store_plan p JOIN sys.query_store_query q ON q.query_id = p.query_id
WHERE q.object_id = OBJECT_ID(N'dbo.PspOzet') OR q.query_id IN (SELECT query_variant_query_id FROM sys.query_store_query_variant)
ORDER BY p.query_id, p.plan_id;
GO
PRINT '#### 6. VARYANT QUERY METNI';
SELECT q.query_id, RIGHT(REPLACE(REPLACE(t.query_sql_text, CHAR(13), ' '), CHAR(10), ' '), 120) AS metin_sonu
FROM sys.query_store_query q JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id
WHERE q.query_id IN (SELECT query_variant_query_id FROM sys.query_store_query_variant);
GO
USE master;
GO
DROP EVENT SESSION psp_izle ON SERVER;
GO
