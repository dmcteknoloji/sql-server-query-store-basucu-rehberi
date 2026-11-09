-- SQL Server Query Store Handbook, Chapter 18, 'Secondary replica verification and backpressure'
-- Run in a test environment only.

SET NOCOUNT ON;
USE qs_lab_ag;
GO
SELECT COUNT_BIG(*) AS adet FROM dbo.AgIzleme WHERE deger = 424242;
GO 60
