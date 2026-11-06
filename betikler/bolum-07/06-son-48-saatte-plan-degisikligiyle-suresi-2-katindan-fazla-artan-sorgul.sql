-- Query Store Basucu Rehberi, Bolum 7
-- son 48 saatte plan degisikligiyle suresi 2 katindan fazla artan sorgular
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT qt.query_sql_text, q.query_id,
       rs1.avg_duration AS ort_sure_1_us, p1.plan_id AS plan_1, rsi1.start_time AS aralik_1,
       rs2.avg_duration AS ort_sure_2_us, p2.plan_id AS plan_2, rsi2.start_time AS aralik_2
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q   ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p1   ON q.query_id = p1.query_id
JOIN sys.query_store_runtime_stats AS rs1 ON p1.plan_id = rs1.plan_id
JOIN sys.query_store_runtime_stats_interval AS rsi1 ON rsi1.runtime_stats_interval_id = rs1.runtime_stats_interval_id
JOIN sys.query_store_plan AS p2   ON q.query_id = p2.query_id
JOIN sys.query_store_runtime_stats AS rs2 ON p2.plan_id = rs2.plan_id
JOIN sys.query_store_runtime_stats_interval AS rsi2 ON rsi2.runtime_stats_interval_id = rs2.runtime_stats_interval_id
WHERE rsi1.start_time > DATEADD(HOUR, -48, GETUTCDATE())
  AND rsi2.start_time > rsi1.start_time
  AND p1.plan_id <> p2.plan_id
  AND rs2.avg_duration > 2 * rs1.avg_duration
ORDER BY q.query_id, rsi1.start_time, rsi2.start_time;
