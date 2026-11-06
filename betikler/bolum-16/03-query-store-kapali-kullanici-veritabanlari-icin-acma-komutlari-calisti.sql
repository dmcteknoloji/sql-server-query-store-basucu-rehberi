-- Query Store Basucu Rehberi, Bolum 16
-- Query Store kapali kullanici veritabanlari icin acma komutlari (@calistir = 0 yalnizca yazdirir)
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SET NOCOUNT ON;
DECLARE @calistir bit = 0, @en_fazla int = 10, @bekleme char(8) = '00:00:05', @tavan_mb int = 1000;
DECLARE @haric TABLE (name sysname);                -- satici veritabanlarini buraya ekleyin
DECLARE @db sysname, @cmd nvarchar(max), @adet int = 0;
DECLARE @bekleme_ayari nvarchar(60) = CASE WHEN CAST(SERVERPROPERTY('ProductMajorVersion') AS int) >= 14 THEN N', WAIT_STATS_CAPTURE_MODE = ON' ELSE N'' END;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
  SELECT d.name FROM sys.databases AS d
  WHERE d.database_id > 4 AND d.state = 0 AND d.is_read_only = 0 AND d.is_query_store_on = 0
        AND d.user_access = 0 AND d.is_distributor = 0 AND d.source_database_id IS NULL
        AND d.name NOT IN (SELECT name FROM @haric)
        AND NOT EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states AS s
                        WHERE s.database_id = d.database_id AND s.is_local = 1 AND s.is_primary_replica = 0)
  ORDER BY d.name;
OPEN c; FETCH NEXT FROM c INTO @db;
WHILE @@FETCH_STATUS = 0 AND @adet < @en_fazla
BEGIN
  SET @cmd = N'ALTER DATABASE ' + QUOTENAME(@db) + N' SET QUERY_STORE = ON ('
           + N'OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), '
           + N'DATA_FLUSH_INTERVAL_SECONDS = 900, MAX_STORAGE_SIZE_MB = ' + CAST(@tavan_mb AS nvarchar(10)) + N', INTERVAL_LENGTH_MINUTES = 60, '
           + N'SIZE_BASED_CLEANUP_MODE = AUTO, QUERY_CAPTURE_MODE = AUTO, MAX_PLANS_PER_QUERY = 200' + @bekleme_ayari + N')';
  PRINT @cmd;
  BEGIN TRY
    IF @calistir = 1 BEGIN EXEC sys.sp_executesql @cmd; WAITFOR DELAY @bekleme; END
  END TRY
  BEGIN CATCH
    PRINT N'HATA ' + @db + N': ' + LEFT(ERROR_MESSAGE(), 300);
  END CATCH
  SET @adet += 1;
  FETCH NEXT FROM c INTO @db;
END
CLOSE c; DEALLOCATE c;
SELECT @adet AS islenen_veritabani, @adet * @tavan_mb AS rezerve_toplam_mb;
