USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Creates a client record and optionally links it to a patient, city, address, and clinic category.
-- The proc remains backward compatible with legacy first/last-name usage while supporting real-world organisations.
CREATE OR ALTER PROC [Profile].[spAddClient]
(
    @ClientCode VARCHAR(50),
    @FirstName VARCHAR(250),
    @LastName VARCHAR(250),
    @DateOfBirth DATETIME = NULL,
    @ID_Number VARCHAR(250) = NULL,
    @Email VARCHAR(250) = NULL,
    @PhoneNumber VARCHAR(50) = NULL,
    @AddressIDFK UNIQUEIDENTIFIER = NULL,
    @PatientIdFK UNIQUEIDENTIFIER = NULL,
    @ClientClinicCategoryIDFK INT = NULL,
    @FacilityCityIDFK INT = NULL,
    @DisplayName VARCHAR(250) = NULL,
    @OrganizationType VARCHAR(20) = NULL,
    @GroupOperator VARCHAR(250) = NULL,
    @NetworkSources VARCHAR(500) = NULL,
    @DirectoryExternalKey VARCHAR(150) = NULL,
    @FacilityTownName VARCHAR(250) = NULL,
    @FacilityProvinceName VARCHAR(250) = NULL,
    @FacilityCountryName VARCHAR(250) = NULL,
    @FacilityAddressText VARCHAR(500) = NULL,
    @CreatedBy VARCHAR(250) = NULL,
    @ClientIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @UserName VARCHAR(200),
            @ErrorSchema VARCHAR(200),
            @ErrorProc VARCHAR(200),
            @ErrorNumber INT,
            @ErrorState INT,
            @ErrorSeverity INT,
            @ErrorLine INT,
            @ErrorMessage VARCHAR(MAX),
            @ErrorDateTime DATETIME,
            @NormalizedPhone VARCHAR(50),
            @FormattedPhone VARCHAR(50),
            @DigitsOnly VARCHAR(50),
            @ResolvedDisplayName VARCHAR(250),
            @ResolvedFirstName VARCHAR(250),
            @ResolvedLastName VARCHAR(250),
            @ResolvedOrganizationType VARCHAR(20),
            @AddressCityId INT,
            @AddressTownName VARCHAR(250),
            @AddressProvinceName VARCHAR(250),
            @AddressCountryName VARCHAR(250),
            @AddressText VARCHAR(500),
            @FacilityCityName VARCHAR(250),
            @FacilityProvinceLookupName VARCHAR(250),
            @FacilityCountryLookupName VARCHAR(250),
            @ResolvedFacilityTownName VARCHAR(250),
            @ResolvedFacilityProvinceName VARCHAR(250),
            @ResolvedFacilityCountryName VARCHAR(250),
            @ResolvedFacilityAddressText VARCHAR(500),
            @HasLeadingPlus BIT = 0;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ClientIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    SET @ClientCode = LTRIM(RTRIM(ISNULL(@ClientCode, '')));
    SET @ResolvedFirstName = NULLIF(LTRIM(RTRIM(ISNULL(@FirstName, ''))), '');
    SET @ResolvedLastName = NULLIF(LTRIM(RTRIM(ISNULL(@LastName, ''))), '');
    SET @ResolvedDisplayName = NULLIF(LTRIM(RTRIM(ISNULL(@DisplayName, ''))), '');
    SET @ResolvedOrganizationType = NULLIF(LTRIM(RTRIM(ISNULL(@OrganizationType, ''))), '');
    SET @GroupOperator = NULLIF(LTRIM(RTRIM(ISNULL(@GroupOperator, ''))), '');
    SET @NetworkSources = NULLIF(LTRIM(RTRIM(ISNULL(@NetworkSources, ''))), '');
    SET @DirectoryExternalKey = NULLIF(LTRIM(RTRIM(ISNULL(@DirectoryExternalKey, ''))), '');
    SET @ResolvedFacilityTownName = NULLIF(LTRIM(RTRIM(ISNULL(@FacilityTownName, ''))), '');
    SET @ResolvedFacilityProvinceName = NULLIF(LTRIM(RTRIM(ISNULL(@FacilityProvinceName, ''))), '');
    SET @ResolvedFacilityCountryName = NULLIF(LTRIM(RTRIM(ISNULL(@FacilityCountryName, ''))), '');
    SET @ResolvedFacilityAddressText = NULLIF(LTRIM(RTRIM(ISNULL(@FacilityAddressText, ''))), '');

    IF @ClientCode = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientCode is required.';
        RETURN;
    END

    IF @ResolvedDisplayName IS NULL AND @ResolvedFirstName IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DisplayName or FirstName is required.';
        RETURN;
    END

    IF @ResolvedDisplayName IS NULL
    BEGIN
        SET @ResolvedDisplayName = @ResolvedFirstName;
    END

    IF @ResolvedFirstName IS NULL
    BEGIN
        SET @ResolvedFirstName = @ResolvedDisplayName;
    END

    IF @ResolvedLastName IS NULL
    BEGIN
        SET @ResolvedLastName = @ResolvedDisplayName;
    END

    IF @DateOfBirth IS NOT NULL AND @DateOfBirth > GETDATE()
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DateOfBirth cannot be in the future.';
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
       AND @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid email format.';
        RETURN;
    END

    IF @AddressIDFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Location.Address WHERE AddressId = @AddressIDFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'AddressIDFK does not exist.';
        RETURN;
    END

    IF @AddressIDFK IS NOT NULL
    BEGIN
        SELECT
            @AddressCityId = A.CityIDFK,
            @AddressTownName = C.CityName,
            @AddressProvinceName = P.ProvinceName,
            @AddressCountryName = CO.CountryName,
            @AddressText =
                NULLIF(
                    LTRIM(RTRIM(
                        CONCAT(
                            ISNULL(A.Line1, ''),
                            CASE
                                WHEN NULLIF(LTRIM(RTRIM(ISNULL(A.Line2, ''))), '') IS NULL THEN ''
                                ELSE ', ' + LTRIM(RTRIM(A.Line2))
                            END
                        )
                    )),
                    ''
                )
        FROM Location.Address A
        INNER JOIN Location.Cities C ON C.CityId = A.CityIDFK
        INNER JOIN Location.Provinces P ON P.ProvinceId = C.ProvinceIDFK
        INNER JOIN Location.Countries CO ON CO.CountryId = P.CountryIDFK
        WHERE A.AddressId = @AddressIDFK;
    END
    ELSE
    BEGIN
        SET @AddressCityId = NULL;
        SET @AddressTownName = NULL;
        SET @AddressProvinceName = NULL;
        SET @AddressCountryName = NULL;
        SET @AddressText = NULL;
    END

    IF @FacilityCityIDFK IS NULL
    BEGIN
        SET @FacilityCityIDFK = @AddressCityId;
    END

    IF @FacilityCityIDFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Location.Cities WHERE CityId = @FacilityCityIDFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FacilityCityIDFK does not exist.';
        RETURN;
    END

    IF @FacilityCityIDFK IS NOT NULL
    BEGIN
        SELECT
            @FacilityCityName = C.CityName,
            @FacilityProvinceLookupName = P.ProvinceName,
            @FacilityCountryLookupName = CO.CountryName
        FROM Location.Cities C
        INNER JOIN Location.Provinces P ON P.ProvinceId = C.ProvinceIDFK
        INNER JOIN Location.Countries CO ON CO.CountryId = P.CountryIDFK
        WHERE C.CityId = @FacilityCityIDFK;
    END
    ELSE
    BEGIN
        SET @FacilityCityName = NULL;
        SET @FacilityProvinceLookupName = NULL;
        SET @FacilityCountryLookupName = NULL;
    END

    IF @AddressCityId IS NOT NULL
       AND @FacilityCityIDFK IS NOT NULL
       AND @AddressCityId <> @FacilityCityIDFK
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FacilityCityIDFK must match the city on AddressIDFK when both are supplied.';
        RETURN;
    END

    IF @PatientIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.Patient WHERE PatientId = @PatientIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'PatientIdFK does not exist.';
        RETURN;
    END

    IF @ClientClinicCategoryIDFK IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Profile.ClientClinicCategories CCC
           WHERE CCC.ClientClinicCategoryId = @ClientClinicCategoryIDFK
             AND CCC.IsActive = 1
       )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientClinicCategoryIDFK does not exist or is inactive.';
        RETURN;
    END

    IF @ResolvedFacilityTownName IS NULL
    BEGIN
        SET @ResolvedFacilityTownName = COALESCE(@FacilityCityName, @AddressTownName);
    END

    IF @ResolvedFacilityProvinceName IS NULL
    BEGIN
        SET @ResolvedFacilityProvinceName = COALESCE(@FacilityProvinceLookupName, @AddressProvinceName);
    END

    IF @ResolvedFacilityCountryName IS NULL
    BEGIN
        SET @ResolvedFacilityCountryName = COALESCE(@FacilityCountryLookupName, @AddressCountryName);
    END

    IF @ResolvedFacilityAddressText IS NULL
    BEGIN
        SET @ResolvedFacilityAddressText = @AddressText;
    END

    IF @ResolvedOrganizationType IS NULL AND @ClientClinicCategoryIDFK IS NOT NULL
    BEGIN
        SELECT @ResolvedOrganizationType =
            CASE
                WHEN CCC.CategoryName LIKE '%Hospital%' THEN 'Hospital'
                WHEN CCC.CategoryName LIKE '%Clinic%' THEN 'Clinic'
                ELSE 'Organization'
            END
        FROM Profile.ClientClinicCategories CCC
        WHERE CCC.ClientClinicCategoryId = @ClientClinicCategoryIDFK;
    END

    IF @ResolvedOrganizationType IS NULL
    BEGIN
        SET @ResolvedOrganizationType = 'Organization';
    END

    IF @ResolvedOrganizationType NOT IN ('Clinic', 'Hospital', 'Organization', 'Other')
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'OrganizationType must be Clinic, Hospital, Organization, or Other.';
        RETURN;
    END

    -- Accept local 10-digit numbers and international E.164-style numbers up to 15 digits.
    SET @NormalizedPhone = LTRIM(RTRIM(ISNULL(@PhoneNumber, '')));
    IF @NormalizedPhone <> ''
    BEGIN
        SET @HasLeadingPlus = CASE WHEN LEFT(@NormalizedPhone, 1) = '+' THEN 1 ELSE 0 END;
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ' ', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '-', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '(', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ')', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '.', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '/', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '\', '');

        IF LEFT(@NormalizedPhone, 2) = '00'
        BEGIN
            SET @NormalizedPhone = '+' + SUBSTRING(@NormalizedPhone, 3, 48);
        END
        ELSE IF @HasLeadingPlus = 1 AND LEFT(@NormalizedPhone, 1) <> '+'
        BEGIN
            SET @NormalizedPhone = '+' + @NormalizedPhone;
        END

        SET @DigitsOnly = REPLACE(@NormalizedPhone, '+', '');

        IF LEN(@DigitsOnly) < 7 OR LEN(@DigitsOnly) > 15 OR @DigitsOnly LIKE '%[^0-9]%'
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'PhoneNumber must contain between 7 and 15 digits after removing punctuation.';
            RETURN;
        END

        IF LEFT(@NormalizedPhone, 1) <> '+' AND LEN(@DigitsOnly) = 10
        BEGIN
            SET @FormattedPhone = SUBSTRING(@DigitsOnly, 1, 3) + '-' +
                                  SUBSTRING(@DigitsOnly, 4, 3) + '-' +
                                  SUBSTRING(@DigitsOnly, 7, 4);
        END
        ELSE
        BEGIN
            SET @FormattedPhone = CASE WHEN LEFT(@NormalizedPhone, 1) = '+' THEN '+' ELSE '' END + @DigitsOnly;
        END
    END
    ELSE
    BEGIN
        SET @FormattedPhone = NULL;
    END

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientCode = @ClientCode)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'ClientCode already exists.';
            RETURN;
        END

        IF @DirectoryExternalKey IS NOT NULL
           AND EXISTS (SELECT 1 FROM Profile.Clients WHERE DirectoryExternalKey = @DirectoryExternalKey)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'DirectoryExternalKey already exists.';
            RETURN;
        END

        IF @PatientIdFK IS NOT NULL
           AND EXISTS (SELECT 1 FROM Profile.Clients WHERE PatientIdFK = @PatientIdFK)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'A client is already linked to this PatientIdFK.';
            RETURN;
        END

        SET @ClientIdOutput = NEWID();

        INSERT INTO Profile.Clients
        (
            ClientId, PatientIdFK, ClientClinicCategoryIDFK, FacilityCityIDFK, ClientCode,
            DisplayName, OrganizationType, GroupOperator, NetworkSources, DirectoryExternalKey,
            FacilityTownName, FacilityProvinceName, FacilityCountryName, FacilityAddressText,
            FirstName, LastName, DateOfBirth, ID_Number, Email, PhoneNumber, AddressIDFK,
            IsActive, IsDeleted, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy
        )
        VALUES
        (
            @ClientIdOutput, @PatientIdFK, @ClientClinicCategoryIDFK, @FacilityCityIDFK, @ClientCode,
            @ResolvedDisplayName, @ResolvedOrganizationType, @GroupOperator, @NetworkSources, @DirectoryExternalKey,
            @ResolvedFacilityTownName, @ResolvedFacilityProvinceName, @ResolvedFacilityCountryName, @ResolvedFacilityAddressText,
            @ResolvedFirstName, @ResolvedLastName, @DateOfBirth, NULLIF(LTRIM(RTRIM(ISNULL(@ID_Number, ''))), ''),
            NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''), @FormattedPhone, @AddressIDFK,
            1, 0, @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME()), @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
        );

        SET @StatusCode = 0;
        SET @Message = '';
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
                        UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                        ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
                    )
                    VALUES
                    (
                        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                        @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
                    );
                END
            END CATCH
        END
        ELSE IF OBJECT_ID('Exceptions.Errors', 'U') IS NOT NULL
        BEGIN
            INSERT INTO Exceptions.Errors
            (
                UserName, ErrorSchema, ErrorProcedure, ErrorNumber,
                ErrorState, ErrorSeverity, ErrorLine, ErrorMessage, ErrorDateTime
            )
            VALUES
            (
                @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber,
                @ErrorState, @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
            );
        END

        SET @ClientIdOutput = NULL;
        SET @StatusCode = -1;
        SET @Message = 'Failed to add client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
