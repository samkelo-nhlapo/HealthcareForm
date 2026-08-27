USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns a paged client roster with organisation metadata, directory-import fields,
-- and resolved location details for admin and directory screens.
CREATE OR ALTER PROC [Profile].[spListClients]
(
    @SearchTerm VARCHAR(250) = '',
    @ClientClinicCategoryIDFK INT = 0,
    @ClinicSize VARCHAR(20) = '',
    @OwnershipType VARCHAR(20) = '',
    @IsActive BIT = NULL,
    @IsDeleted BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Offset INT,
            @NormalizedSearchTerm VARCHAR(250),
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

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 25;
    IF @PageSize > 200 SET @PageSize = 200;

    SET @Offset = (@PageNumber - 1) * @PageSize;
    SET @TotalRecords = 0;
    SET @Message = '';
    SET @NormalizedSearchTerm = LTRIM(RTRIM(ISNULL(@SearchTerm, '')));

    BEGIN TRY
        ;WITH Base AS
        (
            SELECT
                C.ClientId,
                C.PatientIdFK,
                C.ClientClinicCategoryIDFK,
                CCC.CategoryName AS ClientClinicCategoryName,
                CCC.ClinicSize,
                CCC.OwnershipType,
                C.ClientCode,
                C.DisplayName,
                C.OrganizationType,
                C.GroupOperator,
                C.NetworkSources,
                C.DirectoryExternalKey,
                C.FirstName,
                C.LastName,
                C.DateOfBirth,
                C.ID_Number,
                C.Email,
                C.PhoneNumber,
                C.AddressIDFK,
                LA.Line1,
                LA.Line2,
                LA.CityIDFK,
                C.FacilityCityIDFK,
                FacilityTownName = COALESCE(NULLIF(C.FacilityTownName, ''), FC.CityName, AC.CityName, ''),
                FacilityProvinceName = COALESCE(NULLIF(C.FacilityProvinceName, ''), FP.ProvinceName, AP.ProvinceName, ''),
                FacilityCountryName = COALESCE(NULLIF(C.FacilityCountryName, ''), FCO.CountryName, ACO.CountryName, ''),
                FacilityAddressText =
                    COALESCE(
                        NULLIF(C.FacilityAddressText, ''),
                        NULLIF(
                            LTRIM(RTRIM(
                                CONCAT(
                                    ISNULL(LA.Line1, ''),
                                    CASE
                                        WHEN NULLIF(LTRIM(RTRIM(ISNULL(LA.Line2, ''))), '') IS NULL THEN ''
                                        ELSE ', ' + LTRIM(RTRIM(LA.Line2))
                                    END
                                )
                            )),
                            ''
                        ),
                        ''
                    ),
                C.IsActive,
                C.IsDeleted,
                C.CreatedDate,
                C.UpdatedDate
            FROM Profile.Clients C
            LEFT JOIN Location.Address LA ON LA.AddressId = C.AddressIDFK
            LEFT JOIN Location.Cities AC ON AC.CityId = LA.CityIDFK
            LEFT JOIN Location.Provinces AP ON AP.ProvinceId = AC.ProvinceIDFK
            LEFT JOIN Location.Countries ACO ON ACO.CountryId = AP.CountryIDFK
            LEFT JOIN Location.Cities FC ON FC.CityId = C.FacilityCityIDFK
            LEFT JOIN Location.Provinces FP ON FP.ProvinceId = FC.ProvinceIDFK
            LEFT JOIN Location.Countries FCO ON FCO.CountryId = FP.CountryIDFK
            LEFT JOIN Profile.ClientClinicCategories CCC ON CCC.ClientClinicCategoryId = C.ClientClinicCategoryIDFK
            WHERE
                (
                    @NormalizedSearchTerm = ''
                    OR C.ClientCode LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(C.DisplayName, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR C.FirstName LIKE '%' + @NormalizedSearchTerm + '%'
                    OR C.LastName LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(C.ID_Number, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(C.Email, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(C.PhoneNumber, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(C.GroupOperator, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(C.NetworkSources, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(C.FacilityTownName, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(C.FacilityProvinceName, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(C.FacilityCountryName, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(C.FacilityAddressText, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(FC.CityName, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(FP.ProvinceName, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(FCO.CountryName, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(AC.CityName, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(AP.ProvinceName, '') LIKE '%' + @NormalizedSearchTerm + '%'
                    OR ISNULL(ACO.CountryName, '') LIKE '%' + @NormalizedSearchTerm + '%'
                )
                AND (@ClientClinicCategoryIDFK = 0 OR C.ClientClinicCategoryIDFK = @ClientClinicCategoryIDFK)
                AND (@ClinicSize = '' OR ISNULL(CCC.ClinicSize, '') = @ClinicSize)
                AND (@OwnershipType = '' OR ISNULL(CCC.OwnershipType, '') = @OwnershipType)
                AND (@IsActive IS NULL OR C.IsActive = @IsActive)
                AND (@IsDeleted IS NULL OR C.IsDeleted = @IsDeleted)
        ),
        Numbered AS
        (
            SELECT
                B.*,
                COUNT(1) OVER () AS TotalRows,
                ROW_NUMBER() OVER
                (
                    ORDER BY
                        COALESCE(NULLIF(B.DisplayName, ''), NULLIF(B.LastName, ''), NULLIF(B.FirstName, ''), B.ClientCode) ASC,
                        B.ClientCode ASC,
                        B.ClientId ASC
                ) AS RowNum
            FROM Base B
        )
        SELECT
            ClientId,
            PatientIdFK,
            ClientClinicCategoryIDFK,
            ClientClinicCategoryName,
            ClinicSize,
            OwnershipType,
            ClientCode,
            DisplayName,
            OrganizationType,
            GroupOperator,
            NetworkSources,
            DirectoryExternalKey,
            FirstName,
            LastName,
            DateOfBirth,
            ID_Number,
            Email,
            PhoneNumber,
            AddressIDFK,
            Line1,
            Line2,
            CityIDFK,
            FacilityCityIDFK,
            FacilityTownName,
            FacilityProvinceName,
            FacilityCountryName,
            FacilityAddressText,
            IsActive,
            IsDeleted,
            CreatedDate,
            UpdatedDate,
            TotalRows,
            RowNum
        INTO #Numbered
        FROM Numbered;

        SELECT
            ClientId,
            PatientIdFK,
            ClientClinicCategoryIDFK,
            ClientClinicCategoryName,
            ClinicSize,
            OwnershipType,
            ClientCode,
            DisplayName,
            OrganizationType,
            GroupOperator,
            NetworkSources,
            DirectoryExternalKey,
            FirstName,
            LastName,
            DateOfBirth,
            ID_Number,
            Email,
            PhoneNumber,
            AddressIDFK,
            Line1,
            Line2,
            CityIDFK,
            FacilityCityIDFK,
            FacilityTownName,
            FacilityProvinceName,
            FacilityCountryName,
            FacilityAddressText,
            IsActive,
            IsDeleted,
            CreatedDate,
            UpdatedDate
        FROM #Numbered
        WHERE RowNum > @Offset
          AND RowNum <= (@Offset + @PageSize)
        ORDER BY RowNum;

        SELECT @TotalRecords = ISNULL(MAX(TotalRows), 0)
        FROM #Numbered;

        DROP TABLE #Numbered;

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

        SET @TotalRecords = 0;
        SET @Message = 'Failed to retrieve clients list.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
