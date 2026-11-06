SET NOCOUNT ON;
ALTER DATABASE model SET QUERY_STORE = ON;
SELECT name, is_query_store_on FROM sys.databases WHERE database_id <= 4 ORDER BY database_id;
