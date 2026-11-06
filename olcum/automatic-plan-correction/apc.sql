SET NOCOUNT ON;
IF DB_ID('apc') IS NOT NULL BEGIN ALTER DATABASE apc SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE apc; END
GO
CREATE DATABASE apc;
GO
ALTER DATABASE apc SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, INTERVAL_LENGTH_MINUTES = 1, DATA_FLUSH_INTERVAL_SECONDS = 60);
ALTER DATABASE apc SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = ON);
GO
USE apc;
CREATE TABLE dbo.Siparis (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, d char(100) NOT NULL DEFAULT 'x');
INSERT dbo.Siparis (musteri_id) SELECT TOP (400000) 1 FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c;
INSERT dbo.Siparis (musteri_id) SELECT TOP (20000) 2 + ABS(CHECKSUM(NEWID())) % 2000 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
CREATE INDEX ix_m ON dbo.Siparis(musteri_id);
GO
CREATE PROCEDURE dbo.SiparisGetir @m int AS BEGIN DECLARE @a int, @b bigint; SELECT @a = COUNT(*), @b = SUM(LEN(d)) FROM dbo.Siparis WHERE musteri_id = @m; END
GO
SELECT name, desired_state_desc, actual_state_desc, reason_desc FROM sys.database_automatic_tuning_options;
GO
PRINT '== faz 1: iyi plan (tarama), 25 calistirma, interval gecisi';
DECLARE @i int = 0; WHILE @i < 25 BEGIN EXEC dbo.SiparisGetir @m = 1; SET @i += 1; END
GO
WAITFOR DELAY '00:01:10';
GO
PRINT '== faz 2: kotu plan (seek+lookup) ile buyuk musteri';
EXEC sp_recompile 'dbo.SiparisGetir';
EXEC dbo.SiparisGetir @m = 700;
DECLARE @i int = 0; WHILE @i < 12 BEGIN EXEC dbo.SiparisGetir @m = 1; SET @i += 1; END
GO
DECLARE @tur int = 0;
WHILE @tur < 6
BEGIN
  WAITFOR DELAY '00:00:40';
  EXEC sp_query_store_flush_db;
  DECLARE @j int = 0; WHILE @j < 6 BEGIN EXEC dbo.SiparisGetir @m = 1; SET @j += 1; END
  SELECT @tur AS tur, (SELECT COUNT(*) FROM sys.dm_db_tuning_recommendations) AS oneri_sayisi,
         (SELECT COUNT(*) FROM sys.query_store_plan WHERE is_forced_plan = 1 AND plan_forcing_type_desc = N'AUTO') AS otomatik_sabit_plan,
         (SELECT TOP 1 CAST(JSON_VALUE(state, '$.currentValue') AS nvarchar(40)) FROM sys.dm_db_tuning_recommendations) AS oneri_durumu;
  SET @tur += 1;
END
GO
SELECT reason, score, JSON_VALUE(state, '$.currentValue') AS durum, JSON_VALUE(details, '$.implementationDetails.script') AS betik FROM sys.dm_db_tuning_recommendations;
SELECT plan_id, is_forced_plan, plan_forcing_type_desc, force_failure_count FROM sys.query_store_plan WHERE query_id IN (SELECT query_id FROM sys.query_store_query WHERE object_id = OBJECT_ID('dbo.SiparisGetir')) ORDER BY plan_id;
GO
