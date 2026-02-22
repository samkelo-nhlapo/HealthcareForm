-- ============================================================================
-- DATABASE IMPROVEMENTS AND REFACTORING GUIDE
-- Healthcare Form Database - February 2026
-- ============================================================================

/*
SUMMARY OF CHANGES
==================

1. SCHEMA IMPROVEMENTS
   - Added audit columns (CreatedDate, CreatedBy, UpdatedDate, UpdatedBy) to all tables
   - Added proper constraints and defaults
   - Improved data types (VARCHAR(250) -> VARCHAR(MAX) for MedicationList)

2. RELATIONSHIP FIXES
   - Removed direct FK from Patient to single Phone/Email
   - Created junction tables: PatientPhones and PatientEmails
   - Now supports multiple phones/emails per patient

3. VALIDATION IMPROVEMENTS
   - Added UNIQUE constraints on Phone and Email
   - Added UNIQUE constraint on Patient.ID_Number
   - Created validation functions for Email and Phone formatting

4. PERFORMANCE IMPROVEMENTS
   - Added indexes on frequently searched columns (ID_Number, Phone, Email, LastName)
   - Added indexes on foreign keys for join performance
   - Removed unused template tables

5. FUNCTION IMPLEMENTATIONS
   - Created [Contacts].[FormatPhoneNumber] function
   - Created [dbo].[CapitalizeFirstLetter] function
   - Created [dbo].[ValidateEmail] function

*/

-- ============================================================================
-- DEPLOYMENT ORDER (CRITICAL - Follow this sequence)
-- ============================================================================

/*
STEP 1: Create new functions (must exist before stored procedures)
   - 007. Triggers & Functions/dbo.CapitalizeFirstLetter.sql
   - 007. Triggers & Functions/Contacts.FormatPhoneNumber.sql
   - 007. Triggers & Functions/dbo.ValidateEmail.sql

STEP 2: Create new junction tables (no dependencies on existing Patient data)
   - 003. Tables/[Contacts].[PatientPhones].sql
   - 003. Tables/[Contacts].[PatientEmails].sql

STEP 3: Update existing tables (in order due to dependencies)
   - 003. Tables/[Contacts].[Phones].sql
   - 003. Tables/[Contacts].[Emails].sql
   - 003. Tables/[Location].[Address].sql
   - 003. Tables/[Profile].[Patient].sql (LAST - removes old FKs to Phones/Emails)

STEP 4: Update stored procedures
   - 006. Stored Procedures/[Profile].[spAddPatient_v2].sql
   - Update other procedures as needed

STEP 5: Migrate existing data (see DATA MIGRATION section below)

STEP 6: Update application code
   - Remove references to Patient.PhoneIDFK
   - Remove references to Patient.EmailIDFK
   - Use junction tables for phone/email lookups
   - Update stored procedure calls

*/

-- ============================================================================
-- DATA MIGRATION SCRIPT (Run after creating all tables)
-- ============================================================================

/*
IF YOU HAVE EXISTING DATA:

-- Step 1: Migrate phone numbers from Patient table to junction tables
INSERT INTO Contacts.PatientPhones (PatientIdFK, PhoneIdFK, IsPrimary, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy)
SELECT 
    p.PatientId,
    ph.PhoneId,
    1 AS IsPrimary,
    GETDATE(),
    'MIGRATION',
    GETDATE(),
    'MIGRATION'
FROM Profile.Patient p
INNER JOIN Contacts.Phones ph ON p.PhoneIDFK = ph.PhoneId
WHERE p.PhoneIDFK IS NOT NULL;

-- Step 2: Migrate email addresses from Patient table to junction tables
INSERT INTO Contacts.PatientEmails (PatientIdFK, EmailIdFK, IsPrimary, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy)
SELECT 
    p.PatientId,
    e.EmailId,
    1 AS IsPrimary,
    GETDATE(),
    'MIGRATION',
    GETDATE(),
    'MIGRATION'
FROM Profile.Patient p
INNER JOIN Contacts.Emails e ON p.EmailIDFK = e.EmailId
WHERE p.EmailIDFK IS NOT NULL;

-- Step 3: Verify data was migrated correctly
SELECT COUNT(*) AS MigratedPhones FROM Contacts.PatientPhones;
SELECT COUNT(*) AS MigratedEmails FROM Contacts.PatientEmails;

-- Step 4: Update Patient table with audit columns and remove old FKs
UPDATE Profile.Patient 
SET CreatedDate = GETDATE(),
    CreatedBy = 'MIGRATION',
    UpdatedDate = GETDATE(),
    UpdatedBy = 'MIGRATION'
WHERE CreatedDate IS NULL;

*/

-- ============================================================================
-- NEW STORED PROCEDURE - spAddPatient_v2
-- ============================================================================

/*
The new stored procedure [Profile].[spAddPatient_v2] now:

1. Validates all inputs before inserting
2. Creates junction table records for phone/email
3. Supports NULL values for optional fields
4. Tracks user who created the record
5. Includes comprehensive error handling
6. Returns the created PatientId as OUTPUT parameter

USAGE EXAMPLE:
DECLARE @PatientId UNIQUEIDENTIFIER, @Message VARCHAR(500);

EXEC [Profile].[spAddPatient_v2]
    @FirstName = 'John',
    @LastName = 'Doe',
    @ID_Number = '1234567890123',
    @DateOfBirth = '1990-01-15',
    @GenderIDFK = 1,
    @PhoneNumber = '0111234567',
    @Email = 'john.doe@example.com',
    @Line1 = '123 Main Street',
    @Line2 = 'Apartment 4B',
    @CityIDFK = 1,
    @MaritalStatusIDFK = 1,
    @EmergencyName = 'Jane',
    @EmergencyLastName = 'Doe',
    @EmergencyPhoneNumber = '0119876543',
    @Relationship = 'Spouse',
    @EmergencyDateOfBirth = '1992-03-20',
    @MedicationList = 'Aspirin, Metformin',
    @PatientId = @PatientId OUTPUT,
    @Message = @Message OUTPUT;

SELECT @PatientId AS PatientID, @Message AS Message;

*/

-- ============================================================================
-- JUNCTION TABLES - NEW QUERIES
-- ============================================================================

/*
Getting patient's primary phone:
SELECT p.PhoneNumber, pp.IsPrimary
FROM Contacts.PatientPhones pp
JOIN Contacts.Phones p ON pp.PhoneIdFK = p.PhoneId
WHERE pp.PatientIdFK = @PatientId AND pp.IsPrimary = 1;

Getting all patient's emails:
SELECT e.Email, pe.EmailType
FROM Contacts.PatientEmails pe
JOIN Contacts.Emails e ON pe.EmailIdFK = e.EmailId
WHERE pe.PatientIdFK = @PatientId
ORDER BY pe.IsPrimary DESC;

Adding additional phone to patient:
DECLARE @NewPhoneId UNIQUEIDENTIFIER = NEWID();
INSERT INTO Contacts.Phones (PhoneId, PhoneNumber, IsActive, UpdateDate, CreatedDate, CreatedBy)
VALUES (@NewPhoneId, '(011) 987-6543', 1, GETDATE(), GETDATE(), SYSTEM_USER);

INSERT INTO Contacts.PatientPhones (PatientIdFK, PhoneIdFK, IsPrimary, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy)
VALUES (@PatientId, @NewPhoneId, 0, GETDATE(), SYSTEM_USER, GETDATE(), SYSTEM_USER);

*/

-- ============================================================================
-- PERFORMANCE RECOMMENDATIONS
-- ============================================================================

/*
1. INDEXES ADDED:
   - IX_Patient_IDNumber on Profile.Patient(ID_Number)
   - IX_Patient_LastName on Profile.Patient(LastName)
   - IX_Patient_IsDeleted on Profile.Patient(IsDeleted)
   - IX_Phones_PhoneNumber on Contacts.Phones(PhoneNumber)
   - IX_Emails_Email on Contacts.Emails(Email)
   - IX_Address_CityIDFK on Location.Address(CityIDFK)
   - IX_PatientPhones_PatientIdFK on Contacts.PatientPhones(PatientIdFK)
   - IX_PatientPhones_PhoneIdFK on Contacts.PatientPhones(PhoneIdFK)
   - IX_PatientEmails_PatientIdFK on Contacts.PatientEmails(PatientIdFK)
   - IX_PatientEmails_EmailIdFK on Contacts.PatientEmails(EmailIdFK)

2. FILEGROUP RECOMMENDATIONS:
   - Increase PRIMARY filegroup MAXSIZE from 10MB to 1GB minimum
   - Increase FILEGROWTH from 1MB to 10MB or 25MB
   - Remove unused FILESTREAM filegroup if not needed
   - Consider archiving old patient records to separate filegroup

3. STATISTICS AND MAINTENANCE:
   - Update statistics on primary tables weekly
   - Rebuild fragmented indexes monthly
   - Review slow-running queries quarterly

*/

-- ============================================================================
-- VALIDATION CHECKS
-- ============================================================================

/*
After migration, run these checks to ensure data integrity:

-- Check for orphaned phone records
SELECT ph.PhoneId, ph.PhoneNumber
FROM Contacts.Phones ph
LEFT JOIN Contacts.PatientPhones pp ON ph.PhoneId = pp.PhoneIdFK
WHERE pp.PatientPhoneId IS NULL;

-- Check for orphaned email records
SELECT e.EmailId, e.Email
FROM Contacts.Emails e
LEFT JOIN Contacts.PatientEmails pe ON e.EmailId = pe.EmailIdFK
WHERE pe.PatientEmailId IS NULL;

-- Check for duplicate phone/email assignments
SELECT PatientIdFK, PhoneIdFK, COUNT(*) as Duplicates
FROM Contacts.PatientPhones
GROUP BY PatientIdFK, PhoneIdFK
HAVING COUNT(*) > 1;

SELECT PatientIdFK, EmailIdFK, COUNT(*) as Duplicates
FROM Contacts.PatientEmails
GROUP BY PatientIdFK, EmailIdFK
HAVING COUNT(*) > 1;

*/

-- ============================================================================
-- ROLLBACK PLAN (If issues occur)
-- ============================================================================

/*
If you need to rollback:

1. Keep backups of original tables before migration
2. Drop new junction tables: DROP TABLE Contacts.PatientPhones; DROP TABLE Contacts.PatientEmails;
3. Restore Patient table with original FK columns
4. Restore original stored procedures
5. Delete new functions (or keep them for future use)

Database backup is STRONGLY RECOMMENDED before executing any schema changes.

*/
