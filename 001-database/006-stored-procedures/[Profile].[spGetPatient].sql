USE [HealthcareForm]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Loads one patient by PatientId or ID number.
-- The row is returned through output parameters because the API still consumes that shape.
CREATE OR ALTER PROC [Profile].[spGetPatient]
(
    @PatientId UNIQUEIDENTIFIER = NULL,
    @IDNumber VARCHAR(250) = '',
    @IncludeDeleted BIT = 0,
    @FirstName VARCHAR(250) OUTPUT,
    @LastName VARCHAR(250) OUTPUT,
    @ID_Number VARCHAR(250) OUTPUT,
    @DateOfBirth DATETIME OUTPUT,
    @GenderIDFK INT OUTPUT,
    @PhoneNumber VARCHAR(250) OUTPUT,
    @Email VARCHAR(250) OUTPUT,
    @Line1 VARCHAR(250) OUTPUT,
    @Line2 VARCHAR(250) OUTPUT,
    @CityIDFK INT OUTPUT,
    @ProvinceIDFK INT OUTPUT,
    @CountryIDFK INT OUTPUT,
    @MaritalStatusIDFK INT OUTPUT,
    @MedicationList VARCHAR(MAX) OUTPUT,
    @EmergencyName VARCHAR(250) OUTPUT,
    @EmergencyLastName VARCHAR(250) OUTPUT,
    @EmergencyPhoneNumber VARCHAR(250) OUTPUT,
    @Relationship VARCHAR(250) OUTPUT,
    @EmergancyDateOfBirth DATETIME OUTPUT,
    @Message VARCHAR(250) OUTPUT,
    @ClientIdFK UNIQUEIDENTIFIER = NULL OUTPUT
)
AS
BEGIN
    DECLARE @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME;

	    SET NOCOUNT ON;

	    BEGIN TRY
            SET @FirstName = '';
            SET @LastName = '';
            SET @ID_Number = '';
            SET @ClientIdFK = NULL;
            SET @DateOfBirth = GETDATE();
            SET @GenderIDFK = 0;
            SET @PhoneNumber = '';
            SET @Email = '';
            SET @Line1 = '';
            SET @Line2 = '';
            SET @CityIDFK = 0;
            SET @ProvinceIDFK = 0;
            SET @CountryIDFK = 0;
            SET @MaritalStatusIDFK = 0;
            SET @MedicationList = '';
            SET @EmergencyName = '';
            SET @EmergencyLastName = '';
            SET @EmergencyPhoneNumber = '';
            SET @Relationship = '';
            SET @EmergancyDateOfBirth = GETDATE();
            SET @Message = '';

            IF @PatientId IS NULL AND LTRIM(RTRIM(@IDNumber)) = ''
            BEGIN
                SET @Message = 'PatientId or IDNumber is required.';
                RETURN;
            END

	        IF EXISTS
            (
                SELECT 1
                FROM Profile.Patient PP
                WHERE
                    (
                        (@PatientId IS NOT NULL AND PP.PatientId = @PatientId)
                        OR
                        (@PatientId IS NULL AND PP.ID_Number = @IDNumber)
                    )
                    AND (@IncludeDeleted = 1 OR PP.IsDeleted = 0)
            )
	        BEGIN
	            SELECT
                @FirstName = PP.FirstName,
                @LastName = PP.LastName,
                @ID_Number = PP.ID_Number,
                @ClientIdFK = PP.ClientIdFK,
                @DateOfBirth = PP.DateOfBirth,
                @GenderIDFK = PP.GenderIDFK,
                @PhoneNumber = CP.PhoneNumber,
                @Email = CE.Email,
                @Line1 = LA.Line1,
                @Line2 = LA.Line2,
                @CityIDFK = LC.CityId,
                @ProvinceIDFK = LP.ProvinceId,
                @CountryIDFK = LCO.CountryId,
                @MaritalStatusIDFK = PP.MaritalStatusIDFK,
                @MedicationList = PP.MedicationList,
                @EmergencyName = CEC.FirstName,
                @EmergencyLastName = CEC.LastName,
                @EmergencyPhoneNumber = CEC.PhoneNumber,
                @Relationship = CEC.Relationship,
                @EmergancyDateOfBirth = CEC.DateOfBirth
            FROM Profile.Patient AS PP
            LEFT JOIN Location.Address AS LA ON PP.AddressIDFK = LA.AddressId
            LEFT JOIN Location.Cities AS LC ON LA.CityIDFK = LC.CityId
            LEFT JOIN Location.Provinces AS LP ON LC.ProvinceIDFK = LP.ProvinceId
            LEFT JOIN Location.Countries AS LCO ON LP.CountryIDFK = LCO.CountryId
            LEFT JOIN Contacts.EmergencyContacts AS CEC ON PP.EmergencyIDFK = CEC.EmergencyId
            -- Pick the most relevant patient email/phone without introducing extra result sets.
            OUTER APPLY
            (
                SELECT TOP (1) PE.EmailIdFK
                FROM Contacts.PatientEmails PE
                WHERE PE.PatientIdFK = PP.PatientId
                ORDER BY PE.IsPrimary DESC, PE.CreatedDate DESC
            ) PE
            LEFT JOIN Contacts.Emails CE ON CE.EmailId = PE.EmailIdFK
            OUTER APPLY
            (
                SELECT TOP (1) PPX.PhoneIdFK
                FROM Contacts.PatientPhones PPX
                WHERE PPX.PatientIdFK = PP.PatientId
                ORDER BY PPX.IsPrimary DESC, PPX.CreatedDate DESC
            ) PH
	            LEFT JOIN Contacts.Phones CP ON CP.PhoneId = PH.PhoneIdFK
	            WHERE
                    (
                        (@PatientId IS NOT NULL AND PP.PatientId = @PatientId)
                        OR
                        (@PatientId IS NULL AND PP.ID_Number = @IDNumber)
                    )
                    AND (@IncludeDeleted = 1 OR PP.IsDeleted = 0);

	            SET @Message = '';
	        END
	        ELSE
	        BEGIN
                IF @PatientId IS NOT NULL
                    SET @Message = 'PatientId does not exist or is soft deleted.';
                ELSE
	                SET @Message = 'ID number does not exist or is soft deleted.';
	        END
	    END TRY
    BEGIN CATCH
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

        SET @Message = 'Failed to retrieve patient record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
