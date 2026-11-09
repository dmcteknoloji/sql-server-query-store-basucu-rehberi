-- SQL Server Query Store Handbook, Chapter 18, 'Secondary replica verification and backpressure'
-- Run in a test environment only.

SET NOCOUNT ON;
USE qs_lab_ag;
SELECT CONVERT(varchar(19), SYSUTCDATETIME(), 120) AS yuk_basladi;
DECLARE @i bigint = 900000000, @n int = 0, @s nvarchar(400);
WHILE @n < 20000 BEGIN
  SET @s = N'DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.AgIzleme WHERE deger = ' + CAST((@i * 7919 + 13) % 1000 AS nvarchar(12)) + N' AND id > ' + CAST(@i AS nvarchar(12));
  EXEC (@s); SET @i += 1; SET @n += 1;
END
SELECT CONVERT(varchar(19), SYSUTCDATETIME(), 120) AS yuk_bitti;
