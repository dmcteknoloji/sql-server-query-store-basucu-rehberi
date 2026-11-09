-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Flush penceresi örnekleyici'
-- Test ortaminda calistirin.

-- Sunucu capinda sayaclar bu oturum disindaki yuku de icerir. Yalniz bu test icin ayrilmis bir sunucuda calistirin.
SET NOCOUNT ON;
DECLARE @flush_spid int = 0;
DECLARE @db sysname = N'qs_lab_flush';
DECLARE @maks_sn int = 1800;
DECLARE @aralik char(8) = '00:00:01';

DROP TABLE IF EXISTS #ornek;
CREATE TABLE #ornek (sn int NOT NULL, kaynak varchar(12) NOT NULL, ad nvarchar(200) NOT NULL,
                     v1 bigint NULL, v2 bigint NULL, v3 bigint NULL, v4 bigint NULL);

DECLARE @sn int = 0, @goruldu bit = 0, @bitti bit = 0, @bas_sn int = NULL, @son_sn int = NULL;
WHILE @bitti = 0 AND @sn <= @maks_sn
BEGIN
    IF @flush_spid = 0 SELECT @flush_spid = ISNULL((SELECT TOP (1) spid FROM qs_lab_flush.dbo.flush_spid), 0);
    INSERT #ornek SELECT @sn, 'spinlock', name, collisions, spins, backoffs, sleep_time
        FROM sys.dm_os_spinlock_stats;
    INSERT #ornek SELECT @sn, 'latch', latch_class, waiting_requests_count, wait_time_ms, NULL, NULL
        FROM sys.dm_os_latch_stats;
    INSERT #ornek SELECT @sn, 'bekleme', wait_type, waiting_tasks_count, wait_time_ms, signal_wait_time_ms, NULL
        FROM sys.dm_os_wait_stats WHERE waiting_tasks_count > 0;
    INSERT #ornek SELECT @sn, 'clerk', type, SUM(pages_kb), NULL, NULL, NULL
        FROM sys.dm_os_memory_clerks WHERE type LIKE N'%QUERYDISKSTORE%' GROUP BY type;
    INSERT #ornek SELECT @sn, 'sayac', RTRIM(counter_name), cntr_value, NULL, NULL, NULL
        FROM sys.dm_os_performance_counters
        WHERE object_name LIKE N'%Query Store%' AND instance_name = @db;
    INSERT #ornek SELECT @sn, 'dosya', mf.type_desc + N' ' + mf.name,
                         vfs.num_of_writes, vfs.io_stall_write_ms, vfs.num_of_bytes_written, vfs.io_stall_read_ms
        FROM sys.dm_io_virtual_file_stats(DB_ID(@db), NULL) AS vfs
        JOIN sys.master_files AS mf ON mf.database_id = vfs.database_id AND mf.file_id = vfs.file_id;
    INSERT #ornek SELECT @sn, 'istek', N'flush ' + ISNULL(r.wait_type, N'-'),
                         r.cpu_time, r.logical_reads, r.writes, r.total_elapsed_time
        FROM sys.dm_exec_requests AS r WHERE r.session_id = @flush_spid;

    IF EXISTS (SELECT 1 FROM sys.dm_exec_requests WHERE session_id = @flush_spid)
    BEGIN
        SET @goruldu = 1; SET @son_sn = @sn;
        IF @bas_sn IS NULL SET @bas_sn = @sn;
    END
    ELSE IF @goruldu = 1 SET @bitti = 1;
    SET @sn += 1;
    IF @bitti = 0 WAITFOR DELAY @aralik;
END

SELECT @bas_sn AS pencere_bas_sn, @son_sn AS pencere_son_sn, @son_sn - @bas_sn AS yaklasik_sure_sn;

-- Rapor 1, spinlock farki (pencere basi ile sonu)
SELECT TOP (15) e.ad AS spinlock, e.v1 - b.v1 AS collisions_farki, e.v2 - b.v2 AS spins_farki,
       e.v3 - b.v3 AS backoffs_farki, e.v4 - b.v4 AS sleep_time_farki,
       CASE WHEN e.ad LIKE N'%QUERY%STORE%' OR e.ad LIKE N'%QDS%' THEN N'QS ilgili' ELSE N'' END AS isaret
FROM #ornek AS b JOIN #ornek AS e ON e.kaynak = b.kaynak AND e.ad = b.ad
WHERE b.kaynak = 'spinlock' AND b.sn = @bas_sn AND e.sn = @son_sn
ORDER BY e.v2 - b.v2 DESC;

-- Rapor 2, en yuksek tek saniyelik spin artisi
SELECT TOP (10) ad AS spinlock, MAX(d) AS en_yuksek_saniye_spin_artisi
FROM (SELECT ad, v2 - LAG(v2) OVER (PARTITION BY ad ORDER BY sn) AS d
      FROM #ornek WHERE kaynak = 'spinlock' AND sn BETWEEN @bas_sn AND @son_sn) AS z
GROUP BY ad ORDER BY 2 DESC;

-- Rapor 3, latch ve bekleme farki (ilk 10)
SELECT TOP (10) e.kaynak, e.ad, e.v1 - b.v1 AS bekleyen_sayisi_farki, e.v2 - b.v2 AS bekleme_ms_farki
FROM #ornek AS b JOIN #ornek AS e ON e.kaynak = b.kaynak AND e.ad = b.ad
WHERE b.kaynak IN ('latch', 'bekleme') AND b.sn = @bas_sn AND e.sn = @son_sn
ORDER BY e.v2 - b.v2 DESC;

-- Rapor 4, Query Store bellek clerk'i buyumesi ve QS sayaclari
SELECT e.kaynak, e.ad, b.v1 AS pencere_basi, e.v1 AS pencere_sonu, e.v1 - b.v1 AS fark
FROM #ornek AS b JOIN #ornek AS e ON e.kaynak = b.kaynak AND e.ad = b.ad
WHERE b.kaynak IN ('clerk', 'sayac') AND b.sn = @bas_sn AND e.sn = @son_sn ORDER BY e.kaynak, e.ad;

-- Rapor 5, flush oturumunun kendi CPU, okuma ve bekleme dagilimi
SELECT ad AS bekleme_turu, COUNT(*) AS ornek_sayisi, MAX(v1) AS cpu_ms, MAX(v2) AS logical_reads, MAX(v3) AS writes
FROM #ornek WHERE kaynak = 'istek' GROUP BY ad ORDER BY ornek_sayisi DESC;

-- Rapor 6, disk tarafi (WRITELOG ve veri dosyasi)
SELECT e.ad AS dosya, e.v1 - b.v1 AS yazma_sayisi, e.v2 - b.v2 AS yazma_bekleme_ms, (e.v3 - b.v3) / 1048576 AS yazilan_mb
FROM #ornek AS b JOIN #ornek AS e ON e.kaynak = b.kaynak AND e.ad = b.ad
WHERE b.kaynak = 'dosya' AND b.sn = @bas_sn AND e.sn = @son_sn;
