-- SQL Server Query Store Handbook, Chapter 18, 'Discovery-based collection of PSP events'
-- Run in a test environment only.

SET NOCOUNT ON;
SELECT p.name AS paket, o.name AS olay, o.description AS aciklama
FROM sys.dm_xe_objects AS o
JOIN sys.dm_xe_packages AS p ON p.guid = o.package_guid
WHERE o.object_type = N'event'
  AND (o.name LIKE N'%parameter_sensitive%'
    OR o.name LIKE N'%query_variant%'
    OR o.name LIKE N'%multiplan%'
    OR o.name LIKE N'%dispatcher%'
    OR o.name LIKE N'%optional_parameter%'
    OR o.name LIKE N'%psp%')
ORDER BY p.name, o.name;
