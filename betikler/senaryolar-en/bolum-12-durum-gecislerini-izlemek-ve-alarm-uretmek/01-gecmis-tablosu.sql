-- SQL Server Query Store Handbook, Chapter 12, 'Watching state transitions and raising alerts'
-- Run in a test environment only.

IF OBJECT_ID(N'dbo.qs_apc_gecmis') IS NULL
CREATE TABLE dbo.qs_apc_gecmis (
    oneri_adi nvarchar(400) NOT NULL CONSTRAINT pk_qs_apc_gecmis PRIMARY KEY,
    query_id bigint NULL, regressed_plan_id bigint NULL, recommended_plan_id bigint NULL,
    ilk_gorulme_utc datetime2 NOT NULL, son_gorulme_utc datetime2 NOT NULL,
    onceki_durum nvarchar(30) NULL, durum nvarchar(30) NULL, neden nvarchar(80) NULL,
    revert_baslatan nvarchar(30) NULL, revert_zamani datetime2 NULL,
    alarm_gonderildi bit NOT NULL CONSTRAINT df_qs_apc_alarm DEFAULT 0
);
