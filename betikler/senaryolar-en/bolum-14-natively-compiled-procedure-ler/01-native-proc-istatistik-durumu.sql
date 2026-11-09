-- SQL Server Query Store Handbook, Chapter 14, 'Natively compiled procedures'
-- Run in a test environment only.

DECLARE @db int = DB_ID(), @obj int = OBJECT_ID(N'dbo.XtpOzet');
-- turn on only for this procedure
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 1, @database_id = @db, @xtp_object_id = @obj;
-- turn off when you are done
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 0, @database_id = @db, @xtp_object_id = @obj;
