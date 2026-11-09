-- SQL Server Query Store Handbook, Chapter 12, 'Live verification, two-node Availability Group'
-- Run in a test environment only.

ALTER DATABASE [VeritabaniAdi] FOR SECONDARY
SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
