-- SQL Server Query Store Basucu Rehberi, Bolum 14, 'Natively compiled procedureler'
-- Yalnizca test ortaminda calistirin.

DECLARE @db int = DB_ID(), @obj int = OBJECT_ID(N'dbo.XtpOzet');
-- yalnizca bu procedure icin ac
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 1, @database_id = @db, @xtp_object_id = @obj;
-- isiniz bitince kapat
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 0, @database_id = @db, @xtp_object_id = @obj;
