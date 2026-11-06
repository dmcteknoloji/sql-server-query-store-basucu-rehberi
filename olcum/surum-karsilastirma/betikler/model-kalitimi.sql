SET NOCOUNT ON;
PRINT '##### M0 SURUM';
SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar(40)) AS surum;
GO
CREATE DATABASE eski_db;
GO
PRINT '##### M1 model ayari yeni veritabanina yansiyor mu';
SELECT 'model baslangic' AS an, is_query_store_on FROM sys.databases WHERE name = 'model';
GO
ALTER DATABASE model SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, MAX_STORAGE_SIZE_MB = 512, INTERVAL_LENGTH_MINUTES = 30);
GO
CREATE DATABASE yeni_acik;
GO
SELECT 'model ON sonrasi yeni veritabani' AS an, d.name, d.is_query_store_on FROM sys.databases d WHERE d.name IN ('eski_db','yeni_acik') ORDER BY d.name;
GO
USE yeni_acik;
GO
SELECT actual_state_desc, max_storage_size_mb, interval_length_minutes FROM sys.database_query_store_options;
GO
USE master;
GO
ALTER DATABASE model SET QUERY_STORE = OFF;
GO
CREATE DATABASE yeni_kapali;
GO
SELECT 'model OFF sonrasi' AS an, d.name, d.is_query_store_on FROM sys.databases d WHERE d.name IN ('eski_db','yeni_acik','yeni_kapali') ORDER BY d.name;
GO
PRINT '##### BITTI';
