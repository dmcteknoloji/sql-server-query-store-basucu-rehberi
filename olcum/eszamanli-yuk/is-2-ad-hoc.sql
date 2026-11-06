SET NOCOUNT ON;
DECLARE @i int = 0, @s nvarchar(400);
WHILE @i < 3000 BEGIN
  SET @s = N'DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE k = ' + CAST((@i * 31 + @@SPID) % 1000 AS nvarchar(10)) + N' AND id > ' + CAST(@i + @@SPID * 100000 AS nvarchar(12));
  EXEC (@s); SET @i += 1;
END
