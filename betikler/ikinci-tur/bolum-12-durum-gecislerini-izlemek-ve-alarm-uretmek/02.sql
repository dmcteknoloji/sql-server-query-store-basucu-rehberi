-- SQL Server Query Store Basucu Rehberi, Bolum 12, 'Durum geçişlerini izlemek ve alarm üretmek'
-- Test ortaminda calistirin.

CREATE PROCEDURE dbo.qs_apc_yakala AS
BEGIN
SET NOCOUNT ON;
;WITH kaynak AS (
    SELECT r.name AS oneri_adi,
           JSON_VALUE(r.state, '$.currentValue') AS durum,
           JSON_VALUE(r.state, '$.reason') AS neden,
           r.revert_action_initiated_by AS revert_baslatan,
           r.revert_action_start_time AS revert_zamani,
           d.query_id, d.regressedPlanId, d.recommendedPlanId
    FROM sys.dm_db_tuning_recommendations AS r
    CROSS APPLY OPENJSON(r.details, '$.planForceDetails')
         WITH (query_id bigint '$.queryId', regressedPlanId bigint '$.regressedPlanId', recommendedPlanId bigint '$.recommendedPlanId') AS d
    WHERE r.type = N'FORCE_LAST_GOOD_PLAN'
)
MERGE dbo.qs_apc_gecmis AS h
USING kaynak AS k ON k.oneri_adi = h.oneri_adi
WHEN MATCHED THEN
    UPDATE SET onceki_durum = CASE WHEN ISNULL(h.durum, N'') <> ISNULL(k.durum, N'') THEN h.durum ELSE h.onceki_durum END,
               durum = k.durum, neden = k.neden, revert_baslatan = k.revert_baslatan, revert_zamani = k.revert_zamani,
               son_gorulme_utc = SYSUTCDATETIME(),
               alarm_gonderildi = CASE WHEN ISNULL(h.durum, N'') <> ISNULL(k.durum, N'') AND k.durum IN (N'Reverted', N'Expired') THEN 0 ELSE h.alarm_gonderildi END
WHEN NOT MATCHED BY TARGET THEN
    INSERT (oneri_adi, query_id, regressed_plan_id, recommended_plan_id, ilk_gorulme_utc, son_gorulme_utc, onceki_durum, durum, neden, revert_baslatan, revert_zamani)
    VALUES (k.oneri_adi, k.query_id, k.regressedPlanId, k.recommendedPlanId, SYSUTCDATETIME(), SYSUTCDATETIME(), NULL, k.durum, k.neden, k.revert_baslatan, k.revert_zamani);
END;
