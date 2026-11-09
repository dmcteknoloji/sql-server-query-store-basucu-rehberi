-- SQL Server Query Store Basucu Rehberi, Bolum 13, 'Planlı failover öncesi kontrol'
-- Yalnizca test ortaminda calistirin.

-- Planli failover oncesi Query Store kontrolu. Yalniz MEVCUT PRIMARY'de, hedef veritabaninda calistirin.
SET NOCOUNT ON;
DECLARE @db sysname = DB_NAME();
DECLARE @hedef_replika sysname = NULL;     -- NULL ise tum secondary replikalar
DECLARE @bekleme_sn int = 180;
DECLARE @redo_esik_kb bigint = 0;
DECLARE @sorun TABLE (kod varchar(40), ayrinti nvarchar(400));
DECLARE @snap uniqueidentifier = NEWID();

-- 1 on kosullar
IF ISNULL(sys.fn_hadr_is_primary_replica(@db), 0) <> 1
    INSERT @sorun VALUES ('PRIMARY_DEGIL', N'Bu veritabani bu dugumde primary degil.');
IF NOT EXISTS (SELECT 1 FROM sys.database_query_store_options WHERE actual_state_desc = N'READ_WRITE')
    INSERT @sorun SELECT 'QS_DURUMU', CONCAT(N'actual_state=', actual_state_desc, N' readonly_reason=', readonly_reason)
                  FROM sys.database_query_store_options;

-- 2 envanter anlik goruntusu
INSERT dbo.qs_failover_envanter (snapshot_id, alinma_zamani_utc, tur, query_id, plan_id, query_hash, query_plan_hash,
                                 plan_forcing_type_desc, kaynak, geri_yukleme_komutu, metin_ozeti)
SELECT @snap, SYSUTCDATETIME(), 'FORCED_PLAN', p.query_id, p.plan_id, q.query_hash, p.query_plan_hash,
       p.plan_forcing_type_desc, NULL,
       CONCAT(N'EXEC sys.sp_query_store_force_plan @query_id = ', p.query_id, N', @plan_id = ', p.plan_id, N';'),
       LEFT(t.query_sql_text, 300)
FROM sys.query_store_plan AS p
JOIN sys.query_store_query AS q ON q.query_id = p.query_id
JOIN sys.query_store_query_text AS t ON t.query_text_id = q.query_text_id
WHERE p.is_forced_plan = 1;

INSERT dbo.qs_failover_envanter (snapshot_id, alinma_zamani_utc, tur, query_id, query_hash, hint_metni, kaynak,
                                 geri_yukleme_komutu, metin_ozeti)
SELECT @snap, SYSUTCDATETIME(), 'HINT', h.query_id, q.query_hash, h.query_hint_text, h.source_desc,
       CONCAT(N'EXEC sys.sp_query_store_set_hints @query_id = ', h.query_id,
              N', @query_hints = N''', REPLACE(h.query_hint_text, N'''', N''''''), N''';'),
       LEFT(t.query_sql_text, 300)
FROM sys.query_store_query_hints AS h
JOIN sys.query_store_query AS q ON q.query_id = h.query_id
JOIN sys.query_store_query_text AS t ON t.query_text_id = q.query_text_id;

-- 3 flush, suresi de olculur. Kisa surmesi kuyrukta bekleyen is olmadigini gosterir
DECLARE @f0 datetime2 = SYSDATETIME();
EXEC sys.sp_query_store_flush_db;
DECLARE @flush_ms int = DATEDIFF(MILLISECOND, @f0, SYSDATETIME());

-- 4 kuyruklarin bosalmasini bekle
DECLARE @qs_kuyruk_var bit = CASE WHEN OBJECT_ID(N'sys.database_query_store_internal_state') IS NOT NULL THEN 1 ELSE 0 END;
DECLARE @bekleyen bigint = 0, @bellek bigint = 0, @gonderim bigint = 0, @redo bigint = 0;
DECLARE @bitis datetime2 = DATEADD(SECOND, @bekleme_sn, SYSUTCDATETIME()), @tamam bit = 0;
WHILE @tamam = 0
BEGIN
    IF @qs_kuyruk_var = 1
        EXEC sys.sp_executesql N'SELECT @a = pending_message_count, @b = messaging_memory_used_mb FROM sys.database_query_store_internal_state',
             N'@a bigint OUTPUT, @b bigint OUTPUT', @a = @bekleyen OUTPUT, @b = @bellek OUTPUT;
    SELECT @gonderim = ISNULL(MAX(drs.log_send_queue_size), 0), @redo = ISNULL(MAX(drs.redo_queue_size), 0)
    FROM sys.dm_hadr_database_replica_states AS drs
    JOIN sys.availability_replicas AS ar ON ar.replica_id = drs.replica_id
    WHERE drs.database_id = DB_ID() AND drs.is_local = 0
      AND (@hedef_replika IS NULL OR ar.replica_server_name = @hedef_replika);
    IF @bekleyen = 0 AND @bellek = 0 AND @gonderim = 0 AND @redo <= @redo_esik_kb SET @tamam = 1;
    ELSE IF SYSUTCDATETIME() >= @bitis BREAK;
    ELSE WAITFOR DELAY '00:00:02';
END
IF @tamam = 0
    INSERT @sorun VALUES ('KUYRUK_BOSALMADI',
        CONCAT(N'pending_message_count=', @bekleyen, N' messaging_memory_used_mb=', @bellek,
               N' log_send_queue_kb=', @gonderim, N' redo_queue_kb=', @redo));

-- 5 sonuc
SELECT CASE WHEN EXISTS (SELECT 1 FROM @sorun) THEN N'HAZIR DEGIL' ELSE N'HAZIR' END AS karar,
       @snap AS snapshot_id,
       (SELECT COUNT(*) FROM dbo.qs_failover_envanter WHERE snapshot_id = @snap AND tur = 'FORCED_PLAN') AS forced_plan_sayisi,
       (SELECT COUNT(*) FROM dbo.qs_failover_envanter WHERE snapshot_id = @snap AND tur = 'HINT') AS hint_sayisi,
       @qs_kuyruk_var AS qs_kuyruk_izleniyor,
       @flush_ms AS flush_ms;
SELECT * FROM @sorun;
