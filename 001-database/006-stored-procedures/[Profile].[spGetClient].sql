USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Loads one client by ID or client code with resolved organisation metadata and facility location.
CREATE OR ALTER PROC [Profile].[spGetClient]
(
    @ClientId UNIQUEIDENTIFIER = NULL,
    @ClientCode VARCHAR(50) = '',
    @IncludeDeleted BIT = 0,
    @Message VARCHAR(250) OUTPUT
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
    SET @Message = '';
    SET @ClientCode = LTRIM(RTRIM(ISNULL(@ClientCode, '')));

    BEGIN TRY
        IF @ClientId IS NULL AND @ClientCode = ''
        BEGIN
            SET @Message = 'ClientId or ClientCode is required.';
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND (@IncludeDeleted = 1 OR C.IsDeleted = 0)
        )
        BEGIN
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
                C.CreatedBy,
                C.UpdatedDate,
                C.UpdatedBy
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
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND (@IncludeDeleted = 1 OR C.IsDeleted = 0);

            SET @Message = '';
        END
        ELSE
        BEGIN
            SET @Message = 'Client not found.';
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

        SET @Message = 'Failed to retrieve client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
