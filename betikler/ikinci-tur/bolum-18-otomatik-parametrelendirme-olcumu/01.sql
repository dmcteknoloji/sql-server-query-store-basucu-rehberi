-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Otomatik parametrelendirme ölçümü'
-- Test ortaminda calistirin.

SET NOCOUNT ON;
IF DB_ID(N'qs_lab_param') IS NOT NULL BEGIN ALTER DATABASE qs_lab_param SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_lab_param; END
CREATE DATABASE qs_lab_param;
ALTER DATABASE qs_lab_param SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
USE qs_lab_param;
GO
CREATE TABLE dbo.PsT1 (id int IDENTITY PRIMARY KEY, kolon int NOT NULL, metin varchar(50) NOT NULL, tarih date NOT NULL);
CREATE TABLE dbo.PsT2 (id int IDENTITY PRIMARY KEY, t1_id int NOT NULL, deger int NOT NULL);
CREATE INDEX ix_kolon ON dbo.PsT1 (kolon);
CREATE INDEX ix_t1 ON dbo.PsT2 (t1_id);
INSERT dbo.PsT1 (kolon, metin, tarih)
SELECT TOP (20000) n % 100, CONCAT('abc', n % 500), DATEADD(DAY, n % 700, '2024-01-01')
FROM (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects a CROSS JOIN sys.all_objects b) s;
INSERT dbo.PsT2 (t1_id, deger) SELECT id, id % 50 FROM dbo.PsT1;
GO
DROP TABLE IF EXISTS dbo.PsAday, dbo.PsSonuc;
CREATE TABLE dbo.PsAday (kod char(3) PRIMARY KEY, aciklama varchar(60), komut nvarchar(max));
INSERT dbo.PsAday VALUES
 ('k01', 'tek tablo, birincil anahtar esitligi',  N'SELECT /*k01*/ metin FROM dbo.PsT1 WHERE id = 5'),
 ('k02', 'tek tablo, indeksli kolon esitligi',    N'SELECT /*k02*/ metin FROM dbo.PsT1 WHERE kolon = 5'),
 ('k03', 'aralik (BETWEEN)',                      N'SELECT /*k03*/ metin FROM dbo.PsT1 WHERE kolon BETWEEN 5 AND 7'),
 ('k04', 'IN listesi',                            N'SELECT /*k04*/ metin FROM dbo.PsT1 WHERE kolon IN (1, 2, 3)'),
 ('k05', 'INNER JOIN',                            N'SELECT /*k05*/ a.metin, b.deger FROM dbo.PsT1 a JOIN dbo.PsT2 b ON b.t1_id = a.id WHERE a.id = 5'),
 ('k06', 'TOP',                                   N'SELECT /*k06*/ TOP (10) metin FROM dbo.PsT1 WHERE kolon = 5'),
 ('k07', 'DISTINCT',                              N'SELECT /*k07*/ DISTINCT metin FROM dbo.PsT1 WHERE kolon = 5'),
 ('k08', 'GROUP BY',                              N'SELECT /*k08*/ kolon, COUNT(*) FROM dbo.PsT1 WHERE kolon > 5 GROUP BY kolon'),
 ('k09', 'UNION',                                 N'SELECT /*k09*/ metin FROM dbo.PsT1 WHERE kolon = 5 UNION SELECT metin FROM dbo.PsT1 WHERE kolon = 6'),
 ('k10', 'IN alt sorgu',                          N'SELECT /*k10*/ metin FROM dbo.PsT1 WHERE id IN (SELECT t1_id FROM dbo.PsT2 WHERE deger = 5)'),
 ('k11', 'EXISTS alt sorgu',                      N'SELECT /*k11*/ metin FROM dbo.PsT1 a WHERE EXISTS (SELECT 1 FROM dbo.PsT2 b WHERE b.t1_id = a.id AND b.deger = 5)'),
 ('k12', 'ORDER BY',                              N'SELECT /*k12*/ metin FROM dbo.PsT1 WHERE kolon = 5 ORDER BY id'),
 ('k13', 'OR',                                    N'SELECT /*k13*/ metin FROM dbo.PsT1 WHERE kolon = 5 OR kolon = 6'),
 ('k14', 'LIKE',                                  N'SELECT /*k14*/ metin FROM dbo.PsT1 WHERE metin LIKE ''abc1%'''),
 ('k15', 'fonksiyon icinde kolon',                N'SELECT /*k15*/ metin FROM dbo.PsT1 WHERE YEAR(tarih) = 2025'),
 ('k16', 'COUNT(*)',                              N'SELECT /*k16*/ COUNT(*) FROM dbo.PsT1 WHERE kolon = 5'),
 ('k17', 'select listesinde literal',             N'SELECT /*k17*/ 5 AS x, metin FROM dbo.PsT1 WHERE id = 5'),
 ('k18', 'INSERT ... VALUES',                     N'INSERT /*k18*/ dbo.PsT2 (t1_id, deger) VALUES (1, 5)'),
 ('k19', 'UPDATE',                                N'UPDATE /*k19*/ dbo.PsT1 SET kolon = 7 WHERE id = 5'),
 ('k20', 'OPTION (MAXDOP 1)',                     N'SELECT /*k20*/ metin FROM dbo.PsT1 WHERE kolon = 5 OPTION (MAXDOP 1)'),
 ('k21', 'TOP, PK esitligi (trivial plan)',       N'SELECT /*k21*/ TOP (1) metin FROM dbo.PsT1 WHERE id = 5'),
 ('k22', 'DISTINCT, PK esitligi (trivial plan)',  N'SELECT /*k22*/ DISTINCT metin FROM dbo.PsT1 WHERE id = 5'),
 ('k23', 'JOIN PK-PK, PK esitligi',               N'SELECT /*k23*/ a.metin FROM dbo.PsT1 a JOIN dbo.PsT2 b ON b.id = a.id WHERE a.id = 5'),
 ('k24', 'IN listesi, PK uzerinde',               N'SELECT /*k24*/ metin FROM dbo.PsT1 WHERE id IN (5, 6)');
CREATE TABLE dbo.PsSonuc (mod_adi varchar(8), kod char(3), aciklama varchar(60), tur varchar(60), trivial_plan int);
GO
-- Her mod ayri batch'te calisir. ALTER DATABASE ... SET PARAMETERIZATION ayni batch'teki sonraki derlemelere yansimiyor.
CREATE PROCEDURE dbo.AdayKos @mod varchar(8) AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @kod char(3), @ack varchar(60), @k nvarchar(max), @once bigint;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT kod, aciklama, komut FROM dbo.PsAday ORDER BY kod;
    OPEN c; FETCH NEXT FROM c INTO @kod, @ack, @k;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @once = ISNULL(MAX(query_id), 0) FROM sys.query_store_query;
        EXEC (@k);
        EXEC sys.sp_query_store_flush_db;
        -- Parametrelenen ifadeler Query Store'da normalize metinle saklanir (kucuk harf, yorumsuz),
        -- bu yuzden isaret aranmaz. Aday calistiktan sonra eklenen query satirlari okunur.
        INSERT dbo.PsSonuc
        SELECT @mod, @kod, @ack,
               ISNULL(STRING_AGG(CAST(z.tur AS varchar(20)), '+') WITHIN GROUP (ORDER BY z.tur), 'YAKALANMADI'),
               MAX(z.trivial)
        FROM (SELECT q.query_parameterization_type_desc AS tur, MAX(CAST(p.is_trivial_plan AS int)) AS trivial
              FROM sys.query_store_query AS q
              JOIN sys.query_store_query_text AS t ON t.query_text_id = q.query_text_id
              LEFT JOIN sys.query_store_plan AS p ON p.query_id = q.query_id
              WHERE q.query_id > @once AND t.query_sql_text LIKE N'%pst%'
                AND t.query_sql_text NOT LIKE N'%query_store%'
              GROUP BY q.query_id, q.query_parameterization_type_desc) AS z;
        FETCH NEXT FROM c INTO @kod, @ack, @k;
    END
    CLOSE c; DEALLOCATE c;
END;
GO
ALTER DATABASE qs_lab_param SET PARAMETERIZATION SIMPLE;
ALTER DATABASE qs_lab_param SET QUERY_STORE CLEAR ALL;
GO
EXEC dbo.AdayKos @mod = 'SIMPLE';
GO
ALTER DATABASE qs_lab_param SET PARAMETERIZATION FORCED;
ALTER DATABASE qs_lab_param SET QUERY_STORE CLEAR ALL;
GO
EXEC dbo.AdayKos @mod = 'FORCED';
GO
SELECT s.kod, s.aciklama, s.tur AS simple_modda, s.trivial_plan AS simple_trivial, f.tur AS forced_modda, f.trivial_plan AS forced_trivial
FROM dbo.PsSonuc s JOIN dbo.PsSonuc f ON f.kod = s.kod AND f.mod_adi = 'FORCED'
WHERE s.mod_adi = 'SIMPLE' ORDER BY s.kod;
GO
