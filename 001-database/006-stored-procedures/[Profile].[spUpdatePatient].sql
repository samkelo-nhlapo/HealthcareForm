USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Updates the patient row and refreshes the linked address/contact records in one transaction.
-- Validation intentionally stays aligned with spAddPatient so create and update enforce the same rules.
CREATE OR ALTER PROC [Profile].[spUpdatePatient]
(
    @FirstName VARCHAR(250) = '',
    @LastName VARCHAR(250) = '',
    @ID_Number VARCHAR(250) = '',
    @DateOfBirth DATETIME = NULL,
    @GenderIDFK INT = 0,
    @PhoneNumber VARCHAR(250) = '',
    @Email VARCHAR(250) = '',
    @Line1 VARCHAR(250) = '',
    @Line2 VARCHAR(250) = '',
    @CityIDFK INT = 0,
    @ProvinceIDFK INT = 0,
    @CountryIDFK INT = 0,
    @MaritalStatusIDFK INT = 0,
    @MedicationList VARCHAR(MAX) = '',
    @EmergencyName VARCHAR(250) = '',
    @EmergencyLastName VARCHAR(250) = '',
    @EmergencyPhoneNumber VARCHAR(250) = '',
    @Relationship VARCHAR(250) = '',
    @EmergancyDateOfBirth DATETIME = NULL,
    @Message VARCHAR(250) OUTPUT,
    @ClientIdFK UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
    DECLARE @DefaultDate DATETIME = GETDATE(),
            @PatientId UNIQUEIDENTIFIER,
            @AddressId UNIQUEIDENTIFIER,
            @EmergencyId UNIQUEIDENTIFIER,
            @EmailId UNIQUEIDENTIFIER,
            @PhoneId UNIQUEIDENTIFIER,
            @NormalizedPhone VARCHAR(50),
            @NormalizedEmergencyPhone VARCHAR(50),
            @FormattedPhone VARCHAR(15),
            @FormattedEmergencyPhone VARCHAR(15),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validation parity with spAddPatient
    IF LTRIM(RTRIM(@ID_Number)) = ''
    BEGIN
        SET @Message = 'ID number is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(@FirstName)) = '' OR LTRIM(RTRIM(@LastName)) = ''
    BEGIN
        SET @Message = 'First name and last name are required.';
        RETURN;
    END

    IF @DateOfBirth IS NULL OR @DateOfBirth > GETDATE()
    BEGIN
        SET @Message = 'Invalid date of birth.';
        RETURN;
    END

    IF @EmergancyDateOfBirth IS NULL OR @EmergancyDateOfBirth > GETDATE()
    BEGIN
        SET @Message = 'Invalid emergency contact date of birth.';
        RETURN;
    END

    IF @GenderIDFK <= 0 OR @MaritalStatusIDFK <= 0 OR @CityIDFK <= 0
    BEGIN
        SET @Message = 'Gender, marital status and city are required.';
        RETURN;
    END

    IF LTRIM(RTRIM(@Email)) = '' OR @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @Message = 'A valid email address is required.';
        RETURN;
    END

    SET @NormalizedPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@PhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');
    SET @NormalizedEmergencyPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@EmergencyPhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');

    IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Phone number must contain exactly 10 digits.';
        RETURN;
    END

    IF LEN(@NormalizedEmergencyPhone) <> 10 OR @NormalizedEmergencyPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Emergency phone number must contain exactly 10 digits.';
        RETURN;
    END

    IF @ProvinceIDFK > 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM Location.Cities C
            WHERE C.CityId = @CityIDFK
              AND C.ProvinceIDFK = @ProvinceIDFK
        )
        BEGIN
            SET @Message = 'City and province combination is invalid.';
            RETURN;
        END
    END

    IF @CountryIDFK > 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM Location.Cities C
            INNER JOIN Location.Provinces P ON P.ProvinceId = C.ProvinceIDFK
            WHERE C.CityId = @CityIDFK
              AND P.CountryIDFK = @CountryIDFK
        )
        BEGIN
            SET @Message = 'City and country combination is invalid.';
            RETURN;
        END
    END

    IF @ClientIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @Message = 'Invalid ClientIdFK.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRAN;

        SELECT
            @PatientId = PatientId,
            @AddressId = AddressIDFK,
            @EmergencyId = EmergencyIDFK
        FROM Profile.Patient
        WHERE ID_Number = @ID_Number
          AND IsDeleted = 0;

        IF @PatientId IS NULL
        BEGIN
            SET @Message = 'Sorry User [' + @ID_Number + '] does not exist, please verify and try again';
            ROLLBACK TRAN;
            RETURN;
        END

        SET @FormattedPhone =
            SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
            SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
            SUBSTRING(@NormalizedPhone, 7, 4);

        SET @FormattedEmergencyPhone =
            SUBSTRING(@NormalizedEmergencyPhone, 1, 3) + '-' +
            SUBSTRING(@NormalizedEmergencyPhone, 4, 3) + '-' +
            SUBSTRING(@NormalizedEmergencyPhone, 7, 4);

        IF @AddressId IS NULL
        BEGIN
            SET @AddressId = NEWID();
            INSERT INTO Location.Address (AddressId, Line1, Line2, CityIDFK, UpdateDate)
            VALUES (@AddressId, @Line1, @Line2, @CityIDFK, @DefaultDate);
        END
        ELSE
        BEGIN
            UPDATE Location.Address
            SET Line1 = @Line1,
                Line2 = @Line2,
                CityIDFK = @CityIDFK,
                UpdateDate = @DefaultDate,
                UpdatedBy = SUSER_SNAME()
            WHERE AddressId = @AddressId;
        END

        IF @EmergencyId IS NULL
        BEGIN
            SET @EmergencyId = NEWID();
            INSERT INTO Contacts.EmergencyContacts
            (
                EmergencyId,
                FirstName,
                LastName,
                PhoneNumber,
                Relationship,
                DateOfBirth,
                IsActive,
                UpdateDate
            )
            VALUES
            (
                @EmergencyId,
                @EmergencyName,
                @EmergencyLastName,
                @FormattedEmergencyPhone,
                @Relationship,
                @EmergancyDateOfBirth,
                1,
                @DefaultDate
            );
        END
        ELSE
        BEGIN
            UPDATE Contacts.EmergencyContacts
            SET FirstName = @EmergencyName,
                LastName = @EmergencyLastName,
                PhoneNumber = @FormattedEmergencyPhone,
                Relationship = @Relationship,
                DateOfBirth = @EmergancyDateOfBirth,
                UpdateDate = @DefaultDate
            WHERE EmergencyId = @EmergencyId;
        END

        -- Reuse shared contact master rows when possible, then move the patient's
        -- primary junction-table links to the selected email and phone records.
        SELECT @EmailId = E.EmailId FROM Contacts.Emails E WHERE E.Email = @Email;
        IF @EmailId IS NULL
        BEGIN
            SET @EmailId = NEWID();
            INSERT INTO Contacts.Emails (EmailId, Email, IsActive, UpdateDate)
            VALUES (@EmailId, @Email, 1, @DefaultDate);
        END

        SELECT @PhoneId = P.PhoneId FROM Contacts.Phones P WHERE P.PhoneNumber = @FormattedPhone;
        IF @PhoneId IS NULL
        BEGIN
            SET @PhoneId = NEWID();
            INSERT INTO Contacts.Phones (PhoneId, PhoneNumber, IsActive, UpdateDate)
            VALUES (@PhoneId, @FormattedPhone, 1, @DefaultDate);
        END

        IF NOT EXISTS (SELECT 1 FROM Contacts.PatientEmails WHERE PatientIdFK = @PatientId AND EmailIdFK = @EmailId)
        BEGIN
            INSERT INTO Contacts.PatientEmails (PatientEmailId, PatientIdFK, EmailIdFK, IsPrimary, EmailType)
            VALUES (NEWID(), @PatientId, @EmailId, 1, 'Primary');
        END

        UPDATE Contacts.PatientEmails
        SET IsPrimary = CASE WHEN EmailIdFK = @EmailId THEN 1 ELSE 0 END,
            UpdatedDate = @DefaultDate,
            UpdatedBy = SUSER_SNAME()
        WHERE PatientIdFK = @PatientId;

        IF NOT EXISTS (SELECT 1 FROM Contacts.PatientPhones WHERE PatientIdFK = @PatientId AND PhoneIdFK = @PhoneId)
        BEGIN
            INSERT INTO Contacts.PatientPhones (PatientPhoneId, PatientIdFK, PhoneIdFK, IsPrimary, PhoneType)
            VALUES (NEWID(), @PatientId, @PhoneId, 1, 'Primary');
        END

        UPDATE Contacts.PatientPhones
        SET IsPrimary = CASE WHEN PhoneIdFK = @PhoneId THEN 1 ELSE 0 END,
            UpdatedDate = @DefaultDate,
            UpdatedBy = SUSER_SNAME()
        WHERE PatientIdFK = @PatientId;

        UPDATE Profile.Patient
        SET FirstName = @FirstName,
            LastName = @LastName,
            DateOfBirth = @DateOfBirth,
            GenderIDFK = @GenderIDFK,
            MedicationList = @MedicationList,
            ClientIdFK = COALESCE(@ClientIdFK, ClientIdFK),
            AddressIDFK = @AddressId,
            MaritalStatusIDFK = @MaritalStatusIDFK,
            EmergencyIDFK = @EmergencyId,
            UpdatedDate = @DefaultDate,
            UpdatedBy = SUSER_SNAME()
        WHERE PatientId = @PatientId;

        COMMIT TRAN;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SET @UserName = SUSER_SNAME();
        SET @ErrorSchema = 'Profile';
        SET @ErrorProc = ERROR_PROCEDURE();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorState = ERROR_STATE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorDateTime = GETDATE();

        IF EXISTS
        (
            SELECT 1
            FROM sys.procedures P
            INNER JOIN sys.schemas S ON S.schema_id = P.schema_id
            WHERE S.name = 'Exceptions'
              AND P.name = 'spErrorHandling'
        )
        BEGIN
            BEGIN TRY
                EXEC [Exceptions].[spErrorHandling]
                    @UserName = @UserName,
                    @ErrorSchema = @ErrorSchema,
                    @ErrorProc = @ErrorProc,
                    @ErrorNumber = @ErrorNumber,
                    @ErrorState = @ErrorState,
                    @ErrorSeverity = @ErrorSeverity,
                    @ErrorLine = @ErrorLine,
                    @ErrorMessage = @ErrorMessage,
                    @ErrorDateTime = @ErrorDateTime;
            END TRY
            BEGIN CATCH
                IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
                BEGIN
                    INSERT INTO Exceptions.Errors
                    (
                        UserName,
                        ErrorSchema,
                        ErrorProcedure,
                        ErrorNumber,
                        ErrorState,
                        ErrorSeverity,
                        ErrorLine,
                        ErrorMessage,
                        ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName,
                        @ErrorSchema,
                        @ErrorProc,
                        @ErrorNumber,
                        @ErrorState,
                        @ErrorSeverity,
                        @ErrorLine,
                        LEFT(@ErrorMessage, 500),
                        @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName,
                ErrorSchema,
                ErrorProcedure,
                ErrorNumber,
                ErrorState,
                ErrorSeverity,
                ErrorLine,
                ErrorMessage,
                ErrorDateTime
            )
            VALUES
            (
                @UserName,
                @ErrorSchema,
                @ErrorProc,
                @ErrorNumber,
                @ErrorState,
                @ErrorSeverity,
                @ErrorLine,
                LEFT(@ErrorMessage, 500),
                @ErrorDateTime
            );
        END

        SET @Message = 'Failed to update patient record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
