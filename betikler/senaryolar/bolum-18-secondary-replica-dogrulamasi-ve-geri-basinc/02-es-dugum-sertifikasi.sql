-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Secondary replica doğrulaması ve geri basınç'
-- Yalnizca test ortaminda calistirin.

SET NOCOUNT ON;
USE master;
CREATE CERTIFICATE hadr_cert_es FROM BINARY = <DIGER_DUGUM_HEX>;
CREATE LOGIN hadr_login_es FROM CERTIFICATE hadr_cert_es;
GRANT CONNECT ON ENDPOINT::hadr_endpoint TO hadr_login_es;
