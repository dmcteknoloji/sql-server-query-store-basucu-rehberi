-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Native procedure ve istatistik toplama'
-- Test ortaminda calistirin.

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO
USE qs_lab_xtp;
GO
CREATE PROCEDURE dbo.XtpOzet2 @m int, @adet int OUTPUT WITH NATIVE_COMPILATION, SCHEMABINDING AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')
    SELECT @adet = COUNT(*) FROM dbo.XtpSiparis WHERE musteri_id = @m;
END;
GO
CREATE PROCEDURE dbo.XtpKos2 @ad varchar(40) AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @t0 datetime2 = SYSDATETIME(), @i int = 0, @a int;
    WHILE @i < 500000 BEGIN EXEC dbo.XtpOzet2 @m = 7, @adet = @a OUTPUT; SET @i += 1; END
    INSERT dbo.XtpSonuc VALUES (@ad, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
END;
GO
DROP TABLE IF EXISTS dbo.XtpSonuc;
CREATE TABLE dbo.XtpSonuc (kosul varchar(40), gecen_ms int);
GO
DECLARE @db int = DB_ID(), @obj int = OBJECT_ID(N'dbo.XtpOzet2'), @r int = 0;
EXEC dbo.XtpKos2 @ad = 'isinma';
WHILE @r < 4
BEGIN
    EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 0, @database_id = @db, @xtp_object_id = @obj;
    EXEC dbo.XtpKos2 @ad = 'kapali';
    EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 1, @database_id = @db, @xtp_object_id = @obj;
    EXEC dbo.XtpKos2 @ad = 'sorgu_istatistigi_acik';
    SET @r += 1;
END
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 0, @database_id = @db, @xtp_object_id = @obj;
GO
SELECT kosul, COUNT(*) AS tekrar, MIN(gecen_ms) AS en_kucuk_ms, AVG(gecen_ms) AS ort_ms, MAX(gecen_ms) AS en_buyuk_ms FROM dbo.XtpSonuc WHERE kosul <> 'isinma' GROUP BY kosul;
GO
