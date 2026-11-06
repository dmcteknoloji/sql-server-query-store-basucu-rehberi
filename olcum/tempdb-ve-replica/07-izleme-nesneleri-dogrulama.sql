SET NOCOUNT ON;
SELECT @@VERSION AS surum;
GO
PRINT '#### internal_state (AG olmayan tek dugum)';
SELECT pending_message_count, messaging_memory_used_mb FROM sys.database_query_store_internal_state;
PRINT '#### query_store_replicas (AG olmayan tek dugum)';
SELECT COUNT(*) AS satir FROM sys.query_store_replicas;
PRINT '#### Query Store performans sayaclari';
SELECT RTRIM(object_name) AS nesne, RTRIM(counter_name) AS sayac, RTRIM(instance_name) AS ornek, cntr_value FROM sys.dm_os_performance_counters WHERE object_name LIKE '%Query Store%' ORDER BY instance_name, counter_name;
GO
PRINT '#### secondary ve mesajlasma olay oturumu kurulur mu';
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'qs_replica_izle') DROP EVENT SESSION qs_replica_izle ON SERVER;
GO
CREATE EVENT SESSION qs_replica_izle ON SERVER
ADD EVENT sqlserver.hadr_db_manager_qds_msg,
ADD EVENT sqlserver.query_store_hadron_transport_failures,
ADD EVENT sqlserver.query_store_messaging_failures,
ADD EVENT sqlserver.query_store_messaging_fragmentation,
ADD EVENT qds.query_store_async_queue_diagnostics,
ADD EVENT sqlserver.query_store_replica_info_persistence_failure,
ADD EVENT sqlserver.query_store_secondary_guid_creation_failure
ADD TARGET package0.ring_buffer (SET max_memory = 4096)
WITH (MAX_DISPATCH_LATENCY = 5 SECONDS);
GO
SELECT p.name AS paket, o.name AS olay FROM sys.dm_xe_objects o JOIN sys.dm_xe_packages p ON p.guid = o.package_guid WHERE o.name IN ('hadr_db_manager_qds_msg','query_store_hadron_transport_failures','query_store_messaging_failures','query_store_messaging_fragmentation','query_store_async_queue_diagnostics','query_store_replica_info_persistence_failure','query_store_secondary_guid_creation_failure') ORDER BY 2;
GO
