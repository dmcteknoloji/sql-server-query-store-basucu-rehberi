-- SQL Server Query Store Handbook, Chapter 10, 'Reading hints as a table'
-- Run in a test environment only.

WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT TOP (200)
       x.s.value('@QueryStoreStatementHintId', 'bigint') AS hint_id,
       x.s.value('@QueryStoreStatementHintText', 'nvarchar(max)') AS hint_metni,
       x.s.value('@QueryStoreStatementHintSource', 'nvarchar(60)') AS kaynak,
       cp.usecounts, cp.objtype, LEFT(st.text, 100) AS metin
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
CROSS APPLY qp.query_plan.nodes('//StmtSimple[@QueryStoreStatementHintId]') AS x(s)
WHERE qp.dbid = DB_ID() AND qp.query_plan.exist('//StmtSimple/@QueryStoreStatementHintId') = 1;
