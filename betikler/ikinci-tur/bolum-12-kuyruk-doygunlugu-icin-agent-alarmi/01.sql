-- SQL Server Query Store Basucu Rehberi, Bolum 12, 'Kuyruk doygunluğu için Agent alarmı'
-- Test ortaminda calistirin.

USE master;
EXEC sp_addmessage @msgnum = 50101, @severity = 10,
     @msgtext = N'Query Store mesaj kuyrugu doluyor. Veritabani %s, bekleyen mesaj %I64d, esik %d.',
     @lang = N'us_english', @with_log = 'TRUE', @replace = 'REPLACE';
GO
IF DB_ID('dba_araclar') IS NULL CREATE DATABASE dba_araclar;
GO
USE dba_araclar;
GO
CREATE OR ALTER PROCEDURE dbo.qs_kuyruk_alarm
    @esik int = 15000   -- gozlenen doygunluk 25.000, yuzde 60 ile baslayin
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @db sysname, @sql nvarchar(max), @bekleyen bigint, @mb decimal(9,1);
    DECLARE db_listesi CURSOR LOCAL FAST_FORWARD FOR
        SELECT name FROM sys.databases WHERE database_id > 4 AND state = 0 AND is_query_store_on = 1;
    OPEN db_listesi;
    FETCH NEXT FROM db_listesi INTO @db;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @bekleyen = NULL;
        BEGIN TRY
            SET @sql = N'SELECT @b = pending_message_count, @m = messaging_memory_used_mb FROM ' + QUOTENAME(@db) + N'.sys.database_query_store_internal_state;';
            EXEC sys.sp_executesql @sql, N'@b bigint OUTPUT, @m decimal(9,1) OUTPUT', @b = @bekleyen OUTPUT, @m = @mb OUTPUT;
        END TRY
        BEGIN CATCH
            -- Tek veritabanindaki hata dongunun kalanini durdurmasin
            PRINT CONCAT(N'atlandi: ', @db, N', ', ERROR_MESSAGE());
        END CATCH
        -- Uyari TRY blogunun disinda uretilir, boylece CATCH onu yutmaz
        IF @bekleyen >= @esik
            RAISERROR (50101, 10, 1, @db, @bekleyen, @esik) WITH LOG;
        FETCH NEXT FROM db_listesi INTO @db;
    END
    CLOSE db_listesi; DEALLOCATE db_listesi;
END;
GO
USE msdb;
IF NOT EXISTS (SELECT 1 FROM dbo.sysalerts WHERE name = N'Query Store kuyrugu doluyor')
    EXEC dbo.sp_add_alert @name = N'Query Store kuyrugu doluyor', @message_id = 50101, @severity = 0, @enabled = 1,
         @delay_between_responses = 300, @include_event_description_in = 1;
GO
