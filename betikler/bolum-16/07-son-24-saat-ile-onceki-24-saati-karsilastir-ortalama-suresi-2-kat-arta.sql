-- SQL Server Query Store Basucu Rehberi, Bolum 16
-- son 24 saat ile onceki 24 saati karsilastir, ortalama suresi 2 kat artanlar
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

WITH son AS (
  SELECT p.query_id, SUM(rs.avg_duration * rs.count_executions) / NULLIF(SUM(rs.count_executions), 0) AS ort_us,
         SUM(rs.count_executions) AS adet
  FROM sys.query_store_runtime_stats AS rs
  JOIN sys.query_store_plan AS p ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval AS i ON i.runtime_stats_interval_id = rs.runtime_stats_interval_id
  WHERE i.start_time >= DATEADD(HOUR, -24, SYSUTCDATETIME())
  GROUP BY p.query_id
), onceki AS (
  SELECT p.query_id, SUM(rs.avg_duration * rs.count_executions) / NULLIF(SUM(rs.count_executions), 0) AS ort_us,
         SUM(rs.count_executions) AS adet
  FROM sys.query_store_runtime_stats AS rs
  JOIN sys.query_store_plan AS p ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval AS i ON i.runtime_stats_interval_id = rs.runtime_stats_interval_id
  WHERE i.start_time >= DATEADD(HOUR, -48, SYSUTCDATETIME()) AND i.start_time < DATEADD(HOUR, -24, SYSUTCDATETIME())
  GROUP BY p.query_id
)
SELECT s.query_id, o.adet AS onceki_adet, s.adet AS son_adet,
       CAST(o.ort_us / 1000.0 AS decimal(18,2)) AS onceki_ort_ms,
       CAST(s.ort_us / 1000.0 AS decimal(18,2)) AS son_ort_ms,
       CAST(s.ort_us / NULLIF(o.ort_us, 0) AS decimal(10,2)) AS kat_artisi
FROM son AS s JOIN onceki AS o ON o.query_id = s.query_id
WHERE s.ort_us > 2 * o.ort_us
ORDER BY (s.ort_us - o.ort_us) * s.adet DESC;
