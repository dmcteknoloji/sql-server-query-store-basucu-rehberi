-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Secondary replica doğrulaması ve geri basınç'
-- Yalnizca test ortaminda calistirin.

SET NOCOUNT ON;
USE qs_lab_ag;
GO
SELECT COUNT_BIG(*) AS adet FROM dbo.AgIzleme WHERE deger = 424242;
GO 60
