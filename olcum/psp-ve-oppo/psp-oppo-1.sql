SET NOCOUNT ON;
IF DB_ID('psp') IS NOT NULL BEGIN ALTER DATABASE psp SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE psp; END
GO
CREATE DATABASE psp;
GO
ALTER DATABASE psp SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
USE psp;
CREATE TABLE dbo.Siparis (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL, tutar decimal(10,2) NOT NULL DEFAULT 10, durum tinyint NOT NULL, d char(50) NOT NULL DEFAULT 'x');
INSERT dbo.Siparis (musteri_id, durum) SELECT TOP (500000) 1, ABS(CHECKSUM(NEWID())) % 5 FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c;
INSERT dbo.Siparis (musteri_id, durum) SELECT TOP (40000) 2 + ABS(CHECKSUM(NEWID())) % 2000, ABS(CHECKSUM(NEWID())) % 5 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
CREATE INDEX ix_m ON dbo.Siparis(musteri_id) INCLUDE (tutar, durum);
CREATE INDEX ix_d ON dbo.Siparis(durum);
GO
CREATE PROCEDURE dbo.Ozet @m int AS SELECT s.durum, COUNT(*) AS adet, SUM(s.tutar) AS toplam FROM dbo.Siparis AS s WHERE s.musteri_id = @m GROUP BY s.durum;
GO
CREATE PROCEDURE dbo.Ara @musteri int = NULL, @durum tinyint = NULL AS SELECT COUNT(*) AS adet FROM dbo.Siparis WHERE (musteri_id = @musteri OR @musteri IS NULL) AND (durum = @durum OR @durum IS NULL);
GO
CREATE PROCEDURE dbo.rapor @etiket nvarchar(40) AS
BEGIN
  SELECT @etiket AS durum, p.plan_type_desc, COUNT(*) AS plan_adedi
  FROM sys.query_store_plan p JOIN sys.query_store_query q ON q.query_id = p.query_id
  WHERE q.object_id IN (OBJECT_ID('dbo.Ozet'), OBJECT_ID('dbo.Ara')) AND p.plan_type_desc IS NOT NULL
  GROUP BY p.plan_type_desc;
  SELECT @etiket AS durum, COUNT(*) AS variant_kaydi FROM sys.query_store_query_variant;
  SELECT @etiket AS durum, cp.objtype, COUNT(*) AS cache_plani, SUM(CASE WHEN CAST(qp.query_plan AS nvarchar(max)) LIKE N'%ParameterSensitivePlan%' OR CAST(qp.query_plan AS nvarchar(max)) LIKE N'%Dispatcher%' THEN 1 ELSE 0 END) AS dispatcher_iceren
  FROM sys.dm_exec_cached_plans cp CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) t CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
  WHERE t.dbid = DB_ID() AND t.objectid IN (OBJECT_ID('dbo.Ozet'), OBJECT_ID('dbo.Ara')) GROUP BY cp.objtype;
END
GO

PRINT '#### SEVIYE 150';
ALTER DATABASE psp SET COMPATIBILITY_LEVEL = 150;
ALTER DATABASE psp SET QUERY_STORE CLEAR ALL;
WAITFOR DELAY '00:00:05';
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO
DECLARE @i int = 0, @mm int, @t int;
WHILE @i < 6 BEGIN SET @mm = 2 + @i; EXEC dbo.Ozet @m = @mm; EXEC dbo.Ozet @m = 1; SET @i += 1; END
EXEC dbo.Ara @musteri = 1, @durum = NULL; EXEC dbo.Ara @musteri = NULL, @durum = 3; EXEC dbo.Ara @musteri = 5, @durum = 2; EXEC dbo.Ara @musteri = NULL, @durum = NULL; EXEC dbo.Ara @musteri = 1, @durum = 2;
EXEC dbo.Ara @musteri = 1, @durum = NULL; EXEC dbo.Ara @musteri = NULL, @durum = 3; EXEC dbo.Ara @musteri = 7, @durum = NULL;
EXEC sp_query_store_flush_db;
SELECT 150 AS seviye, (SELECT compatibility_level FROM sys.databases WHERE name = 'psp') AS db_seviye;
EXEC dbo.rapor N'uyumluluk 150';
GO

PRINT '#### SEVIYE 160';
ALTER DATABASE psp SET COMPATIBILITY_LEVEL = 160;
ALTER DATABASE psp SET QUERY_STORE CLEAR ALL;
WAITFOR DELAY '00:00:05';
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO
DECLARE @i int = 0, @mm int, @t int;
WHILE @i < 6 BEGIN SET @mm = 2 + @i; EXEC dbo.Ozet @m = @mm; EXEC dbo.Ozet @m = 1; SET @i += 1; END
EXEC dbo.Ara @musteri = 1, @durum = NULL; EXEC dbo.Ara @musteri = NULL, @durum = 3; EXEC dbo.Ara @musteri = 5, @durum = 2; EXEC dbo.Ara @musteri = NULL, @durum = NULL; EXEC dbo.Ara @musteri = 1, @durum = 2;
EXEC dbo.Ara @musteri = 1, @durum = NULL; EXEC dbo.Ara @musteri = NULL, @durum = 3; EXEC dbo.Ara @musteri = 7, @durum = NULL;
EXEC sp_query_store_flush_db;
SELECT 160 AS seviye, (SELECT compatibility_level FROM sys.databases WHERE name = 'psp') AS db_seviye;
EXEC dbo.rapor N'uyumluluk 160';
GO

PRINT '#### SEVIYE 170';
ALTER DATABASE psp SET COMPATIBILITY_LEVEL = 170;
ALTER DATABASE psp SET QUERY_STORE CLEAR ALL;
WAITFOR DELAY '00:00:05';
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO
DECLARE @i int = 0, @mm int, @t int;
WHILE @i < 6 BEGIN SET @mm = 2 + @i; EXEC dbo.Ozet @m = @mm; EXEC dbo.Ozet @m = 1; SET @i += 1; END
EXEC dbo.Ara @musteri = 1, @durum = NULL; EXEC dbo.Ara @musteri = NULL, @durum = 3; EXEC dbo.Ara @musteri = 5, @durum = 2; EXEC dbo.Ara @musteri = NULL, @durum = NULL; EXEC dbo.Ara @musteri = 1, @durum = 2;
EXEC dbo.Ara @musteri = 1, @durum = NULL; EXEC dbo.Ara @musteri = NULL, @durum = 3; EXEC dbo.Ara @musteri = 7, @durum = NULL;
EXEC sp_query_store_flush_db;
SELECT 170 AS seviye, (SELECT compatibility_level FROM sys.databases WHERE name = 'psp') AS db_seviye;
EXEC dbo.rapor N'uyumluluk 170';
GO
