SET NOCOUNT ON;
SELECT @@VERSION AS surum;
GO
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'psp_izle') DROP EVENT SESSION psp_izle ON SERVER;
GO
CREATE EVENT SESSION psp_izle ON SERVER
ADD EVENT sqlserver.parameter_sensitive_plan_optimization (ACTION (sqlserver.database_name, sqlserver.sql_text) WHERE sqlserver.database_name = N'psp_lab'),
ADD EVENT sqlserver.parameter_sensitive_plan_optimization_skipped_reason (ACTION (sqlserver.database_name, sqlserver.sql_text) WHERE sqlserver.database_name = N'psp_lab')
ADD TARGET package0.ring_buffer (SET max_memory = 4096)
WITH (MAX_DISPATCH_LATENCY = 1 SECONDS, EVENT_RETENTION_MODE = NO_EVENT_LOSS);
GO
USE psp_lab;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE dbo.xe_ozet2 @etiket nvarchar(60) AS
BEGIN
  DECLARE @x xml = (SELECT CAST(t.target_data AS xml) FROM sys.dm_xe_session_targets t JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address WHERE s.name = 'psp_izle' AND t.target_name = 'ring_buffer');
  SELECT olay, atlama_nedeni, variant_id, COUNT(*) AS adet FROM (
    SELECT e.value('@name', 'varchar(80)') AS olay, ISNULL(e.value('(data[@name="reason"]/text)[1]', 'varchar(60)'), '-') AS atlama_nedeni,
           ISNULL(CAST(e.value('(data[@name="query_variant_id"]/value)[1]', 'int') AS varchar(10)), '-') AS variant_id,
           e.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(400)') AS m
    FROM @x.nodes('/RingBufferTarget/event') x(e)) k
  WHERE m LIKE N'%sp_executesql%' AND m LIKE N'%' + @etiket + N'%'
  GROUP BY olay, atlama_nedeni, variant_id ORDER BY olay, variant_id;
END
GO

PRINT '#### 0. gecerli USE HINT listesi (PARAMETER, PLAN, SENSITIVE, OPTIONAL, PSP, OPPO iceren adlar)';
SELECT name FROM sys.dm_exec_valid_use_hints WHERE name LIKE '%PARAMETER%' OR name LIKE '%PLAN%' OR name LIKE '%SENSITIVE%' OR name LIKE '%OPTIONAL%' OR name LIKE '%PSP%' OR name LIKE '%OPPO%' ORDER BY name;
SELECT COUNT(*) AS toplam_gecerli_hint FROM sys.dm_exec_valid_use_hints;
GO

PRINT '#### kontrol: ';
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_kontrol*/ ', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_kontrol*/ ', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_kontrol*/ ', N'@m int', @m = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_kontrol*/ ', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_kontrol*/ ', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_kontrol*/ ', N'@m int', @m = 2;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_ozet2 N'L_kontrol';
GO

PRINT '#### maxdop1: OPTION (MAXDOP 1)';
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_maxdop1*/ OPTION (MAXDOP 1)', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_maxdop1*/ OPTION (MAXDOP 1)', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_maxdop1*/ OPTION (MAXDOP 1)', N'@m int', @m = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_maxdop1*/ OPTION (MAXDOP 1)', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_maxdop1*/ OPTION (MAXDOP 1)', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_maxdop1*/ OPTION (MAXDOP 1)', N'@m int', @m = 2;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_ozet2 N'L_maxdop1';
GO

PRINT '#### opt_unknown: OPTION (OPTIMIZE FOR UNKNOWN)';
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_unknown*/ OPTION (OPTIMIZE FOR UNKNOWN)', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_unknown*/ OPTION (OPTIMIZE FOR UNKNOWN)', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_unknown*/ OPTION (OPTIMIZE FOR UNKNOWN)', N'@m int', @m = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_unknown*/ OPTION (OPTIMIZE FOR UNKNOWN)', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_unknown*/ OPTION (OPTIMIZE FOR UNKNOWN)', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_unknown*/ OPTION (OPTIMIZE FOR UNKNOWN)', N'@m int', @m = 2;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_ozet2 N'L_opt_unknown';
GO

PRINT '#### opt_for_deger: OPTION (OPTIMIZE FOR (@m = 1))';
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_for_deger*/ OPTION (OPTIMIZE FOR (@m = 1))', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_for_deger*/ OPTION (OPTIMIZE FOR (@m = 1))', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_for_deger*/ OPTION (OPTIMIZE FOR (@m = 1))', N'@m int', @m = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_for_deger*/ OPTION (OPTIMIZE FOR (@m = 1))', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_for_deger*/ OPTION (OPTIMIZE FOR (@m = 1))', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_opt_for_deger*/ OPTION (OPTIMIZE FOR (@m = 1))', N'@m int', @m = 2;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_ozet2 N'L_opt_for_deger';
GO

PRINT '#### legacy_ce: OPTION (USE HINT (''FORCE_LEGACY_CARDINALITY_ESTIMATION''))';
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_legacy_ce*/ OPTION (USE HINT (''FORCE_LEGACY_CARDINALITY_ESTIMATION''))', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_legacy_ce*/ OPTION (USE HINT (''FORCE_LEGACY_CARDINALITY_ESTIMATION''))', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_legacy_ce*/ OPTION (USE HINT (''FORCE_LEGACY_CARDINALITY_ESTIMATION''))', N'@m int', @m = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_legacy_ce*/ OPTION (USE HINT (''FORCE_LEGACY_CARDINALITY_ESTIMATION''))', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_legacy_ce*/ OPTION (USE HINT (''FORCE_LEGACY_CARDINALITY_ESTIMATION''))', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_legacy_ce*/ OPTION (USE HINT (''FORCE_LEGACY_CARDINALITY_ESTIMATION''))', N'@m int', @m = 2;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_ozet2 N'L_legacy_ce';
GO

PRINT '#### recompile: OPTION (RECOMPILE)';
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_recompile*/ OPTION (RECOMPILE)', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_recompile*/ OPTION (RECOMPILE)', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_recompile*/ OPTION (RECOMPILE)', N'@m int', @m = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_recompile*/ OPTION (RECOMPILE)', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_recompile*/ OPTION (RECOMPILE)', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_recompile*/ OPTION (RECOMPILE)', N'@m int', @m = 2;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_ozet2 N'L_recompile';
GO

PRINT '#### sniffing_kapali: OPTION (USE HINT (''DISABLE_PARAMETER_SNIFFING''))';
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_sniffing_kapali*/ OPTION (USE HINT (''DISABLE_PARAMETER_SNIFFING''))', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_sniffing_kapali*/ OPTION (USE HINT (''DISABLE_PARAMETER_SNIFFING''))', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_sniffing_kapali*/ OPTION (USE HINT (''DISABLE_PARAMETER_SNIFFING''))', N'@m int', @m = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_sniffing_kapali*/ OPTION (USE HINT (''DISABLE_PARAMETER_SNIFFING''))', N'@m int', @m = 7;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_sniffing_kapali*/ OPTION (USE HINT (''DISABLE_PARAMETER_SNIFFING''))', N'@m int', @m = 1;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m /*L_sniffing_kapali*/ OPTION (USE HINT (''DISABLE_PARAMETER_SNIFFING''))', N'@m int', @m = 2;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_ozet2 N'L_sniffing_kapali';
GO

PRINT '#### ikinci_kosul: AND durum = 2';
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
BEGIN TRY ALTER EVENT SESSION psp_izle ON SERVER STATE = STOP; END TRY BEGIN CATCH END CATCH
ALTER EVENT SESSION psp_izle ON SERVER STATE = START;
GO
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m AND durum = @d /*L_ikinci_kosul*/', N'@m int, @d tinyint', @m = 7, @d = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m AND durum = @d /*L_ikinci_kosul*/', N'@m int, @d tinyint', @m = 1, @d = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m AND durum = @d /*L_ikinci_kosul*/', N'@m int, @d tinyint', @m = 2, @d = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m AND durum = @d /*L_ikinci_kosul*/', N'@m int, @d tinyint', @m = 7, @d = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m AND durum = @d /*L_ikinci_kosul*/', N'@m int, @d tinyint', @m = 1, @d = 2;
EXEC sp_executesql N'SELECT COUNT(*) AS adet, SUM(tutar) AS toplam, MAX(aciklama) AS ornek FROM dbo.PspSiparis WHERE musteri_id = @m AND durum = @d /*L_ikinci_kosul*/', N'@m int, @d tinyint', @m = 2, @d = 2;
GO
WAITFOR DELAY '00:00:02';
EXEC dbo.xe_ozet2 N'L_ikinci_kosul';
GO

PRINT '#### hint adi denemesi, belgede gecen iki ad';
EXEC sys.sp_query_store_flush_db;
DECLARE @q int = (SELECT TOP (1) query_id FROM sys.query_store_query ORDER BY query_id DESC);
SELECT @q AS denenen_query_id;
BEGIN TRY
  EXEC sys.sp_query_store_set_hints @query_id = @q, @query_hints = N'OPTION (USE HINT (''DISABLE_OPTIONAL_PARAMETER_OPTIMIZATION''))';
  SELECT 'kabul edildi' AS sonuc;
END TRY
BEGIN CATCH
  SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata;
END CATCH
BEGIN TRY
  EXEC sys.sp_query_store_set_hints @query_id = @q, @query_hints = N'OPTION (USE HINT (''DISABLE_PARAMETER_SENSITIVE_PLAN_OPTIMIZATION''))';
  SELECT 'kabul edildi' AS sonuc;
END TRY
BEGIN CATCH
  SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata;
END CATCH
GO
USE master;
GO
DROP EVENT SESSION psp_izle ON SERVER;
GO
