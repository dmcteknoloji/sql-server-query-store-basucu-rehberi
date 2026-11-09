-- SQL Server Query Store Basucu Rehberi, Bolum 12, 'Canlı doğrulama, iki düğümlü Availability Group'
-- Yalnizca test ortaminda calistirin.

ALTER DATABASE [VeritabaniAdi] FOR SECONDARY
SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
