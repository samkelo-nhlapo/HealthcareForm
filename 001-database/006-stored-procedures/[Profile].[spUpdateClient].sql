USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Updates a client row while preserving backward compatibility with legacy first/last-name flows.
-- New facility metadata parameters are optional; when they are omitted, the procedure preserves
-- imported values or derives them from the linked facility city / address rows.
CREATE OR ALTER PROC [Profile].[spUpdateClient]
(
    @ClientId UNIQUEIDENTIFIER,
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
    @IsActive BIT = 1,
    @UpdatedBy VARCHAR(250) = NULL,
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
            @HasLeadingPlus BIT = 0,
            @ExistingDisplayName VARCHAR(250),
            @ExistingOrganizationType VARCHAR(20),
            @ExistingGroupOperator VARCHAR(250),
            @ExistingNetworkSources VARCHAR(500),
            @ExistingDirectoryExternalKey VARCHAR(150),
            @ExistingFacilityCityIDFK INT,
            @ExistingFacilityTownName VARCHAR(250),
            @ExistingFacilityProvinceName VARCHAR(250),
            @ExistingFacilityCountryName VARCHAR(250),
            @ExistingFacilityAddressText VARCHAR(500),
            @ResolvedDisplayName VARCHAR(250),
            @ResolvedOrganizationType VARCHAR(20),
            @ResolvedGroupOperator VARCHAR(250),
            @ResolvedNetworkSources VARCHAR(500),
            @ResolvedDirectoryExternalKey VARCHAR(150),
            @ResolvedFacilityTownName VARCHAR(250),
            @ResolvedFacilityProvinceName VARCHAR(250),
            @ResolvedFacilityCountryName VARCHAR(250),
            @ResolvedFacilityAddressText VARCHAR(500),
            @AddressCityId INT,
            @AddressTownName VARCHAR(250),
            @AddressProvinceName VARCHAR(250),
            @AddressCountryName VARCHAR(250),
            @AddressText VARCHAR(500),
            @FacilityCityName VARCHAR(250),
            @FacilityProvinceLookupName VARCHAR(250),
            @FacilityCountryLookupName VARCHAR(250);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientId is required.';
        RETURN;
    END

    SET @ClientCode = LTRIM(RTRIM(ISNULL(@ClientCode, '')));
    SET @FirstName = LTRIM(RTRIM(ISNULL(@FirstName, '')));
    SET @LastName = LTRIM(RTRIM(ISNULL(@LastName, '')));

    IF @ClientCode = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientCode is required.';
        RETURN;
    END

    IF @FirstName = '' OR @LastName = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FirstName and LastName are required.';
        RETURN;
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

    SELECT
        @ExistingDisplayName = C.DisplayName,
        @ExistingOrganizationType = C.OrganizationType,
        @ExistingGroupOperator = C.GroupOperator,
        @ExistingNetworkSources = C.NetworkSources,
        @ExistingDirectoryExternalKey = C.DirectoryExternalKey,
        @ExistingFacilityCityIDFK = C.FacilityCityIDFK,
        @ExistingFacilityTownName = C.FacilityTownName,
        @ExistingFacilityProvinceName = C.FacilityProvinceName,
        @ExistingFacilityCountryName = C.FacilityCountryName,
        @ExistingFacilityAddressText = C.FacilityAddressText
    FROM Profile.Clients C
    WHERE C.ClientId = @ClientId
      AND C.IsDeleted = 0;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client not found or already deleted.';
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
        SET @FacilityCityIDFK = COALESCE(@AddressCityId, @ExistingFacilityCityIDFK);
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

    SET @ResolvedDisplayName = NULLIF(LTRIM(RTRIM(ISNULL(@DisplayName, ''))), '');
    IF @ResolvedDisplayName IS NULL
    BEGIN
        SET @ResolvedDisplayName = @FirstName;
    END

    SET @ResolvedOrganizationType = NULLIF(LTRIM(RTRIM(ISNULL(@OrganizationType, ''))), '');
    IF @ResolvedOrganizationType IS NULL
    BEGIN
        SET @ResolvedOrganizationType = NULLIF(LTRIM(RTRIM(ISNULL(@ExistingOrganizationType, ''))), '');
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

    SET @ResolvedGroupOperator = NULLIF(LTRIM(RTRIM(ISNULL(@GroupOperator, ''))), '');
    SET @ResolvedNetworkSources = NULLIF(LTRIM(RTRIM(ISNULL(@NetworkSources, ''))), '');
    SET @ResolvedDirectoryExternalKey = NULLIF(LTRIM(RTRIM(ISNULL(@DirectoryExternalKey, ''))), '');
    SET @ResolvedFacilityTownName = NULLIF(LTRIM(RTRIM(ISNULL(@FacilityTownName, ''))), '');
    SET @ResolvedFacilityProvinceName = NULLIF(LTRIM(RTRIM(ISNULL(@FacilityProvinceName, ''))), '');
    SET @ResolvedFacilityCountryName = NULLIF(LTRIM(RTRIM(ISNULL(@FacilityCountryName, ''))), '');
    SET @ResolvedFacilityAddressText = NULLIF(LTRIM(RTRIM(ISNULL(@FacilityAddressText, ''))), '');

    SET @ResolvedGroupOperator = COALESCE(@ResolvedGroupOperator, NULLIF(LTRIM(RTRIM(ISNULL(@ExistingGroupOperator, ''))), ''));
    SET @ResolvedNetworkSources = COALESCE(@ResolvedNetworkSources, NULLIF(LTRIM(RTRIM(ISNULL(@ExistingNetworkSources, ''))), ''));
    SET @ResolvedDirectoryExternalKey = COALESCE(@ResolvedDirectoryExternalKey, NULLIF(LTRIM(RTRIM(ISNULL(@ExistingDirectoryExternalKey, ''))), ''));
    SET @ResolvedFacilityTownName = COALESCE(@ResolvedFacilityTownName, @FacilityCityName, @AddressTownName, NULLIF(LTRIM(RTRIM(ISNULL(@ExistingFacilityTownName, ''))), ''));
    SET @ResolvedFacilityProvinceName = COALESCE(@ResolvedFacilityProvinceName, @FacilityProvinceLookupName, @AddressProvinceName, NULLIF(LTRIM(RTRIM(ISNULL(@ExistingFacilityProvinceName, ''))), ''));
    SET @ResolvedFacilityCountryName = COALESCE(@ResolvedFacilityCountryName, @FacilityCountryLookupName, @AddressCountryName, NULLIF(LTRIM(RTRIM(ISNULL(@ExistingFacilityCountryName, ''))), ''));
    SET @ResolvedFacilityAddressText = COALESCE(@ResolvedFacilityAddressText, @AddressText, NULLIF(LTRIM(RTRIM(ISNULL(@ExistingFacilityAddressText, ''))), ''));

    -- Keep local and international numbers in a consistent stored format.
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
        IF EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientCode = @ClientCode AND ClientId <> @ClientId)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'ClientCode already exists.';
            RETURN;
        END

        IF @ResolvedDirectoryExternalKey IS NOT NULL
           AND EXISTS
           (
               SELECT 1
               FROM Profile.Clients
               WHERE DirectoryExternalKey = @ResolvedDirectoryExternalKey
                 AND ClientId <> @ClientId
           )
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'DirectoryExternalKey already exists.';
            RETURN;
        END

        IF @PatientIdFK IS NOT NULL
           AND EXISTS (SELECT 1 FROM Profile.Clients WHERE PatientIdFK = @PatientIdFK AND ClientId <> @ClientId)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'A client is already linked to this PatientIdFK.';
            RETURN;
        END

        UPDATE Profile.Clients
        SET ClientCode = @ClientCode,
            FirstName = @FirstName,
            LastName = @LastName,
            DisplayName = @ResolvedDisplayName,
            OrganizationType = @ResolvedOrganizationType,
            GroupOperator = @ResolvedGroupOperator,
            NetworkSources = @ResolvedNetworkSources,
            DirectoryExternalKey = @ResolvedDirectoryExternalKey,
            FacilityCityIDFK = @FacilityCityIDFK,
            FacilityTownName = @ResolvedFacilityTownName,
            FacilityProvinceName = @ResolvedFacilityProvinceName,
            FacilityCountryName = @ResolvedFacilityCountryName,
            FacilityAddressText = @ResolvedFacilityAddressText,
            DateOfBirth = @DateOfBirth,
            ID_Number = NULLIF(LTRIM(RTRIM(ISNULL(@ID_Number, ''))), ''),
            Email = NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''),
            PhoneNumber = @FormattedPhone,
            AddressIDFK = @AddressIDFK,
            PatientIdFK = @PatientIdFK,
            ClientClinicCategoryIDFK = @ClientClinicCategoryIDFK,
            IsActive = @IsActive,
            UpdatedDate = @Now,
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ClientId = @ClientId
          AND IsDeleted = 0;

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

        SET @StatusCode = -1;
        SET @Message = 'Failed to update client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
