SET NOCOUNT ON;
SELECT @@VERSION AS surum;
GO
USE psp_lab;
GO
DROP TABLE IF EXISTS dbo.PspDengeli;
CREATE TABLE dbo.PspDengeli (id int IDENTITY PRIMARY KEY, musteri_id int NOT NULL);
INSERT dbo.PspDengeli (musteri_id) SELECT TOP (50000) ABS(CHECKSUM(NEWID())) % 100 FROM sys.all_objects a CROSS JOIN sys.all_objects b;
CREATE INDEX ix_dengeli ON dbo.PspDengeli (musteri_id);
GO
DECLARE @tablo sysname = N'dbo.PspSiparis', @kolon sysname = N'musteri_id';
SELECT @tablo AS tablo, s.name AS istatistik, COUNT(*) AS histogram_adimi, MAX(h.equal_rows) AS en_yuksek_eq, MIN(NULLIF(h.equal_rows, 0)) AS en_dusuk_eq,
       CAST(MAX(h.equal_rows) / MIN(NULLIF(h.equal_rows, 0)) AS decimal(18,0)) AS oran,
       CASE WHEN MAX(h.equal_rows) / MIN(NULLIF(h.equal_rows, 0)) >= 100000 THEN 'ESIK ASILDI' ELSE 'ESIK ALTINDA' END AS karar
FROM sys.stats AS s
JOIN sys.stats_columns AS sc ON sc.object_id = s.object_id AND sc.stats_id = s.stats_id AND sc.stats_column_id = 1
JOIN sys.columns AS c ON c.object_id = sc.object_id AND c.column_id = sc.column_id AND c.name = @kolon
CROSS APPLY sys.dm_db_stats_histogram(s.object_id, s.stats_id) AS h
WHERE s.object_id = OBJECT_ID(@tablo)
GROUP BY s.name;
GO
DECLARE @tablo sysname = N'dbo.PspDengeli', @kolon sysname = N'musteri_id';
SELECT @tablo AS tablo, s.name AS istatistik, COUNT(*) AS histogram_adimi, MAX(h.equal_rows) AS en_yuksek_eq, MIN(NULLIF(h.equal_rows, 0)) AS en_dusuk_eq,
       CAST(MAX(h.equal_rows) / MIN(NULLIF(h.equal_rows, 0)) AS decimal(18,0)) AS oran,
       CASE WHEN MAX(h.equal_rows) / MIN(NULLIF(h.equal_rows, 0)) >= 100000 THEN 'ESIK ASILDI' ELSE 'ESIK ALTINDA' END AS karar
FROM sys.stats AS s
JOIN sys.stats_columns AS sc ON sc.object_id = s.object_id AND sc.stats_id = s.stats_id AND sc.stats_column_id = 1
JOIN sys.columns AS c ON c.object_id = sc.object_id AND c.column_id = sc.column_id AND c.name = @kolon
CROSS APPLY sys.dm_db_stats_histogram(s.object_id, s.stats_id) AS h
WHERE s.object_id = OBJECT_ID(@tablo)
GROUP BY s.name;
GO
