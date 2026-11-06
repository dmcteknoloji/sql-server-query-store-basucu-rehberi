SET NOCOUNT ON;
SELECT @@VERSION AS surum;
PRINT '#### XE olaylari (psp, parameter_sensitive, variant, dispatcher)';
SELECT o.package_guid, p.name AS paket, o.name AS olay, o.description
FROM sys.dm_xe_objects o JOIN sys.dm_xe_packages p ON p.guid = o.package_guid
WHERE o.object_type = 'event' AND (o.name LIKE '%psp%' OR o.name LIKE '%parameter_sensitive%' OR o.name LIKE '%variant%' OR o.name LIKE '%dispatcher%' OR o.name LIKE '%optional_parameter%' OR o.name LIKE '%oppo%')
ORDER BY o.name;
PRINT '#### belirtilen adlar var mi';
SELECT n.ad, CASE WHEN EXISTS (SELECT 1 FROM sys.dm_xe_objects o WHERE o.name = n.ad AND o.object_type='event') THEN 'VAR' ELSE 'YOK' END AS durum
FROM (VALUES ('psp_feature_feedback'),('query_variant_track_operation'),('parameter_sensitive_plan_optimization'),('parameter_sensitive_plan_optimization_skipped_reason'),('query_with_parameter_sensitive_plan_optimization')) n(ad);
PRINT '#### olay kolonlari';
SELECT c.object_name AS olay, c.name AS kolon, c.type_name, c.description
FROM sys.dm_xe_object_columns c
WHERE c.object_name IN (SELECT o.name FROM sys.dm_xe_objects o WHERE o.object_type='event' AND (o.name LIKE '%parameter_sensitive%' OR o.name LIKE '%variant%' OR o.name LIKE '%psp%' OR o.name LIKE '%dispatcher%'))
  AND c.column_type <> 'readonly'
ORDER BY c.object_name, c.column_id;
PRINT '#### map degerleri';
SELECT m.name AS harita, m.map_key, m.map_value
FROM sys.dm_xe_map_values m
WHERE m.name LIKE '%parameter_sensitive%' OR m.name LIKE '%psp%' OR m.name LIKE '%variant%' OR m.name LIKE '%skipped%'
ORDER BY m.name, m.map_key;
PRINT '#### database scoped config';
SELECT name, value FROM sys.database_scoped_configurations WHERE name LIKE '%PARAMETER%';
