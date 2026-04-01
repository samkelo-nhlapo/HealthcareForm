USE HealthcareForm
GO

-- Smoke/UAT harness for the patient CRUD stored procedures.
-- By default it runs inside a transaction and rolls everything back at the end.
SET NOCOUNT ON;

DECLARE @RunInTransaction BIT = 1;
DECLARE @DoRollback BIT = 1;

DECLARE @GenderIDFK INT,
        @MaritalStatusIDFK INT,
        @CityIDFK INT,
        @ProvinceIDFK INT,
        @CountryIDFK INT;

SELECT TOP (1)
    @GenderIDFK = G.GenderId
FROM Profile.Gender G
WHERE G.IsActive = 1
ORDER BY G.GenderId;

SELECT TOP (1)
    @MaritalStatusIDFK = M.MaritalStatusId
FROM Profile.MaritalStatus M
WHERE M.IsActive = 1
ORDER BY M.MaritalStatusId;

SELECT TOP (1)
    @CityIDFK = C.CityId,
    @ProvinceIDFK = P.ProvinceId,
    @CountryIDFK = CO.CountryId
FROM Location.Cities C
INNER JOIN Location.Provinces P ON P.ProvinceId = C.ProvinceIDFK
INNER JOIN Location.Countries CO ON CO.CountryId = P.CountryIDFK
WHERE C.IsActive = 1
  AND P.IsActive = 1
  AND CO.IsActive = 1
ORDER BY C.CityId;

IF @GenderIDFK IS NULL OR @MaritalStatusIDFK IS NULL OR @CityIDFK IS NULL
BEGIN
    THROW 50000, 'Lookup data missing (Gender/MaritalStatus/City). Seed lookups before running UAT.', 1;
END

DECLARE @UniqueSuffix VARCHAR(20) = REPLACE(CONVERT(VARCHAR(19), GETDATE(), 120), ':', '');
SET @UniqueSuffix = REPLACE(@UniqueSuffix, '-', '');
SET @UniqueSuffix = REPLACE(@UniqueSuffix, ' ', '');

DECLARE @IDNumber VARCHAR(250) = 'UAT' + @UniqueSuffix;
DECLARE @Email VARCHAR(250) = 'uat.' + @UniqueSuffix + '@healthcareform.local';
DECLARE @Phone VARCHAR(250) = '0825551234';
DECLARE @EmergencyPhone VARCHAR(250) = '0825554321';

DECLARE @Message VARCHAR(250),
        @StatusCode INT,
        @PatientId UNIQUEIDENTIFIER,
        @TotalRecords INT;

DECLARE @FirstName VARCHAR(250),
        @LastName VARCHAR(250),
        @ID_Number_Out VARCHAR(250),
        @DateOfBirth DATETIME,
        @GenderOut INT,
        @PhoneOut VARCHAR(250),
        @EmailOut VARCHAR(250),
        @Line1Out VARCHAR(250),
        @Line2Out VARCHAR(250),
        @CityOut INT,
        @ProvinceOut INT,
        @CountryOut INT,
        @MaritalOut INT,
        @MedicationListOut VARCHAR(MAX),
        @EmergencyNameOut VARCHAR(250),
        @EmergencyLastNameOut VARCHAR(250),
        @EmergencyPhoneOut VARCHAR(250),
        @RelationshipOut VARCHAR(250),
        @EmergencyDOBOut DATETIME;

IF @RunInTransaction = 1
    BEGIN TRAN;

BEGIN TRY
    PRINT 'Step 1: Add patient';
    EXEC [Profile].[spAddPatient]
        @FirstName = 'Uat',
        @LastName = 'Patient',
        @ID_Number = @IDNumber,
        @DateOfBirth = '1990-01-01',
        @GenderIDFK = @GenderIDFK,
        @PhoneNumber = @Phone,
        @Email = @Email,
        @Line1 = '123 UAT Street',
        @Line2 = 'Suite 10',
        @CityIDFK = @CityIDFK,
        @ProvinceIDFK = @ProvinceIDFK,
        @CountryIDFK = @CountryIDFK,
        @MaritalStatusIDFK = @MaritalStatusIDFK,
        @EmergencyName = 'UatEmergency',
        @EmergencyLastName = 'Contact',
        @EmergencyPhoneNumber = @EmergencyPhone,
        @Relationship = 'Sibling',
        @EmergancyDateOfBirth = '1992-02-02',
        @MedicationList = 'None',
        @Message = @Message OUTPUT,
        @PatientIdOutput = @PatientId OUTPUT,
        @StatusCode = @StatusCode OUTPUT;

    SELECT [Step] = 'Add', @StatusCode AS StatusCode, @Message AS Message, @PatientId AS PatientId;

    PRINT 'Step 2: Get patient';
    EXEC [Profile].[spGetPatient]
        @IDNumber = @IDNumber,
        @FirstName = @FirstName OUTPUT,
        @LastName = @LastName OUTPUT,
        @ID_Number = @ID_Number_Out OUTPUT,
        @DateOfBirth = @DateOfBirth OUTPUT,
        @GenderIDFK = @GenderOut OUTPUT,
        @PhoneNumber = @PhoneOut OUTPUT,
        @Email = @EmailOut OUTPUT,
        @Line1 = @Line1Out OUTPUT,
        @Line2 = @Line2Out OUTPUT,
        @CityIDFK = @CityOut OUTPUT,
        @ProvinceIDFK = @ProvinceOut OUTPUT,
        @CountryIDFK = @CountryOut OUTPUT,
        @MaritalStatusIDFK = @MaritalOut OUTPUT,
        @MedicationList = @MedicationListOut OUTPUT,
        @EmergencyName = @EmergencyNameOut OUTPUT,
        @EmergencyLastName = @EmergencyLastNameOut OUTPUT,
        @EmergencyPhoneNumber = @EmergencyPhoneOut OUTPUT,
        @Relationship = @RelationshipOut OUTPUT,
        @EmergancyDateOfBirth = @EmergencyDOBOut OUTPUT,
        @Message = @Message OUTPUT;

    SELECT [Step] = 'Get', @Message AS Message, @FirstName AS FirstName, @LastName AS LastName, @PhoneOut AS PhoneNumber, @EmailOut AS Email;

    PRINT 'Step 3: Update patient';
    EXEC [Profile].[spUpdatePatient]
        @FirstName = 'UatUpdated',
        @LastName = 'PatientUpdated',
        @ID_Number = @IDNumber,
        @DateOfBirth = '1990-01-01',
        @GenderIDFK = @GenderIDFK,
        @PhoneNumber = '0825556789',
        @Email = @Email,
        @Line1 = '456 Updated Street',
        @Line2 = 'Suite 22',
        @CityIDFK = @CityIDFK,
        @ProvinceIDFK = @ProvinceIDFK,
        @CountryIDFK = @CountryIDFK,
        @MaritalStatusIDFK = @MaritalStatusIDFK,
        @MedicationList = 'Aspirin',
        @EmergencyName = 'UatEmergency',
        @EmergencyLastName = 'Contact',
        @EmergencyPhoneNumber = @EmergencyPhone,
        @Relationship = 'Sibling',
        @EmergancyDateOfBirth = '1992-02-02',
        @Message = @Message OUTPUT;

    SELECT [Step] = 'Update', @Message AS Message;

    PRINT 'Step 4: List patients (filtered)';
    EXEC [Profile].[spListPatients]
        @SearchTerm = @IDNumber,
        @IsDeleted = 0,
        @PageNumber = 1,
        @PageSize = 10,
        @TotalRecords = @TotalRecords OUTPUT,
        @Message = @Message OUTPUT;

    SELECT [Step] = 'List', @TotalRecords AS TotalRecords, @Message AS Message;

    PRINT 'Step 5: Soft delete patient';
    EXEC [Profile].[spDeletePatient]
        @IDNumber = @IDNumber,
        @Message = @Message OUTPUT;

    SELECT [Step] = 'Delete', @Message AS Message;

    PRINT 'Step 6: Restore patient';
    EXEC [Profile].[spRestorePatient]
        @IDNumber = @IDNumber,
        @Message = @Message OUTPUT,
        @StatusCode = @StatusCode OUTPUT;

    SELECT [Step] = 'Restore', @StatusCode AS StatusCode, @Message AS Message;

    IF @RunInTransaction = 1
    BEGIN
        IF @DoRollback = 1
        BEGIN
            ROLLBACK TRAN;
            PRINT 'UAT completed and rolled back.';
        END
        ELSE
        BEGIN
            COMMIT TRAN;
            PRINT 'UAT completed and committed.';
        END
    END
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 AND @RunInTransaction = 1
        ROLLBACK TRAN;

    THROW;
END CATCH
GO
