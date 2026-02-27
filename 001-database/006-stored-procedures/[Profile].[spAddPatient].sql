USE [HealthcareForm]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAddPatient]
(
    @FirstName VARCHAR(250) = '',
    @LastName VARCHAR(250) = '',
    @ID_Number VARCHAR(250) = '',
    @DateOfBirth DATETIME,
    @GenderIDFK INT = 0,
    @PhoneNumber VARCHAR(250) = '',
    @Email VARCHAR(250) = '',
    @Line1 VARCHAR(250) = '',
    @Line2 VARCHAR(250) = '',
    @CityIDFK INT = 0,
    @ProvinceIDFK INT = 0,
    @CountryIDFK INT = 0,
    @MaritalStatusIDFK INT = 0,
    @EmergencyName VARCHAR(250) = '',
    @EmergencyLastName VARCHAR(250) = '',
    @EmergencyPhoneNumber VARCHAR(250) = '',
    @Relationship VARCHAR(250) = '',
    @EmergancyDateOfBirth DATETIME,
    @MedicationList VARCHAR(MAX) = '',
    @Message VARCHAR(250) OUTPUT,
    @PatientIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @ClientIdFK UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
    DECLARE @DefaultDate DATETIME = GETDATE(),
            @AddressIDFK UNIQUEIDENTIFIER = NEWID(),
            @EmergencyIDFK UNIQUEIDENTIFIER = NEWID(),
            @PatientId UNIQUEIDENTIFIER = NEWID(),
            @EmailIDFK UNIQUEIDENTIFIER,
            @PhoneIDFK UNIQUEIDENTIFIER,
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

    SET @PatientIdOutput = NULL;
    SET @StatusCode = -1;

    IF LTRIM(RTRIM(@ID_Number)) = ''
    BEGIN
        SET @Message = 'ID number is required.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF LTRIM(RTRIM(@FirstName)) = '' OR LTRIM(RTRIM(@LastName)) = ''
    BEGIN
        SET @Message = 'First name and last name are required.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF @DateOfBirth IS NULL OR @DateOfBirth > GETDATE()
    BEGIN
        SET @Message = 'Invalid date of birth.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF @GenderIDFK <= 0 OR @MaritalStatusIDFK <= 0 OR @CityIDFK <= 0
    BEGIN
        SET @Message = 'Gender, marital status and city are required.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF LTRIM(RTRIM(@Email)) = '' OR @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @Message = 'A valid email address is required.';
        SET @StatusCode = 1;
        RETURN;
    END

    SET @NormalizedPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@PhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');
    SET @NormalizedEmergencyPhone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@EmergencyPhoneNumber)), '-', ''), ' ', ''), '+', ''), '(', ''), ')', '');

    IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Phone number must contain exactly 10 digits.';
        SET @StatusCode = 1;
        RETURN;
    END

    IF LEN(@NormalizedEmergencyPhone) <> 10 OR @NormalizedEmergencyPhone LIKE '%[^0-9]%'
    BEGIN
        SET @Message = 'Emergency phone number must contain exactly 10 digits.';
        SET @StatusCode = 1;
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
            SET @StatusCode = 1;
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
            SET @StatusCode = 1;
            RETURN;
        END
    END

    IF @ClientIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @Message = 'Invalid ClientIdFK.';
        SET @StatusCode = 1;
        RETURN;
    END

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRAN;

        IF EXISTS(SELECT 1 FROM Profile.Patient WITH (UPDLOCK, HOLDLOCK) WHERE ID_Number = @ID_Number AND IsDeleted = 0)
        BEGIN
            SET @Message = 'Sorry User ID Number: "' + @ID_Number + '" already exists, please validate and try again';
            SET @StatusCode = 2;
            ROLLBACK TRAN;
            SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
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

        SELECT @EmailIDFK = E.EmailId
        FROM Contacts.Emails E WITH (UPDLOCK, HOLDLOCK)
        WHERE E.Email = @Email;

        IF @EmailIDFK IS NULL
        BEGIN
            SET @EmailIDFK = NEWID();
            INSERT INTO Contacts.Emails (EmailId, Email, IsActive, UpdateDate)
            VALUES (@EmailIDFK, @Email, 1, @DefaultDate);
        END

        SELECT @PhoneIDFK = P.PhoneId
        FROM Contacts.Phones P WITH (UPDLOCK, HOLDLOCK)
        WHERE P.PhoneNumber = @FormattedPhone;

        IF @PhoneIDFK IS NULL
        BEGIN
            SET @PhoneIDFK = NEWID();
            INSERT INTO Contacts.Phones (PhoneId, PhoneNumber, IsActive, UpdateDate)
            VALUES (@PhoneIDFK, @FormattedPhone, 1, @DefaultDate);
        END

        INSERT INTO Location.Address (AddressId, Line1, Line2, CityIDFK, UpdateDate)
        VALUES (@AddressIDFK, @Line1, @Line2, @CityIDFK, @DefaultDate);

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
            @EmergencyIDFK,
            @EmergencyName,
            @EmergencyLastName,
            @FormattedEmergencyPhone,
            @Relationship,
            @EmergancyDateOfBirth,
            1,
            @DefaultDate
        );

        INSERT INTO Profile.Patient
        (
            PatientId,
            FirstName,
            LastName,
            ID_Number,
            DateOfBirth,
            GenderIDFK,
            MedicationList,
            ClientIdFK,
            AddressIDFK,
            MaritalStatusIDFK,
            EmergencyIDFK
        )
        VALUES
        (
            @PatientId,
            @FirstName,
            @LastName,
            @ID_Number,
            @DateOfBirth,
            @GenderIDFK,
            @MedicationList,
            @ClientIdFK,
            @AddressIDFK,
            @MaritalStatusIDFK,
            @EmergencyIDFK
        );

        INSERT INTO Contacts.PatientEmails (PatientEmailId, PatientIdFK, EmailIdFK, IsPrimary, EmailType)
        VALUES (NEWID(), @PatientId, @EmailIDFK, 1, 'Primary');

        INSERT INTO Contacts.PatientPhones (PatientPhoneId, PatientIdFK, PhoneIdFK, IsPrimary, PhoneType)
        VALUES (NEWID(), @PatientId, @PhoneIDFK, 1, 'Primary');

        COMMIT TRAN;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        SET @PatientIdOutput = @PatientId;
        SET @StatusCode = 0;
        SET @Message = '';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

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

        IF @ErrorNumber IN (2601, 2627)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'A duplicate patient, email or phone record was detected. Please verify input and try again.';
        END
        ELSE
        BEGIN
            SET @StatusCode = -1;
            SET @Message = 'Failed to add patient record.';
        END
    END CATCH

    SET NOCOUNT OFF;
END
GO
