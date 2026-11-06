SET NOCOUNT ON;
SELECT @@VERSION AS surum;
GO
PRINT '#### 1. Query Store ile ilgili sistem nesneleri';
SELECT o.name, o.type_desc FROM sys.all_objects o WHERE o.name LIKE '%query_store%' OR o.name LIKE '%qds%' ORDER BY o.type_desc, o.name;
GO
PRINT '#### 2. internal_state gorunumu var mi, kolonlari';
SELECT c.name AS kolon, TYPE_NAME(c.user_type_id) AS tip FROM sys.all_columns c WHERE c.object_id = OBJECT_ID('sys.database_query_store_internal_state') ORDER BY c.column_id;
SELECT 'internal_state satir sayisi' AS bilgi, COUNT(*) AS adet FROM sys.database_query_store_internal_state;
GO
PRINT '#### 3. replica ile ilgili kolonlar';
SELECT o.name AS nesne, c.name AS kolon FROM sys.all_columns c JOIN sys.all_objects o ON o.object_id = c.object_id WHERE (o.name LIKE '%query_store%') AND (c.name LIKE '%replica%') ORDER BY o.name, c.name;
GO
PRINT '#### 4. performans sayaclari (Query Store)';
SELECT DISTINCT object_name, counter_name FROM sys.dm_os_performance_counters WHERE object_name LIKE '%Query Store%' OR object_name LIKE '%QDS%' OR counter_name LIKE '%Query Store%' ORDER BY 1, 2;
GO
PRINT '#### 5. XE olaylari (query_store, qds, replica)';
SELECT o.name AS olay, LEFT(o.description, 110) AS aciklama FROM sys.dm_xe_objects o WHERE o.object_type = 'event' AND (o.name LIKE '%query_store%' OR o.name LIKE '%qds%' OR o.name LIKE '%query_data_store%') ORDER BY o.name;
GO
PRINT '#### 6. QDS bekleme turleri';
SELECT wait_type FROM sys.dm_os_wait_stats WHERE wait_type LIKE 'QDS%' ORDER BY wait_type;
GO
PRINT '#### 7. replica yordamlari ve secenekleri';
SELECT o.name, o.type_desc FROM sys.all_objects o WHERE o.name LIKE '%replica%' AND (o.name LIKE '%query%' OR o.name LIKE '%qs%' OR o.name LIKE '%store%');
SELECT TOP (0) * FROM sys.database_query_store_options;
SELECT c.name AS kolon FROM sys.all_columns c WHERE c.object_id = OBJECT_ID('sys.database_query_store_options') ORDER BY c.column_id;
GO
