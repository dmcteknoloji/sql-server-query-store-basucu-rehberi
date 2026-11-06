SET NOCOUNT ON;
SELECT @@VERSION AS surum, (SELECT sqlserver_start_time FROM sys.dm_os_sys_info) AS baslangic;
SELECT database_id, name, is_query_store_on FROM sys.databases WHERE database_id <= 4 ORDER BY database_id;
SELECT 'tempdb' AS vt, desired_state_desc, actual_state_desc, readonly_reason FROM tempdb.sys.database_query_store_options;
SELECT COUNT(*) AS tempdb_options_satiri FROM tempdb.sys.database_query_store_options;
SELECT 'model' AS vt, desired_state_desc, actual_state_desc FROM model.sys.database_query_store_options;
GO
BEGIN TRY ALTER DATABASE tempdb SET QUERY_STORE = ON; SELECT 'tempdb ON kabul edildi' AS sonuc; END TRY BEGIN CATCH SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata; END CATCH
BEGIN TRY ALTER DATABASE tempdb SET QUERY_STORE (OPERATION_MODE = READ_WRITE); SELECT 'tempdb ayar kabul edildi' AS sonuc; END TRY BEGIN CATCH SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata; END CATCH
BEGIN TRY ALTER DATABASE master SET QUERY_STORE = ON; SELECT 'master ON kabul edildi' AS sonuc; END TRY BEGIN CATCH SELECT ERROR_NUMBER() AS hata_no, ERROR_MESSAGE() AS hata; END CATCH
SELECT database_id, name, is_query_store_on FROM sys.databases WHERE database_id <= 2 ORDER BY database_id;
GO
