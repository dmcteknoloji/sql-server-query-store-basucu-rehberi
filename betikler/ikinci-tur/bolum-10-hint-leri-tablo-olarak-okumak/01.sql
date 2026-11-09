-- SQL Server Query Store Basucu Rehberi, Bolum 10, 'Hintleri tablo olarak okumak'
-- Test ortaminda calistirin.

WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT h.query_id, h.query_hint_id, h.query_hint_text, h.source_desc AS kaynak,
       h.query_hint_failure_count, h.last_query_hint_failure_reason_desc,
       p.plan_id, p.plan_type_desc, p.is_forced_plan,
       x.s.value('@QueryStoreStatementHintText', 'nvarchar(max)') AS plandaki_hint_metni,
       x.s.value('@QueryStoreStatementHintId', 'bigint') AS plandaki_hint_id,
       x.s.value('@QueryStoreStatementHintSource', 'nvarchar(60)') AS plandaki_kaynak,
       LEFT(t.query_sql_text, 100) AS metin
FROM sys.query_store_query_hints AS h
JOIN sys.query_store_query AS q ON q.query_id = h.query_id
JOIN sys.query_store_query_text AS t ON t.query_text_id = q.query_text_id
LEFT JOIN sys.query_store_plan AS p ON p.query_id = h.query_id
OUTER APPLY (SELECT TRY_CAST(p.query_plan AS xml) AS px) AS c
OUTER APPLY c.px.nodes('//StmtSimple[@QueryStoreStatementHintText]') AS x(s)
ORDER BY h.query_id, p.plan_id;
