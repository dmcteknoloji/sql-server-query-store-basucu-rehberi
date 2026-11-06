-- SQL Server Query Store Basucu Rehberi, Bolum 16
-- tum kullanici veritabanlarinda Query Store durumu (SQL Server 2017 ve sonrasi)
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SET NOCOUNT ON;
DROP TABLE IF EXISTS #qs;
CREATE TABLE #qs (veritabani sysname, desired_state_desc nvarchar(60) NULL, actual_state_desc nvarchar(60) NULL, readonly_reason int NULL,
                  current_storage_size_mb bigint NULL, max_storage_size_mb bigint NULL, query_capture_mode_desc nvarchar(60) NULL, hata nvarchar(400) NULL);
DECLARE @db sysname, @sql nvarchar(max);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
  SELECT d.name FROM sys.databases AS d
  WHERE d.database_id > 4 AND d.state = 0 AND d.is_query_store_on = 1 AND d.source_database_id IS NULL
    AND NOT EXISTS (SELECT 1 FROM sys.dm_hadr_database_replica_states AS s
                    WHERE s.database_id = d.database_id AND s.is_local = 1 AND s.is_primary_replica = 0);
OPEN c; FETCH NEXT FROM c INTO @db;
WHILE @@FETCH_STATUS = 0
BEGIN
  BEGIN TRY
    SET @sql = N'INSERT #qs (veritabani, desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb, max_storage_size_mb, query_capture_mode_desc) '
             + N'SELECT @d, desired_state_desc, actual_state_desc, readonly_reason, current_storage_size_mb, max_storage_size_mb, query_capture_mode_desc FROM '
             + QUOTENAME(@db) + N'.sys.database_query_store_options';
    EXEC sys.sp_executesql @sql, N'@d sysname', @d = @db;
  END TRY
  BEGIN CATCH
    INSERT #qs (veritabani, hata) VALUES (@db, LEFT(ERROR_MESSAGE(), 400));
  END CATCH
  FETCH NEXT FROM c INTO @db;
END
CLOSE c; DEALLOCATE c;
IF NOT EXISTS (SELECT 1 FROM #qs)
    SELECT 'Query Store acik kullanici veritabani yok' AS sonuc;
ELSE
    SELECT * FROM #qs ORDER BY veritabani;
