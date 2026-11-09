-- SQL Server Query Store Basucu Rehberi, Bolum 13, 'Planlı failover öncesi kontrol'
-- Yalnizca test ortaminda calistirin.

IF OBJECT_ID(N'dbo.qs_failover_envanter') IS NULL
CREATE TABLE dbo.qs_failover_envanter (
    snapshot_id uniqueidentifier NOT NULL,
    alinma_zamani_utc datetime2 NOT NULL,
    tur varchar(12) NOT NULL,                 -- FORCED_PLAN ya da HINT
    query_id bigint NOT NULL,
    plan_id bigint NULL,
    query_hash binary(8) NULL,
    query_plan_hash binary(8) NULL,
    plan_forcing_type_desc nvarchar(60) NULL,
    hint_metni nvarchar(max) NULL,
    kaynak nvarchar(60) NULL,
    geri_yukleme_komutu nvarchar(max) NULL,
    metin_ozeti nvarchar(300) NULL
);
