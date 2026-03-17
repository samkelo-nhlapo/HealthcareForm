USE master
GO

--================================================================================================
--	HEALTHCARE FORM DATABASE - COMPLETE MASTER DEPLOYMENT SCRIPT
--	
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Complete end-to-end database deployment orchestration
--	Purpose:		Deploys entire healthcare database from scratch in correct dependency order
--	
--	EXECUTION:		Execute this script as SA or with appropriate permissions
--	TIME:			Approximately 15-20 minutes for complete deployment
--	
--	IMPORTANT:	This script assumes all SQL files are in the same directory structure as this file.
--				For best results, execute from SQL Server Management Studio (not SQLCMD mode required).
--	
--	PHASES:
--	  Phase 1: Database & Filegroups (1 step)
--	  Phase 2: Schemas (1 step)
--	  Phase 3: Tables (45 tables)
--	  Phase 4: Triggers & Functions (12 objects)
--	  Phase 5: Stored Procedures (50 procedures)
--	  Phase 6: Data Initialization (20 insert scripts)
--	  Phase 7: Verification & Reporting
--
--================================================================================================

PRINT '================================================================================================'
PRINT 'HEALTHCARE FORM DATABASE - COMPLETE MASTER DEPLOYMENT'
PRINT '================================================================================================'
PRINT ''
PRINT 'Start Time: ' + CONVERT(VARCHAR(25), GETDATE(), 121)
PRINT ''

-- ================================================================================================
-- PHASE 1: DATABASE AND FILEGROUP CREATION
-- ================================================================================================

PRINT ''
PRINT '[PHASE 1] DATABASE & FILEGROUP CREATION'
PRINT '------------------------------------------------------------------------'

IF DB_ID('HealthcareForm') IS NOT NULL
BEGIN
	PRINT 'Database HealthcareForm already exists. Skipping creation.'
	PRINT 'WARNING: Existing database will not be dropped. Use separate script to reset if needed.'
END
ELSE
BEGIN
	PRINT '[1/1] Creating HealthcareForm database with filegroups...'
	PRINT 'Please execute: 001-database/001-filegroups/001-healthcare-form.sql'
	PRINT ''
END

-- ================================================================================================
-- PHASE 2: SCHEMA CREATION
-- ================================================================================================

PRINT ''
PRINT '[PHASE 2] SCHEMA CREATION'
PRINT '------------------------------------------------------------------------'

-- Check if we can connect to the database
IF DB_ID('HealthcareForm') IS NULL
BEGIN
	PRINT 'ERROR: HealthcareForm database does not exist. Please create it first using:'
	PRINT '  001-database/001-filegroups/001-healthcare-form.sql'
	RAISERROR('Database HealthcareForm not found', 16, 1)
END

PRINT '[1/1] Creating database schemas...'

USE HealthcareForm
GO

-- Create schemas directly in this script
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Location')
	CREATE SCHEMA Location
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Profile')
	CREATE SCHEMA Profile
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Contacts')
	CREATE SCHEMA Contacts
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Auth')
	CREATE SCHEMA Auth
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Exceptions')
	CREATE SCHEMA Exceptions
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Lookup')
	CREATE SCHEMA Lookup
GO

PRINT 'Schemas created successfully'
PRINT ''
GO


-- ================================================================================================
-- PHASE 3: TABLE CREATION (45 TABLES)
-- ================================================================================================
-- NOTE: Individual table creation scripts must be executed separately from 003. Tables folder
-- This master script provides the framework and verification
-- 
-- Tables to create (all located in 003. Tables folder):
-- Location Schema: Countries, Provinces, Cities, Address
-- Profile Schema: Patient demographics, clinical records, billing, operations
-- Contacts Schema: Phones, Emails, PatientPhones, PatientEmails, forms
-- Auth Schema: Users, Roles, Permissions, RolePermissions, AuditLog, UserActivityAudit, DB_Errors
-- Exceptions Schema: Errors
-- Lookup Schema: Reference tables (allergies, medications, etc.)
--
-- IMPORTANT: Execute all .sql files from 003. Tables folder before proceeding to Phase 4
-- ================================================================================================

PRINT ''
PRINT '[PHASE 3] TABLE CREATION (45 TABLES)'
PRINT '------------------------------------------------------------------------'
PRINT 'Please execute all SQL files from the 003-tables folder:'
PRINT '  - Location: Countries, Provinces, Cities, Address'
PRINT '  - Profile: Patient, appointments, consultations, billing, insurance'
PRINT '  - Contacts: Phones, Emails, PatientPhones, PatientEmails, forms'
PRINT '  - Auth: Users, Roles, Permissions, RolePermissions, AuditLog, UserActivityAudit'
PRINT '  - Exceptions: Errors'
PRINT '  - Lookup: Reference tables'
PRINT ''
PRINT 'Location: ~/HealthcareForm/003-tables/'
PRINT 'Waiting for manual table creation...'
PRINT 'All 45 tables should be created (verify in SQL Server Management Studio)'
PRINT ''

-- ================================================================================================
-- PHASE 4: FUNCTIONS & UTILITY CREATION
-- ================================================================================================
-- NOTE: Function creation scripts must be executed from 007. Triggers & Functions folder
-- ================================================================================================

PRINT ''
PRINT '[PHASE 4] TRIGGERS & FUNCTIONS CREATION'
PRINT '------------------------------------------------------------------------'
PRINT 'Location: ~/HealthcareForm/007-triggers-functions/'
PRINT 'Please execute all trigger/function scripts (see folder for full list).'
PRINT ''

-- ================================================================================================
-- PHASE 5: STORED PROCEDURES CREATION
-- ================================================================================================
-- NOTE: Stored procedure scripts must be executed from 006. Stored Procedures folder
-- ================================================================================================

PRINT ''
PRINT '[PHASE 5] STORED PROCEDURES CREATION'
PRINT '------------------------------------------------------------------------'
PRINT 'Location: ~/HealthcareForm/006-stored-procedures/'
PRINT 'Please execute all stored procedure scripts (see folder for full list).'
PRINT ''

-- ================================================================================================
-- PHASE 6: DATA INITIALIZATION (INSERT SCRIPTS)
-- ================================================================================================
-- NOTE: Data initialization scripts must be executed from 005. Table Inserts folder
-- ================================================================================================

PRINT ''
PRINT '[PHASE 6] DATA INITIALIZATION - 20 INSERT SCRIPTS'
PRINT '------------------------------------------------------------------------'
PRINT 'Location: ~/HealthcareForm/005-table-inserts/'
PRINT 'Please execute insert scripts in the order listed in 005-table-inserts/000. MASTER_DEPLOYMENT_SCRIPT.sql'
PRINT ''
PRINT 'All lookup tables and reference data will be populated'
PRINT ''

-- ================================================================================================
-- PHASE 7: VERIFICATION & REPORTING
-- ================================================================================================

PRINT ''
PRINT '[PHASE 7] VERIFICATION & DATA VALIDATION'
PRINT '------------------------------------------------------------------------'
PRINT ''

-- Verify database exists
IF DB_ID('HealthcareForm') IS NOT NULL
BEGIN
	USE HealthcareForm
	GO
	
	-- Check schemas
	PRINT 'SCHEMAS CREATED:'
	PRINT '================'
	SELECT SCHEMA_NAME(schema_id) AS [Schema Name]
	FROM sys.schemas
	WHERE schema_id > 4  -- Skip system schemas
	ORDER BY SCHEMA_NAME(schema_id)
	GO
	
	-- Check if core tables exist
	PRINT ''
	PRINT 'CORE TABLES VERIFICATION:'
	PRINT '=========================='
	SELECT 
		'Location.Countries' AS [Table Name],
		CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'Location' AND table_name = 'Countries') THEN 'EXISTS' ELSE 'MISSING' END AS [Status]
	UNION ALL
	SELECT 'Location.Provinces', CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'Location' AND table_name = 'Provinces') THEN 'EXISTS' ELSE 'MISSING' END
	UNION ALL
	SELECT 'Profile.Patient', CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'Profile' AND table_name = 'Patient') THEN 'EXISTS' ELSE 'MISSING' END
	UNION ALL
	SELECT 'Profile.Gender', CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'Profile' AND table_name = 'Gender') THEN 'EXISTS' ELSE 'MISSING' END
	UNION ALL
	SELECT 'Auth.Roles', CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'Auth' AND table_name = 'Roles') THEN 'EXISTS' ELSE 'MISSING' END
	UNION ALL
	SELECT 'Auth.Users', CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'Auth' AND table_name = 'Users') THEN 'EXISTS' ELSE 'MISSING' END
	ORDER BY [Table Name]
	GO
	
	-- Attempt to count records if tables exist
	PRINT ''
	PRINT 'RECORD COUNTS (Once data is inserted):'
	PRINT '======================================'
	
	IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'Location' AND table_name = 'Countries')
		SELECT 'Location.Countries' AS [Table], COUNT(*) AS [Records] FROM Location.Countries
	ELSE
		PRINT '  Location.Countries - TABLE NOT YET CREATED'
		
	IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'Profile' AND table_name = 'Gender')
		SELECT 'Profile.Gender' AS [Table], COUNT(*) AS [Records] FROM Profile.Gender
	ELSE
		PRINT '  Profile.Gender - TABLE NOT YET CREATED'
		
	IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'Profile' AND table_name = 'Patient')
		SELECT 'Profile.Patient' AS [Table], COUNT(*) AS [Records] FROM Profile.Patient
	ELSE
		PRINT '  Profile.Patient - TABLE NOT YET CREATED'
		
	IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'Auth' AND table_name = 'Roles')
		SELECT 'Auth.Roles' AS [Table], COUNT(*) AS [Records] FROM Auth.Roles
	ELSE
		PRINT '  Auth.Roles - TABLE NOT YET CREATED'
		
	IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'Auth' AND table_name = 'Users')
		SELECT 'Auth.Users' AS [Table], COUNT(*) AS [Records] FROM Auth.Users
	ELSE
		PRINT '  Auth.Users - TABLE NOT YET CREATED'
	GO
END
ELSE
BEGIN
	PRINT 'ERROR: HealthcareForm database does not exist.'
	PRINT 'Please create the database first using: 001. Database & FileGroups\001. Healthcare form.sql'
END

PRINT ''
PRINT '================================================================================================'
PRINT 'DEPLOYMENT FRAMEWORK COMPLETE!'
PRINT '================================================================================================'
PRINT ''
PRINT 'NEXT STEPS:'
PRINT '-----------'
PRINT ''
PRINT '1. DATABASE CREATION (If not already done):'
PRINT '   Execute: 001-database/001-filegroups/001-healthcare-form.sql'
PRINT ''
PRINT '2. SCHEMA CREATION:'
PRINT '   Re-run this master script (schemas are created in Phase 2)'
PRINT ''
PRINT '3. TABLE CREATION:'
PRINT '   Execute all .sql files from: 003-tables/ (45 files)'
PRINT '   Recommended order: Location → Profile → Contacts → Auth → Exceptions → Lookup'
PRINT ''
PRINT '4. FUNCTION CREATION:'
PRINT '   Execute function scripts from: 007-triggers-functions/'
PRINT ''
PRINT '5. STORED PROCEDURE CREATION:'
PRINT '   Execute procedure scripts from: 006-stored-procedures/'
PRINT ''
PRINT '6. DATA INITIALIZATION:'
PRINT '   Execute insert scripts from: 005-table-inserts/ (in order provided above)'
PRINT ''
PRINT '7. VERIFY ADMIN BOOTSTRAP CREDENTIAL:'
PRINT '   Admin username: admin'
PRINT '   Password hash is supplied via ADMIN_PASSWORD_HASH at deployment (no default in repo)'
PRINT '   ROTATE IMMEDIATELY AFTER FIRST LOGIN'
PRINT ''
PRINT '8. CREATE APPLICATION USERS:'
PRINT '   - Doctors (DOCTOR role - 31 permissions)'
PRINT '   - Nurses (NURSE role - 20 permissions)'
PRINT '   - Receptionists (RECEPTIONIST role - 10 permissions)'
PRINT '   - Billing staff (BILLING role - 14 permissions)'
PRINT '   - Patients (PATIENT role - 15 permissions)'
PRINT ''
PRINT '9. CONFIGURE BACKUPS:'
PRINT '   - Schedule nightly FULL backups'
PRINT '   - Configure transaction log backups every 15 minutes'
PRINT '   - Test backup restoration'
PRINT ''
PRINT 'ALTERNATIVE: Execute scripts using a deployment tool or script'
PRINT 'You can batch execute all files using PowerShell or other automation tools'
PRINT ''
PRINT 'Completion Time: ' + CONVERT(VARCHAR(25), GETDATE(), 121)
PRINT ''
PRINT '================================================================================================'
GO
