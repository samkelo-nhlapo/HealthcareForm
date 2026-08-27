USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Upserts a real-world facility record from the hospital-network directory.
-- The procedure keeps imported metadata in the client directory without forcing the
-- caller to understand the legacy person-shaped client schema.
CREATE OR ALTER PROC [Profile].[spUpsertFacilityClient]
(
    @ClientCode VARCHAR(50),
    @DisplayName VARCHAR(250),
    @OrganizationType VARCHAR(20) = NULL,
    @OwnershipType VARCHAR(20) = NULL,
    @Town VARCHAR(250) = NULL,
    @Province VARCHAR(250) = NULL,
    @Country VARCHAR(250) = NULL,
    @GroupOperator VARCHAR(250) = NULL,
    @AddressText VARCHAR(500) = NULL,
    @PhoneNumber VARCHAR(50) = NULL,
    @NetworkSources VARCHAR(500) = NULL,
    @DirectoryExternalKey VARCHAR(150),
    @CreatedBy VARCHAR(250) = NULL,
    @ClientIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @ResolvedOrganizationType VARCHAR(20),
            @ResolvedOwnershipType VARCHAR(20),
            @ResolvedCategoryName VARCHAR(100),
            @ResolvedClientClinicCategoryIDFK INT,
            @CountryId INT,
            @ProvinceId INT,
            @FacilityCityIDFK INT,
            @ExistingClientId UNIQUEIDENTIFIER,
            @ExistingIsDeleted BIT,
            @ExistingDateOfBirth DATETIME,
            @ExistingIDNumber VARCHAR(250),
            @ExistingEmail VARCHAR(250),
            @ExistingAddressIDFK UNIQUEIDENTIFIER,
            @ExistingPatientIdFK UNIQUEIDENTIFIER,
            @UpperName VARCHAR(250),
            @UpperOperator VARCHAR(250);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ClientIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    SET @ClientCode = LTRIM(RTRIM(ISNULL(@ClientCode, '')));
    SET @DisplayName = LTRIM(RTRIM(ISNULL(@DisplayName, '')));
    SET @OrganizationType = NULLIF(LTRIM(RTRIM(ISNULL(@OrganizationType, ''))), '');
    SET @OwnershipType = NULLIF(LTRIM(RTRIM(ISNULL(@OwnershipType, ''))), '');
    SET @Town = NULLIF(LTRIM(RTRIM(ISNULL(@Town, ''))), '');
    SET @Province = NULLIF(LTRIM(RTRIM(ISNULL(@Province, ''))), '');
    SET @Country = NULLIF(LTRIM(RTRIM(ISNULL(@Country, ''))), '');
    SET @GroupOperator = NULLIF(LTRIM(RTRIM(ISNULL(@GroupOperator, ''))), '');
    SET @AddressText = NULLIF(LTRIM(RTRIM(ISNULL(@AddressText, ''))), '');
    SET @PhoneNumber = NULLIF(LTRIM(RTRIM(ISNULL(@PhoneNumber, ''))), '');
    SET @NetworkSources = NULLIF(LTRIM(RTRIM(ISNULL(@NetworkSources, ''))), '');
    SET @DirectoryExternalKey = NULLIF(LTRIM(RTRIM(ISNULL(@DirectoryExternalKey, ''))), '');
    SET @CreatedBy = COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(@CreatedBy, ''))), ''), 'Directory Import');

    IF @ClientCode = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientCode is required.';
        RETURN;
    END

    IF @DisplayName = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DisplayName is required.';
        RETURN;
    END

    IF @DirectoryExternalKey IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DirectoryExternalKey is required.';
        RETURN;
    END

    SET @UpperName = UPPER(@DisplayName);
    SET @UpperOperator = UPPER(ISNULL(@GroupOperator, ''));

    SET @ResolvedOrganizationType = @OrganizationType;
    IF @ResolvedOrganizationType IS NULL
    BEGIN
        SET @ResolvedOrganizationType =
            CASE
                WHEN @UpperName LIKE '%HOSPITAL%' THEN 'Hospital'
                WHEN @UpperName LIKE '%CLINIC%' OR @UpperName LIKE '%MEDICAL%' OR @UpperName LIKE '%TREATMENT%' OR @UpperName LIKE '%CENTRE%' OR @UpperName LIKE '%CENTER%' THEN 'Clinic'
                ELSE 'Clinic'
            END;
    END

    IF @ResolvedOrganizationType NOT IN ('Clinic', 'Hospital')
    BEGIN
        SET @ResolvedOrganizationType =
            CASE
                WHEN @ResolvedOrganizationType = 'Organization' THEN 'Clinic'
                ELSE @ResolvedOrganizationType
            END;
    END

    IF @ResolvedOrganizationType NOT IN ('Clinic', 'Hospital')
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'OrganizationType must resolve to Clinic or Hospital for directory imports.';
        RETURN;
    END

    SET @ResolvedOwnershipType = @OwnershipType;
    IF @ResolvedOwnershipType IS NULL
    BEGIN
        SET @ResolvedOwnershipType =
            CASE
                WHEN @UpperName LIKE '%PRIVATE%'
                  OR @UpperOperator IN ('NETCARE', 'LIFE HEALTHCARE', 'MEDICLINIC', 'LENMED', 'AKESO', 'CLINIX', 'INTERCARE', 'BUSAMED', 'MEDICROSS', 'MELOMED', 'NHN', 'NURTURE')
                    THEN 'Private'
                WHEN @UpperName LIKE '%DISTRICT%'
                  OR @UpperName LIKE '%PROVINCIAL%'
                  OR @UpperName LIKE '%REGIONAL%'
                  OR @UpperName LIKE '%ACADEMIC%'
                  OR @UpperName LIKE '%COMMUNITY%'
                  OR @UpperName LIKE '%GOVERNMENT%'
                  OR @UpperName LIKE '%MILITARY%'
                    THEN 'Public'
                ELSE 'Unknown'
            END;
    END

    IF @ResolvedOwnershipType NOT IN ('Private', 'Public', 'Unknown')
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'OwnershipType must be Private, Public, or Unknown.';
        RETURN;
    END

    IF @Country IS NULL
    BEGIN
        SET @Country = 'South Africa';
    END

    SET @ResolvedCategoryName = CONCAT(@ResolvedOwnershipType, ' ', @ResolvedOrganizationType);

    SELECT TOP (1) @ResolvedClientClinicCategoryIDFK = CCC.ClientClinicCategoryId
    FROM Profile.ClientClinicCategories CCC
    WHERE CCC.IsActive = 1
      AND CCC.CategoryName = @ResolvedCategoryName
    ORDER BY CASE WHEN CCC.ClinicSize = 'Unknown' THEN 0 ELSE 1 END, CCC.ClientClinicCategoryId;

    IF @ResolvedClientClinicCategoryIDFK IS NULL
    BEGIN
        SELECT TOP (1) @ResolvedClientClinicCategoryIDFK = CCC.ClientClinicCategoryId
        FROM Profile.ClientClinicCategories CCC
        WHERE CCC.IsActive = 1
          AND CCC.CategoryName LIKE '%' + @ResolvedOrganizationType + '%'
          AND CCC.OwnershipType = @ResolvedOwnershipType
        ORDER BY CASE WHEN CCC.ClinicSize = 'Unknown' THEN 0 ELSE 1 END, CCC.ClientClinicCategoryId;
    END

    IF @ResolvedClientClinicCategoryIDFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'No active client category matches the imported facility.';
        RETURN;
    END

    SELECT @CountryId = CountryId
    FROM Location.Countries
    WHERE CountryName = @Country;

    IF @CountryId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Country does not exist in Location.Countries.';
        RETURN;
    END

    SET @ProvinceId = NULL;
    SET @FacilityCityIDFK = NULL;

    IF @Province IS NOT NULL
    BEGIN
        SELECT @ProvinceId = ProvinceId
        FROM Location.Provinces
        WHERE ProvinceName = @Province
          AND CountryIDFK = @CountryId;

        IF @ProvinceId IS NULL
        BEGIN
            INSERT INTO Location.Provinces
            (
                ProvinceName,
                CountryIDFK,
                IsActive,
                UpdateDate
            )
            VALUES
            (
                @Province,
                @CountryId,
                1,
                @Now
            );

            SET @ProvinceId = SCOPE_IDENTITY();
        END
    END

    IF @Town IS NOT NULL AND @ProvinceId IS NOT NULL
    BEGIN
        SELECT @FacilityCityIDFK = CityId
        FROM Location.Cities
        WHERE CityName = @Town
          AND ProvinceIDFK = @ProvinceId;

        IF @FacilityCityIDFK IS NULL
        BEGIN
            INSERT INTO Location.Cities
            (
                CityName,
                ProvinceIDFK,
                IsActive,
                UpdateDate
            )
            VALUES
            (
                @Town,
                @ProvinceId,
                1,
                @Now
            );

            SET @FacilityCityIDFK = SCOPE_IDENTITY();
        END
    END

    SELECT
        @ExistingClientId = C.ClientId,
        @ExistingIsDeleted = C.IsDeleted,
        @ExistingDateOfBirth = C.DateOfBirth,
        @ExistingIDNumber = C.ID_Number,
        @ExistingEmail = C.Email,
        @ExistingAddressIDFK = C.AddressIDFK,
        @ExistingPatientIdFK = C.PatientIdFK
    FROM Profile.Clients C
    WHERE C.DirectoryExternalKey = @DirectoryExternalKey;

    IF @ExistingClientId IS NOT NULL
    BEGIN
        IF @ExistingIsDeleted = 1
        BEGIN
            UPDATE Profile.Clients
            SET IsDeleted = 0,
                IsActive = 1,
                UpdatedDate = @Now,
                UpdatedBy = @CreatedBy
            WHERE ClientId = @ExistingClientId;
        END

        EXEC [Profile].[spUpdateClient]
            @ClientId = @ExistingClientId,
            @ClientCode = @ClientCode,
            @FirstName = @DisplayName,
            @LastName = @DisplayName,
            @DateOfBirth = @ExistingDateOfBirth,
            @ID_Number = @ExistingIDNumber,
            @Email = @ExistingEmail,
            @PhoneNumber = @PhoneNumber,
            @AddressIDFK = @ExistingAddressIDFK,
            @PatientIdFK = @ExistingPatientIdFK,
            @ClientClinicCategoryIDFK = @ResolvedClientClinicCategoryIDFK,
            @FacilityCityIDFK = @FacilityCityIDFK,
            @DisplayName = @DisplayName,
            @OrganizationType = @ResolvedOrganizationType,
            @GroupOperator = @GroupOperator,
            @NetworkSources = @NetworkSources,
            @DirectoryExternalKey = @DirectoryExternalKey,
            @FacilityTownName = @Town,
            @FacilityProvinceName = @Province,
            @FacilityCountryName = @Country,
            @FacilityAddressText = @AddressText,
            @IsActive = 1,
            @UpdatedBy = @CreatedBy,
            @StatusCode = @StatusCode OUTPUT,
            @Message = @Message OUTPUT;

        SET @ClientIdOutput = @ExistingClientId;
        RETURN;
    END

    EXEC [Profile].[spAddClient]
        @ClientCode = @ClientCode,
        @FirstName = @DisplayName,
        @LastName = @DisplayName,
        @DateOfBirth = NULL,
        @ID_Number = NULL,
        @Email = NULL,
        @PhoneNumber = @PhoneNumber,
        @AddressIDFK = NULL,
        @PatientIdFK = NULL,
        @ClientClinicCategoryIDFK = @ResolvedClientClinicCategoryIDFK,
        @FacilityCityIDFK = @FacilityCityIDFK,
        @DisplayName = @DisplayName,
        @OrganizationType = @ResolvedOrganizationType,
        @GroupOperator = @GroupOperator,
        @NetworkSources = @NetworkSources,
        @DirectoryExternalKey = @DirectoryExternalKey,
        @FacilityTownName = @Town,
        @FacilityProvinceName = @Province,
        @FacilityCountryName = @Country,
        @FacilityAddressText = @AddressText,
        @CreatedBy = @CreatedBy,
        @ClientIdOutput = @ClientIdOutput OUTPUT,
        @StatusCode = @StatusCode OUTPUT,
        @Message = @Message OUTPUT;
END
GO
