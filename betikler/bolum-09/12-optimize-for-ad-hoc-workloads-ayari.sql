-- SQL Server Query Store Basucu Rehberi, Bolum 9
-- optimize for ad hoc workloads ayari
-- Test ortaminda calistirin. Ornek veritabani icin betikler/00-demo-veritabani.sql dosyasina bakin.

SELECT name, value, value_in_use FROM sys.configurations WHERE name = N'optimize for ad hoc workloads';
