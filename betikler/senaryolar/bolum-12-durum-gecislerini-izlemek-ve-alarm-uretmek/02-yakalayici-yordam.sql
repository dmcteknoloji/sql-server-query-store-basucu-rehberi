-- SQL Server Query Store Basucu Rehberi, Bolum 12, 'Durum geçişlerini izlemek ve alarm üretmek'
-- Yalnizca test ortaminda calistirin.

CREATE OR ALTER PROCEDURE dbo.qs_apc_yakala
    @saklama_gun int = 90
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    -- 1) Gorunumu once kisa surede kendi tablomuza al. JSON ayristirmasi kilit altinda yapilmasin.
    CREATE TABLE #kaynak (
        oneri_adi nvarchar(400) NOT NULL PRIMARY KEY, durum nvarchar(30) NULL, neden nvarchar(80) NULL,
        revert_baslatan nvarchar(30) NULL, revert_zamani datetime2 NULL,
        query_id bigint NULL, regressed_plan_id bigint NULL, recommended_plan_id bigint NULL);
    INSERT #kaynak
    SELECT r.name, JSON_VALUE(r.state, '$.currentValue'), JSON_VALUE(r.state, '$.reason'),
           r.revert_action_initiated_by, r.revert_action_start_time,
           d.query_id, d.regressedPlanId, d.recommendedPlanId
    FROM sys.dm_db_tuning_recommendations AS r
    CROSS APPLY OPENJSON(r.details, '$.planForceDetails')
         WITH (query_id bigint '$.queryId', regressedPlanId bigint '$.regressedPlanId', recommendedPlanId bigint '$.recommendedPlanId') AS d
    WHERE r.type = N'FORCE_LAST_GOOD_PLAN';

    BEGIN TRY
        BEGIN TRANSACTION;
        -- 2) Ayni anda ikinci bir calisma varsa beklemeden cik. Kilit islem bitince kendiliginden kalkar.
        DECLARE @kilit int;
        EXEC @kilit = sys.sp_getapplock @Resource = N'qs_apc_yakala', @LockMode = N'Exclusive',
                                        @LockOwner = N'Transaction', @LockTimeout = 0;
        IF @kilit < 0
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3) Durumu degisenleri guncelle
        UPDATE h
        SET onceki_durum = CASE WHEN ISNULL(h.durum, N'') <> ISNULL(k.durum, N'') THEN h.durum ELSE h.onceki_durum END,
            alarm_gonderildi = CASE WHEN ISNULL(h.durum, N'') <> ISNULL(k.durum, N'') AND k.durum IN (N'Reverted', N'Expired') THEN 0 ELSE h.alarm_gonderildi END,
            durum = k.durum, neden = k.neden, revert_baslatan = k.revert_baslatan, revert_zamani = k.revert_zamani,
            son_gorulme_utc = SYSUTCDATETIME()
        FROM dbo.qs_apc_gecmis AS h
        JOIN #kaynak AS k ON k.oneri_adi = h.oneri_adi;

        -- 4) Yeni onerileri ekle
        INSERT dbo.qs_apc_gecmis (oneri_adi, query_id, regressed_plan_id, recommended_plan_id, ilk_gorulme_utc, son_gorulme_utc,
                                  onceki_durum, durum, neden, revert_baslatan, revert_zamani)
        SELECT k.oneri_adi, k.query_id, k.regressed_plan_id, k.recommended_plan_id, SYSUTCDATETIME(), SYSUTCDATETIME(),
               NULL, k.durum, k.neden, k.revert_baslatan, k.revert_zamani
        FROM #kaynak AS k
        WHERE NOT EXISTS (SELECT 1 FROM dbo.qs_apc_gecmis AS h WHERE h.oneri_adi = k.oneri_adi);

        -- 5) Eski kayitlari temizle. Alarmi gonderilmemis olana dokunma.
        DELETE dbo.qs_apc_gecmis
        WHERE son_gorulme_utc < DATEADD(DAY, -@saklama_gun, SYSUTCDATETIME())
          AND (alarm_gonderildi = 1 OR durum NOT IN (N'Reverted', N'Expired') OR durum IS NULL);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
