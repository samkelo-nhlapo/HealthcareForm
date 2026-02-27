-- ================================================================================================
-- 000_MODULAR_MASTER_DEPLOYMENT.sql
-- One-command modular deployment for HealthcareForm.
--
-- Requirements:
-- 1) Run with SQLCMD mode (`sqlcmd` CLI or SSMS SQLCMD mode enabled).
-- 2) Provide ADMIN_PASSWORD_HASH when bootstrapping first admin user:
--      sqlcmd -S <server> -U <user> -P "<pass>" -v ADMIN_PASSWORD_HASH="<bcrypt hash>" -i "000_MODULAR_MASTER_DEPLOYMENT.sql"
-- ================================================================================================

-- ------------------------------------------------------------------------------------------------
-- 1) Create database if missing (idempotent)
-- ------------------------------------------------------------------------------------------------
IF DB_ID('HealthcareForm') IS NULL
BEGIN
    CREATE DATABASE HealthcareForm
    ON PRIMARY
      (
        NAME='HealthcareForm_Primary',
        FILENAME='/var/opt/mssql/data/healthcare-form-primary.mdf',
        SIZE=500MB,
        MAXSIZE=5GB,
        FILEGROWTH=100MB
      ),
    FILEGROUP PatientDataGroup
      (
        NAME='PatientData_File1',
        FILENAME='/var/opt/mssql/data/healthcare-form-patient-data-1.ndf',
        SIZE=1GB,
        MAXSIZE=10GB,
        FILEGROWTH=100MB
      ),
      (
        NAME='PatientData_File2',
        FILENAME='/var/opt/mssql/data/healthcare-form-patient-data-2.ndf',
        SIZE=1GB,
        MAXSIZE=10GB,
        FILEGROWTH=100MB
      )
    LOG ON
      (
        NAME='HealthcareForm_Log',
        FILENAME='/var/opt/mssql/data/healthcare-form.ldf',
        SIZE=500MB,
        MAXSIZE=5GB,
        FILEGROWTH=100MB
      );
END
GO

IF DB_ID('HealthcareForm') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM HealthcareForm.sys.filegroups
        WHERE name = 'PatientDataGroup'
          AND is_default = 0
    )
        ALTER DATABASE HealthcareForm MODIFY FILEGROUP PatientDataGroup DEFAULT;

    ALTER DATABASE HealthcareForm SET RECOVERY FULL;
    ALTER DATABASE HealthcareForm SET AUTO_UPDATE_STATISTICS ON;
    ALTER DATABASE HealthcareForm SET AUTO_SHRINK OFF;
    ALTER DATABASE HealthcareForm SET PAGE_VERIFY CHECKSUM;
END
GO

PRINT '================================================================================================';
PRINT 'HealthcareForm - Modular Full Deployment';
PRINT 'Started: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT '================================================================================================';
GO

-- ------------------------------------------------------------------------------------------------
-- 2) Schemas, tables, programmable objects
-- ------------------------------------------------------------------------------------------------
:r 002-schema/001_schema_script.sql
:r 003-tables/000. MASTER_DEPLOYMENT_SCRIPT.sql
:r migrations/sql/V9__phase1_scalability_hardening.sql
:r 006-stored-procedures/000. MASTER_DEPLOYMENT_SCRIPT.sql
:r 007-triggers-functions/000. MASTER_DEPLOYMENT_SCRIPT.sql

-- ------------------------------------------------------------------------------------------------
-- 3) Seed lookup/reference/auth data
-- ------------------------------------------------------------------------------------------------
:r 005-table-inserts/005. Insert Countries.sql
:r 005-table-inserts/006. Insert Provinces.sql
:r 005-table-inserts/007. Insert Cities.sql
:r 005-table-inserts/Insert Gender.sql
:r 005-table-inserts/Insert Merital Status.sql
:r 005-table-inserts/017. Insert ClientClinicCategories.sql
:r 005-table-inserts/011. Insert BillingCodes.sql
:r 005-table-inserts/012. Insert HealthcareProviders.sql
:r 005-table-inserts/013. Insert InsuranceProviders.sql
:r 005-table-inserts/014. Insert Allergies_Medications.sql
:r 005-table-inserts/000. MASTER_DEPLOYMENT_SCRIPT.sql

-- Optional test data (disabled by default)
-- :r "005-table-inserts/015. Insert SampleTestData.sql"

PRINT '================================================================================================';
PRINT 'Modular full deployment complete: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT '================================================================================================';
GO
