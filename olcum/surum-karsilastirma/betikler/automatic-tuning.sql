SET NOCOUNT ON;
PRINT '##### A0 SURUM';
SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar(40)) AS surum;
GO
IF DB_ID('qs_demo') IS NOT NULL BEGIN ALTER DATABASE qs_demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE qs_demo; END
CREATE DATABASE qs_demo;
GO
USE qs_demo;
GO
PRINT '##### A1 AUTOMATIC TUNING VARSAYILAN';
SELECT name, desired_state_desc, actual_state_desc, reason_desc FROM sys.database_automatic_tuning_options;
GO
ALTER DATABASE qs_demo SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
ALTER DATABASE qs_demo SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = ON);
GO
PRINT '##### A2 AUTOMATIC TUNING ACIK, QUERY STORE ACIK';
SELECT name, desired_state_desc, actual_state_desc, reason_desc FROM sys.database_automatic_tuning_options;
GO
ALTER DATABASE qs_demo SET QUERY_STORE = OFF;
GO
PRINT '##### A3 AUTOMATIC TUNING ACIK, QUERY STORE KAPALI';
SELECT name, desired_state_desc, actual_state_desc, reason_desc FROM sys.database_automatic_tuning_options;
GO
PRINT '##### A4 TUNING ONERILERI GORUNUMU';
SELECT COUNT(*) AS oneri_sayisi FROM sys.dm_db_tuning_recommendations;
GO
PRINT '##### BITTI';
