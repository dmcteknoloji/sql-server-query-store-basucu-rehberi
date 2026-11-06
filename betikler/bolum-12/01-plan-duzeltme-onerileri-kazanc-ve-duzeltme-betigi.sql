-- SQL Server Query Store Basucu Rehberi, Bolum 12
-- plan duzeltme onerileri, kazanc ve duzeltme betigi
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT reason, score,
       script = JSON_VALUE(details, '$.implementationDetails.script'),
       planForceDetails.*,
       estimated_gain = (regressedPlanExecutionCount + recommendedPlanExecutionCount)
                        * (regressedPlanCpuTimeAverage - recommendedPlanCpuTimeAverage) / 1000000,
       error_prone = IIF(regressedPlanErrorCount > recommendedPlanErrorCount, 'YES', 'NO')
FROM sys.dm_db_tuning_recommendations
CROSS APPLY OPENJSON (details, '$.planForceDetails')
     WITH (query_id int '$.queryId',
           regressedPlanId int '$.regressedPlanId',
           recommendedPlanId int '$.recommendedPlanId',
           regressedPlanErrorCount int,
           recommendedPlanErrorCount int,
           regressedPlanExecutionCount int,
           regressedPlanCpuTimeAverage float,
           recommendedPlanExecutionCount int,
           recommendedPlanCpuTimeAverage float) AS planForceDetails;
