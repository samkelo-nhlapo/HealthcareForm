-- ================================================================================================
-- Healthcare Form Database - Insert Scripts Execution Checklist
-- ================================================================================================
-- Use this checklist to track execution of all insert scripts
-- Status: Create for new scripts, Verify for fixed scripts
-- ================================================================================================

EXECUTION ORDER & CHECKLIST
=============================

STEP 1: Location Lookups (NO DEPENDENCIES - Execute First)
----------------------------------------------------------
[ ] 005. Insert Countries.sql
    Records to insert: 20 countries
    Dependencies: None
    Verification: SELECT COUNT(*) FROM Location.Countries -- Should be 20

[ ] 006. Insert Provinces.sql
    Records to insert: 9 provinces
    Dependencies: Location.Countries
    Verification: SELECT COUNT(*) FROM Location.Provinces -- Should be 9

[ ] 007. Insert Cities.sql
    Records to insert: 38 cities
    Dependencies: Location.Provinces
    Verification: SELECT COUNT(*) FROM Location.Cities -- Should be 38


STEP 2: Profile Lookups (NO DEPENDENCIES - Execute Second)
-----------------------------------------------------------
[ ] Insert Gender.sql (FIXED)
    Records to insert: 4 genders
    Dependencies: None
    Verification: SELECT COUNT(*) FROM Profile.Gender WHERE IsActive = 1 -- Should be 4

[ ] Insert Merital Status.sql (FIXED)
    Records to insert: 6 marital statuses
    Dependencies: None
    Verification: SELECT COUNT(*) FROM Profile.MaritalStatus WHERE IsActive = 1 -- Should be 6


STEP 3: Security Setup (ORDER MATTERS)
---------------------------------------
[ ] 008. Insert Roles.sql
    Records to insert: 7 roles
    Dependencies: None
    Verification: SELECT COUNT(*) FROM Security.Roles -- Should be 7

[ ] 009. Insert Permissions.sql
    Records to insert: 52 permissions
    Dependencies: None
    Verification: SELECT COUNT(*) FROM Security.Permissions -- Should be 52

[ ] 010. Insert RolePermissions.sql
    Records to insert: 210+ role-permission mappings
    Dependencies: Security.Roles, Security.Permissions (both must be populated first)
    Verification: SELECT COUNT(*) FROM Security.RolePermissions -- Should be ~210


STEP 4: Healthcare Reference Data (Execute After Location/Profile Lookups)
---------------------------------------------------------------------------
[ ] 011. Insert BillingCodes.sql
    Records to insert: 50 billing codes
    Dependencies: None
    Verification: SELECT COUNT(*) FROM Billing.BillingCodes -- Should be 50

[ ] 012. Insert HealthcareProviders.sql
    Records to insert: 10 healthcare providers
    Dependencies: Location.Cities
    Verification: SELECT COUNT(*) FROM HealthcareServices.HealthcareProviders -- Should be 10

[ ] 013. Insert InsuranceProviders.sql
    Records to insert: 8 insurance providers
    Dependencies: Location.Countries
    Verification: SELECT COUNT(*) FROM HealthcareServices.InsuranceProviders -- Should be 8

[ ] 014. Insert Allergies_Medications.sql
    Records to insert: 15 allergies + 15 medications = 30 records
    Dependencies: None
    Verification: SELECT COUNT(*) FROM Profile.Allergies -- Should be 15
                  SELECT COUNT(*) FROM Profile.Medications -- Should be 15


STEP 5: Admin Bootstrap (Execute After Roles Created)
------------------------------------------------------
[ ] 016. Insert AdminUser.sql
    Records to insert: 1 admin user + 1 user-role mapping
    Dependencies: Security.Roles (ADMIN role must exist)
    Verification: SELECT * FROM Security.Users WHERE UserName = 'admin'
    Credentials: Username: admin | Password: HealthcareAdmin@2026! (CHANGE ON FIRST LOGIN)


STEP 6: Sample Test Data (Execute After ALL Lookups and Reference Data)
------------------------------------------------------------------------
[ ] 015. Insert SampleTestData.sql
    Records to insert: 1 patient with 20+ related records
    Dependencies: ALL previous scripts (lookups, reference data)
    Verification: SELECT * FROM Profile.Patient WHERE FirstName = 'John'
    Test Patient: John Anderson - complete medical profile for UAT


=============================
COMPLETE DATA VERIFICATION
=============================

After executing all scripts, verify total data loaded:

SELECT 'Countries' as [Table], COUNT(*) as [Records] FROM Location.Countries UNION ALL
SELECT 'Provinces', COUNT(*) FROM Location.Provinces UNION ALL
SELECT 'Cities', COUNT(*) FROM Location.Cities UNION ALL
SELECT 'Gender', COUNT(*) FROM Profile.Gender UNION ALL
SELECT 'MaritalStatus', COUNT(*) FROM Profile.MaritalStatus UNION ALL
SELECT 'Roles', COUNT(*) FROM Security.Roles UNION ALL
SELECT 'Permissions', COUNT(*) FROM Security.Permissions UNION ALL
SELECT 'RolePermissions', COUNT(*) FROM Security.RolePermissions UNION ALL
SELECT 'Users', COUNT(*) FROM Security.Users UNION ALL
SELECT 'BillingCodes', COUNT(*) FROM Billing.BillingCodes UNION ALL
SELECT 'HealthcareProviders', COUNT(*) FROM HealthcareServices.HealthcareProviders UNION ALL
SELECT 'InsuranceProviders', COUNT(*) FROM HealthcareServices.InsuranceProviders UNION ALL
SELECT 'Allergies', COUNT(*) FROM Profile.Allergies UNION ALL
SELECT 'Medications', COUNT(*) FROM Profile.Medications UNION ALL
SELECT 'Patients', COUNT(*) FROM Profile.Patient


EXPECTED RESULTS:
=================
Countries: 20
Provinces: 9
Cities: 38
Gender: 4
MaritalStatus: 6
Roles: 7
Permissions: 52
RolePermissions: 210
Users: 1
BillingCodes: 50
HealthcareProviders: 10
InsuranceProviders: 8
Allergies: 15
Medications: 15
Patients: 1 (with optional sample data)

TOTAL: 495+ records


=============================
EXECUTION NOTES
=============================

1. DEPENDENCIES ARE CRITICAL
   - Always execute Location lookups before Health reference data
   - Always execute Roles & Permissions before RolePermissions
   - Always execute all lookups before Sample Test Data
   - Use Master Deployment Script to handle ordering automatically

2. ERROR HANDLING
   - If error occurs, check dependency table is populated
   - If FK constraint error: Execute parent table inserts first
   - If duplicate error: Delete and re-execute affected script
   - If timeout: Increase query timeout in SSMS (Tools > Options > Query Execution)

3. ROLLBACK PROCEDURE (if needed)
   - Delete data in reverse order of insertion
   - Keep transactions small to avoid locks
   - Verify no production data affected before proceeding

4. POST-EXECUTION TASKS
   - Change admin default password immediately
   - Create application users and assign roles
   - Configure backup strategy
   - Test appointment scheduling workflow
   - Validate patient form submission
   - Perform user acceptance testing (use John Anderson sample patient)

5. SECURITY REMINDERS
   - Admin default password: HealthcareAdmin@2026! (MUST CHANGE)
   - Store secure passwords in encrypted vault
   - Audit all user access
   - Review permissions regularly
   - Enable SQL Server audit logging


=============================
FILE LOCATIONS & SIZES (Approximate)
=============================

Location: /home/samkelo/HealthcareForm/001. Database/005. Table Inserts/

000. MASTER_DEPLOYMENT_SCRIPT.sql        ~3 KB    Orchestration script
005. Insert Countries.sql                ~2 KB    20 countries
006. Insert Provinces.sql                ~1 KB    9 provinces
007. Insert Cities.sql                   ~4 KB    38 cities
Insert Gender.sql                        ~1 KB    4 genders (FIXED)
Insert Merital Status.sql                ~1 KB    6 statuses (FIXED)
008. Insert Roles.sql                    ~2 KB    7 roles
009. Insert Permissions.sql              ~6 KB    52 permissions
010. Insert RolePermissions.sql         ~10 KB    210+ mappings
011. Insert BillingCodes.sql             ~5 KB    50 billing codes
012. Insert HealthcareProviders.sql      ~3 KB    10 providers
013. Insert InsuranceProviders.sql       ~2 KB    8 insurance providers
014. Insert Allergies_Medications.sql    ~4 KB    30 records
015. Insert SampleTestData.sql          ~15 KB    1 patient + 20+ records
016. Insert AdminUser.sql                ~1 KB    1 admin user
INSERT_SCRIPTS_README.md                ~50 KB    Comprehensive documentation
COMPLETION_SUMMARY.md                   ~20 KB    Summary of deliverables

Total: ~145 KB of SQL scripts and documentation


=============================
RECOMMENDED EXECUTION METHOD
=============================

OPTION 1 (RECOMMENDED): Use Master Deployment Script
-----------------------------------------------------
:r "C:\Path\To\000. MASTER_DEPLOYMENT_SCRIPT.sql"

This will:
✓ Execute all scripts in correct order
✓ Show progress with step numbers
✓ Verify dependencies automatically
✓ Display completion time
✓ Show next steps for post-deployment


OPTION 2: Execute Individually
-------------------------------
Follow the checklist above in order, executing one script at a time
Allows for verification between steps
More time-consuming but provides better control


=============================
QUICK START (COPY & PASTE)
=============================

USE HealthcareForm
GO

-- Execute all inserts in order
:r "C:\Path\To\005. Insert Countries.sql"
:r "C:\Path\To\006. Insert Provinces.sql"
:r "C:\Path\To\007. Insert Cities.sql"
:r "C:\Path\To\Insert Gender.sql"
:r "C:\Path\To\Insert Merital Status.sql"
:r "C:\Path\To\008. Insert Roles.sql"
:r "C:\Path\To\009. Insert Permissions.sql"
:r "C:\Path\To\010. Insert RolePermissions.sql"
:r "C:\Path\To\011. Insert BillingCodes.sql"
:r "C:\Path\To\012. Insert HealthcareProviders.sql"
:r "C:\Path\To\013. Insert InsuranceProviders.sql"
:r "C:\Path\To\014. Insert Allergies_Medications.sql"
:r "C:\Path\To\016. Insert AdminUser.sql"
:r "C:\Path\To\015. Insert SampleTestData.sql"

-- Verify all data loaded
SELECT 'Countries' as [Table], COUNT(*) FROM Location.Countries UNION ALL
SELECT 'Provinces', COUNT(*) FROM Location.Provinces UNION ALL
SELECT 'Cities', COUNT(*) FROM Location.Cities UNION ALL
SELECT 'Roles', COUNT(*) FROM Security.Roles UNION ALL
SELECT 'Permissions', COUNT(*) FROM Security.Permissions UNION ALL
SELECT 'Patients', COUNT(*) FROM Profile.Patient

GO


=============================
SUPPORT & DOCUMENTATION
=============================

For detailed information, see:
- INSERT_SCRIPTS_README.md        [Comprehensive guide]
- COMPLETION_SUMMARY.md            [Project status]
- Specific script headers           [Script details]

For troubleshooting:
- Check dependencies are satisfied
- Verify parent tables are populated
- Review script error messages
- Consult INSERT_SCRIPTS_README.md troubleshooting section


Created: 14/02/2026
Version: 1.0
Status: Production-Ready
