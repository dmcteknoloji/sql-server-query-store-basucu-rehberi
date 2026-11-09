-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Secondaryde çalıştırma biçimleri'
-- Test ortaminda calistirin.

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO
USE qs_lab_ag;
GO
-- 1 dinamik EXEC, WHILE, yorum isaretli
DECLARE @i int = 0;
WHILE @i < 60 BEGIN EXEC (N'SELECT COUNT_BIG(*) AS ag_v1_exec_yorumlu FROM dbo.AgIzleme WHERE deger = 424242 /*isaret*/'); SET @i += 1; END
GO
-- 2 dinamik EXEC, WHILE, yorumsuz
DECLARE @i int = 0;
WHILE @i < 60 BEGIN EXEC (N'SELECT COUNT_BIG(*) AS ag_v2_exec_yorumsuz FROM dbo.AgIzleme WHERE deger = 424242'); SET @i += 1; END
GO
-- 3 dogrudan sorgu, WHILE
DECLARE @i int = 0;
WHILE @i < 60 BEGIN SELECT COUNT_BIG(*) AS ag_v3_dogrudan_while FROM dbo.AgIzleme WHERE deger = 424242; SET @i += 1; END
GO
-- 4 dogrudan sorgu, GO 60
SELECT COUNT_BIG(*) AS ag_v4_dogrudan_go FROM dbo.AgIzleme WHERE deger = 424242;
GO 60
-- 5 sp_executesql, WHILE
DECLARE @i int = 0;
WHILE @i < 60 BEGIN EXEC sys.sp_executesql N'SELECT COUNT_BIG(*) AS ag_v5_spexecutesql FROM dbo.AgIzleme WHERE deger = @d', N'@d int', @d = 424242; SET @i += 1; END
GO
-- 6 dinamik EXEC, GO 60
EXEC (N'SELECT COUNT_BIG(*) AS ag_v6_exec_go FROM dbo.AgIzleme WHERE deger = 424242');
GO 60
-- 7 dinamik EXEC, her turda farkli sabit (metin once degiskene alinir)
DECLARE @i int = 0, @s nvarchar(300);
WHILE @i < 60 BEGIN
  SET @s = N'SELECT COUNT_BIG(*) AS ag_v7_exec_farkli_sabit FROM dbo.AgIzleme WHERE deger = ' + CAST(900200 + @i AS nvarchar(10));
  EXEC (@s); SET @i += 1;
END
GO
-- 8 uc ayri dogrudan sorgu, her biri farkli sabit
SELECT COUNT_BIG(*) AS ag_v8_uc_sorgu FROM dbo.AgIzleme WHERE deger = 900003;
SELECT COUNT_BIG(*) AS ag_v8_uc_sorgu FROM dbo.AgIzleme WHERE deger = 900004;
SELECT COUNT_BIG(*) AS ag_v8_uc_sorgu FROM dbo.AgIzleme WHERE deger = 900005;
GO
