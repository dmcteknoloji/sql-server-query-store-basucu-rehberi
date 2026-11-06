SET NOCOUNT ON;
USE qs_lab_flush;
GO
DELETE dbo.o_faz;
WITH s AS (SELECT DISTINCT sn FROM dbo.o_tput), g AS (SELECT sn, LAG(sn) OVER (ORDER BY sn) AS onceki FROM s),
b AS (SELECT MIN(sn) AS d_bas, (SELECT onceki FROM g WHERE sn = (SELECT MIN(sn) FROM g WHERE DATEDIFF(SECOND, onceki, sn) > 3)) AS c_bit FROM g WHERE DATEDIFF(SECOND, onceki, sn) > 3)
INSERT dbo.o_faz SELECT 'C', (SELECT MIN(sn) FROM dbo.o_tput), c_bit FROM b UNION ALL SELECT 'D', d_bas, (SELECT MAX(sn) FROM dbo.o_tput) FROM b;
GO
USE qs_lab_flush;
GO
TRUNCATE TABLE dbo.o_probe; TRUNCATE TABLE dbo.o_disk;
BULK INSERT dbo.o_probe FROM 'C:\qs\fl_probe.csv' WITH (FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');
BULK INSERT dbo.o_disk FROM 'C:\qs\fl_disk.csv' WITH (FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');
GO
PRINT '#### 0. fazlar';
SELECT ad, bas, bit, DATEDIFF(SECOND, bas, bit) AS sure_sn FROM dbo.o_faz ORDER BY bas;
PRINT '#### 1. Faz B, elle flush ve checkpoint';
SELECT adim, sure_ms, yazma_adedi, yazilan_mb, stall_ms, qs_mb, kirli_sayfa FROM dbo.o_fazb;
GO
DROP TABLE IF EXISTS dbo.o_sonuc;
DECLARE @bas datetime2(0) = (SELECT bas FROM dbo.o_faz WHERE ad = 'C'), @bit datetime2(0) = (SELECT bit FROM dbo.o_faz WHERE ad = 'C');
SELECT i.sn,
  i.yazma - LAG(i.yazma) OVER (ORDER BY i.sn) AS d_yazma,
  CAST((i.bayt - LAG(i.bayt) OVER (ORDER BY i.sn)) / 1048576.0 AS decimal(12,2)) AS d_mb,
  i.stall_ms - LAG(i.stall_ms) OVER (ORDER BY i.sn) AS d_stall_ms,
  i.qs_mb, i.bekleyen_io,
  i.w_pageiolatch - LAG(i.w_pageiolatch) OVER (ORDER BY i.sn) AS d_pageiolatch,
  i.w_writelog - LAG(i.w_writelog) OVER (ORDER BY i.sn) AS d_writelog,
  i.w_qds - LAG(i.w_qds) OVER (ORDER BY i.sn) AS d_qds,
  i.w_qds_persist - LAG(i.w_qds_persist) OVER (ORDER BY i.sn) AS d_qds_persist,
  i.w_io_comp - LAG(i.w_io_comp) OVER (ORDER BY i.sn) AS d_io_comp,
  i.w_chkpt - LAG(i.w_chkpt) OVER (ORDER BY i.sn) AS d_chkpt
INTO #io FROM dbo.o_io i WHERE i.sn BETWEEN @bas AND DATEADD(SECOND, 5, @bit);
SELECT sn, SUM(n) AS q INTO #tp FROM dbo.o_tput WHERE sn BETWEEN @bas AND @bit GROUP BY sn;
SELECT DISTINCT sn,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ms) OVER (PARTITION BY sn) AS p50,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ms) OVER (PARTITION BY sn) AS p99,
  MAX(ms) OVER (PARTITION BY sn) AS mx, COUNT(*) OVER (PARTITION BY sn) AS adet
INTO #pr FROM dbo.o_probe;
SELECT sn, MAX(kuyruk) AS kuyruk, MAX(yazma_ms) AS yazma_ms, MAX(mbps) AS mbps, MAX(iops) AS iops INTO #dk FROM dbo.o_disk GROUP BY sn;
SELECT io.sn, io.d_yazma, io.d_mb, io.d_stall_ms, io.qs_mb, io.bekleyen_io, io.d_pageiolatch, io.d_writelog, io.d_qds, io.d_qds_persist, io.d_io_comp, io.d_chkpt,
       tp.q, CAST(pr.p50 AS decimal(9,3)) AS pr_p50_ms, CAST(pr.p99 AS decimal(9,3)) AS pr_p99_ms, CAST(pr.mx AS decimal(9,3)) AS pr_max_ms, pr.adet AS pr_adet,
       CAST(dk.kuyruk AS decimal(9,2)) AS disk_kuyruk, CAST(dk.yazma_ms AS decimal(9,2)) AS disk_yazma_ms, CAST(dk.mbps AS decimal(9,2)) AS disk_mbps, CAST(dk.iops AS decimal(9,0)) AS disk_iops
INTO dbo.o_sonuc
FROM #io io LEFT JOIN #tp tp ON tp.sn = io.sn LEFT JOIN #pr pr ON pr.sn = io.sn LEFT JOIN #dk dk ON dk.sn = io.sn WHERE io.d_mb IS NOT NULL;
GO
PRINT '#### 2. Faz C, flush saniyeleri (saniyede 5 MB ve uzeri yazma) ve komsu saniyeler';
SELECT s.sn, s.d_yazma, s.d_mb, s.d_stall_ms, s.qs_mb, s.q AS sorgu_sn, s.pr_p50_ms, s.pr_p99_ms, s.pr_max_ms, s.disk_kuyruk, s.disk_yazma_ms, s.disk_mbps, s.disk_iops, s.d_pageiolatch, s.d_writelog, s.d_qds, s.d_io_comp, s.d_chkpt
FROM dbo.o_sonuc s WHERE EXISTS (SELECT 1 FROM dbo.o_sonuc f WHERE f.d_mb >= 5 AND ABS(DATEDIFF(SECOND, f.sn, s.sn)) <= 2) ORDER BY s.sn;
PRINT '#### 3. Faz C ozet, flush saniyeleri ve digerleri';
SELECT CASE WHEN d_mb >= 5 THEN 'flush saniyesi' ELSE 'diger' END AS grup, COUNT(*) AS saniye,
  CAST(AVG(1.0 * q) AS decimal(12,1)) AS ort_sorgu_sn, MIN(q) AS en_az_sorgu_sn,
  CAST(AVG(pr_p50_ms) AS decimal(9,3)) AS ort_probe_p50_ms, CAST(AVG(pr_p99_ms) AS decimal(9,3)) AS ort_probe_p99_ms, CAST(MAX(pr_max_ms) AS decimal(9,3)) AS en_yuksek_probe_ms,
  CAST(MAX(disk_kuyruk) AS decimal(9,2)) AS en_yuksek_disk_kuyruk, CAST(MAX(disk_yazma_ms) AS decimal(9,2)) AS en_yuksek_disk_yazma_ms, CAST(MAX(d_mb) AS decimal(12,2)) AS en_yuksek_mb_sn,
  SUM(d_pageiolatch) AS pageiolatch_ms, SUM(d_writelog) AS writelog_ms, SUM(d_qds) AS qds_ms, SUM(d_qds_persist) AS qds_persist_sleep_ms, SUM(d_io_comp) AS io_comp_ms, SUM(d_chkpt) AS chkpt_ms
FROM dbo.o_sonuc GROUP BY CASE WHEN d_mb >= 5 THEN 'flush saniyesi' ELSE 'diger' END;
PRINT '#### 4. Faz C genel';
SELECT COUNT(*) AS saniye, CAST(SUM(d_mb) AS decimal(12,1)) AS toplam_yazilan_mb, MIN(qs_mb) AS qs_mb_bas, MAX(qs_mb) AS qs_mb_son, SUM(q) AS toplam_sorgu, CAST(AVG(1.0 * q) AS decimal(12,1)) AS ort_sorgu_sn, SUM(CASE WHEN d_mb >= 5 THEN 1 ELSE 0 END) AS flush_saniyesi FROM dbo.o_sonuc;
PRINT '#### 5. Faz D, Query Store OFF taban';
SELECT CAST(AVG(1.0 * q) AS decimal(12,1)) AS ort_sorgu_sn_off, MIN(q) AS en_az, MAX(q) AS en_cok, COUNT(*) AS saniye
FROM (SELECT t.sn, SUM(t.n) AS q FROM dbo.o_tput t JOIN dbo.o_faz f ON f.ad = 'D' AND t.sn BETWEEN DATEADD(SECOND, 1, f.bas) AND DATEADD(SECOND, -1, f.bit) GROUP BY t.sn) x;
PRINT '#### 6. bekleme istatistikleri farki (Faz C basindan sonuna)';
SELECT a.wait_type, a.wait_ms - b.wait_ms AS fark_ms, a.sayi - b.sayi AS fark_sayi
FROM dbo.o_wait a JOIN dbo.o_wait b ON b.wait_type = a.wait_type AND b.snap = 'once' WHERE a.snap = 'sonra'
  AND (a.wait_type LIKE 'QDS%' OR a.wait_type LIKE 'PAGEIOLATCH%' OR a.wait_type IN ('WRITELOG', 'IO_COMPLETION', 'ASYNC_IO_COMPLETION', 'CHKPT', 'LOGBUFFER', 'ASYNC_NETWORK_IO'))
  AND a.wait_ms - b.wait_ms > 0 ORDER BY fark_ms DESC;
GO
