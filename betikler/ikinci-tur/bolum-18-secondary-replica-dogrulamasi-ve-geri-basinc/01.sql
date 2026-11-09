-- SQL Server Query Store Basucu Rehberi, Bolum 18, 'Secondary replica doğrulaması ve geri basınç'
-- Test ortaminda calistirin.

USE master;
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##') CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<guclu-bir-parola>';
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'hadr_cert_yerel') CREATE CERTIFICATE hadr_cert_yerel WITH SUBJECT = 'hadr yerel', EXPIRY_DATE = '20301231';
IF NOT EXISTS (SELECT 1 FROM sys.endpoints WHERE name = 'hadr_endpoint')
  CREATE ENDPOINT hadr_endpoint STATE = STARTED AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
  FOR DATABASE_MIRRORING (AUTHENTICATION = CERTIFICATE hadr_cert_yerel, ROLE = ALL, ENCRYPTION = REQUIRED ALGORITHM AES);
-- Sertifikayi 200 karakterlik parcalar halinde oku
DECLARE @h varchar(max) = CONVERT(varchar(max), CERTENCODED(CERT_ID('hadr_cert_yerel')), 1);
SELECT 'C' + RIGHT('000' + CAST(n AS varchar(3)), 3) + '=' + SUBSTRING(@h, (n - 1) * 200 + 1, 200) AS satir
FROM (SELECT TOP ((LEN(@h) + 199) / 200) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) AS x ORDER BY n;
