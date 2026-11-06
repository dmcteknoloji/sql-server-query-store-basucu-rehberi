SET NOCOUNT ON;
DECLARE @bas datetime2(0) = SYSDATETIME(), @t0 datetime2(0) = SYSDATETIME(), @n int = 0, @i bigint = @@SPID * 100000, @s nvarchar(400), @sn datetime2(0);
DECLARE @son datetime2(0) = DATEADD(SECOND, $(SURE), SYSDATETIME());
WHILE SYSDATETIME() < @son BEGIN
  SET @s = N'DECLARE @c int; SELECT @c = COUNT(*) FROM dbo.t WHERE k = ' + CAST((@i * 7919 + 13) % 1000 AS nvarchar(12)) + N' AND id > ' + CAST(@i AS nvarchar(12));
  EXEC (@s);
  SET @i += 1; SET @n += 1;
  SET @sn = SYSDATETIME();
  IF @sn > @t0 BEGIN INSERT dbo.o_tput VALUES (@@SPID, @t0, @n); SET @n = 0; SET @t0 = @sn; END
END
