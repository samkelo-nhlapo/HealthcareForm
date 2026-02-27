-- ================================================================================================
-- 000_PRODUCTION_SYNC.sql
-- Production-safe sync for an existing HealthcareForm database.
--
-- Design goals:
-- 1) No CREATE DATABASE / ALTER DATABASE option changes.
-- 2) No direct execution of migration scripts (Flyway is the source of truth).
-- 3) No sample/provider seeds and no admin bootstrap creation.
--
-- Preconditions:
-- - Run Flyway migrations first (through V10 in this repository).
-- - Run in SQLCMD mode (`sqlcmd` CLI or SSMS SQLCMD mode enabled).
-- ================================================================================================

IF DB_ID('HealthcareForm') IS NULL
    THROW 50010, 'HealthcareForm database does not exist. Use bootstrap deployment for new environments.', 1;
GO

USE HealthcareForm;
GO

IF OBJECT_ID(N'[dbo].[flyway_schema_history]', N'U') IS NULL
    THROW 50011, 'Flyway history table is missing. Run Flyway migrations before production sync.', 1;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.flyway_schema_history
    WHERE success = 1
      AND [script] = 'V10__staff_designations_and_departments.sql'
)
    THROW 50012, 'Flyway migration V10 is not applied. Run Flyway migrate before production sync.', 1;
GO

PRINT '================================================================================================';
PRINT 'HealthcareForm - Production Safe Sync';
PRINT 'Started: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT '================================================================================================';
GO

-- ------------------------------------------------------------------------------------------------
-- 1) DDL/object sync (idempotent)
-- ------------------------------------------------------------------------------------------------
:r 002-schema/001_schema_script.sql
:r 003-tables/000. MASTER_DEPLOYMENT_SCRIPT.sql
:r 006-stored-procedures/000. MASTER_DEPLOYMENT_SCRIPT.sql
:r 007-triggers-functions/000. MASTER_DEPLOYMENT_SCRIPT.sql

-- ------------------------------------------------------------------------------------------------
-- 2) Safe reference/master seed sync (idempotent, no sample providers/admin bootstrap)
-- ------------------------------------------------------------------------------------------------
:r 005-table-inserts/005. Insert Countries.sql
:r 005-table-inserts/006. Insert Provinces.sql
:r 005-table-inserts/007. Insert Cities.sql
:r 005-table-inserts/Insert Gender.sql
:r 005-table-inserts/Insert Merital Status.sql
:r 005-table-inserts/017. Insert ClientClinicCategories.sql
:r 005-table-inserts/011. Insert BillingCodes.sql
:r 005-table-inserts/014. Insert Allergies_Medications.sql
:r 005-table-inserts/008. Insert Roles.sql
:r 005-table-inserts/009. Insert Permissions.sql
:r 005-table-inserts/010. Insert RolePermissions.sql

PRINT '================================================================================================';
PRINT 'Production safe sync complete: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT 'Excluded by design: DB create/options, direct migrations, provider/insurance sample seeds, admin bootstrap.';
PRINT '================================================================================================';
GO
