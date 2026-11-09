-- SQL Server Query Store Handbook, Chapter 18, 'Execution styles on the secondary'
-- Run in a test environment only.

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO
USE qs_lab_ag;
GO
-- 1 dynamic EXEC, WHILE, with comment marker
DECLARE @i int = 0;
WHILE @i < 60 BEGIN EXEC (N'SELECT COUNT_BIG(*) AS ag_v1_exec_yorumlu FROM dbo.AgIzleme WHERE deger = 424242 /*isaret*/'); SET @i += 1; END
GO
-- 2 dynamic EXEC, WHILE, no comment
DECLARE @i int = 0;
WHILE @i < 60 BEGIN EXEC (N'SELECT COUNT_BIG(*) AS ag_v2_exec_yorumsuz FROM dbo.AgIzleme WHERE deger = 424242'); SET @i += 1; END
GO
-- 3 direct query, WHILE
DECLARE @i int = 0;
WHILE @i < 60 BEGIN SELECT COUNT_BIG(*) AS ag_v3_dogrudan_while FROM dbo.AgIzleme WHERE deger = 424242; SET @i += 1; END
GO
-- 4 direct query, GO 60
SELECT COUNT_BIG(*) AS ag_v4_dogrudan_go FROM dbo.AgIzleme WHERE deger = 424242;
GO 60
-- 5 sp_executesql, WHILE
DECLARE @i int = 0;
WHILE @i < 60 BEGIN EXEC sys.sp_executesql N'SELECT COUNT_BIG(*) AS ag_v5_spexecutesql FROM dbo.AgIzleme WHERE deger = @d', N'@d int', @d = 424242; SET @i += 1; END
GO
-- 6 dynamic EXEC, GO 60
EXEC (N'SELECT COUNT_BIG(*) AS ag_v6_exec_go FROM dbo.AgIzleme WHERE deger = 424242');
GO 60
-- 7 dynamic EXEC, different literal each round (text is first put into a variable)
DECLARE @i int = 0, @s nvarchar(300);
WHILE @i < 60 BEGIN
  SET @s = N'SELECT COUNT_BIG(*) AS ag_v7_exec_farkli_sabit FROM dbo.AgIzleme WHERE deger = ' + CAST(900200 + @i AS nvarchar(10));
  EXEC (@s); SET @i += 1;
END
GO
-- 8 three separate direct queries, each with a different literal
SELECT COUNT_BIG(*) AS ag_v8_uc_sorgu FROM dbo.AgIzleme WHERE deger = 900003;
SELECT COUNT_BIG(*) AS ag_v8_uc_sorgu FROM dbo.AgIzleme WHERE deger = 900004;
SELECT COUNT_BIG(*) AS ag_v8_uc_sorgu FROM dbo.AgIzleme WHERE deger = 900005;
GO
