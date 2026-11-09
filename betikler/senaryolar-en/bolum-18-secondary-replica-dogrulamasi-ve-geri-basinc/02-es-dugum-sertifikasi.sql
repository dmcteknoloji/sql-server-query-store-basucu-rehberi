-- SQL Server Query Store Handbook, Chapter 18, 'Secondary replica verification and backpressure'
-- Run in a test environment only.

SET NOCOUNT ON;
USE master;
CREATE CERTIFICATE hadr_cert_es FROM BINARY = <DIGER_DUGUM_HEX>;
CREATE LOGIN hadr_login_es FROM CERTIFICATE hadr_cert_es;
GRANT CONNECT ON ENDPOINT::hadr_endpoint TO hadr_login_es;
