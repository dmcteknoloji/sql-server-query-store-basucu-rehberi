-- Query Store Basucu Rehberi, Bolum 9
-- plan cache ne kadar eski
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT (SELECT sqlserver_start_time FROM sys.dm_os_sys_info) AS sunucu_baslangic,
       MIN(creation_time) AS en_eski_plan, MAX(creation_time) AS en_yeni_plan, COUNT(*) AS plan_sayisi
FROM sys.dm_exec_query_stats;
