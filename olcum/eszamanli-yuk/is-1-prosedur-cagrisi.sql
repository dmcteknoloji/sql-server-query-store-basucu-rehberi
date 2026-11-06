SET NOCOUNT ON;
DECLARE @i int = 0, @k int;
WHILE @i < 30000 BEGIN SET @k = (@i * 7919 + @@SPID * 13) % 1000; EXEC dbo.p @k; SET @i += 1; END
