SET NOCOUNT ON;
USE qs_lab_flush;
GO
DECLARE @t0 datetime2(0) = (SELECT MIN(sn) FROM dbo.o_sonuc);
SELECT x.k * 15 AS sn_basi, COUNT(*) AS saniye, CAST(AVG(1.0 * x.q) AS decimal(9,0)) AS ort_sorgu_sn, CAST(SUM(x.d_mb) AS decimal(9,1)) AS yazilan_mb, MAX(x.qs_mb) AS qs_mb,
  CAST(AVG(x.pr_p50_ms) AS decimal(9,3)) AS probe_p50_ms, CAST(AVG(x.pr_p99_ms) AS decimal(9,3)) AS probe_p99_ms, CAST(MAX(x.pr_max_ms) AS decimal(9,2)) AS probe_max_ms,
  CAST(MAX(x.disk_kuyruk) AS decimal(9,2)) AS disk_kuyruk_max, CAST(MAX(x.disk_yazma_ms) AS decimal(9,2)) AS disk_yazma_ms_max, SUM(x.d_writelog) AS writelog_ms
FROM (SELECT DATEDIFF(SECOND, @t0, sn) / 15 AS k, * FROM dbo.o_sonuc) x GROUP BY x.k ORDER BY x.k;
SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ms) OVER () AS tum_probe_p50, PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ms) OVER () AS tum_probe_p99, COUNT(*) OVER () AS probe_sayisi FROM dbo.o_probe;
GO
