USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns a paged patient directory with preferred contact and location data already flattened.
-- This is the broader legacy list proc; the API worklist proc handles the richer clinical dashboard view.
CREATE OR ALTER PROC [Profile].[spListPatients]
(
    @SearchTerm VARCHAR(250) = '',
    @GenderIDFK INT = 0,
    @MaritalStatusIDFK INT = 0,
    @CityIDFK INT = 0,
    @IsDeleted BIT = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 25,
    @TotalRecords INT OUTPUT,
    @Message VARCHAR(250) OUTPUT,
    @ClientIdFK UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
    DECLARE @Offset INT,
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

    BEGIN TRY
        ;WITH PatientBase AS
        (
            SELECT
                P.PatientId,
                P.FirstName,
                P.LastName,
                P.ID_Number,
                P.DateOfBirth,
                P.GenderIDFK,
                P.MaritalStatusIDFK,
                P.ClientIdFK,
                P.MedicationList,
                P.IsDeleted,
                P.CreatedDate,
                P.UpdatedDate,
                CE.Email,
                CP.PhoneNumber,
                LA.Line1,
                LA.Line2,
                LC.CityId,
                LC.CityName,
                LP.ProvinceId,
                LP.ProvinceName,
                LCO.CountryId,
                LCO.CountryName
            FROM Profile.Patient P
            LEFT JOIN Location.Address LA ON LA.AddressId = P.AddressIDFK
            LEFT JOIN Location.Cities LC ON LC.CityId = LA.CityIDFK
            LEFT JOIN Location.Provinces LP ON LP.ProvinceId = LC.ProvinceIDFK
            LEFT JOIN Location.Countries LCO ON LCO.CountryId = LP.CountryIDFK
            -- Pick one preferred email row per patient so the result stays one row per patient.
            OUTER APPLY
            (
                SELECT TOP (1) PE.EmailIdFK
                FROM Contacts.PatientEmails PE
                WHERE PE.PatientIdFK = P.PatientId
                ORDER BY PE.IsPrimary DESC, PE.CreatedDate DESC
            ) PE1
            LEFT JOIN Contacts.Emails CE ON CE.EmailId = PE1.EmailIdFK
            -- Pick one preferred phone row per patient for the same reason.
            OUTER APPLY
            (
                SELECT TOP (1) PP.PhoneIdFK
                FROM Contacts.PatientPhones PP
                WHERE PP.PatientIdFK = P.PatientId
                ORDER BY PP.IsPrimary DESC, PP.CreatedDate DESC
            ) PP1
            LEFT JOIN Contacts.Phones CP ON CP.PhoneId = PP1.PhoneIdFK
            WHERE
                (
                    @SearchTerm = ''
                    OR P.FirstName LIKE '%' + @SearchTerm + '%'
                    OR P.LastName LIKE '%' + @SearchTerm + '%'
                    OR P.ID_Number LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(CE.Email, '') LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(CP.PhoneNumber, '') LIKE '%' + @SearchTerm + '%'
                )
                AND (@ClientIdFK IS NULL OR P.ClientIdFK = @ClientIdFK)
                AND (@GenderIDFK = 0 OR P.GenderIDFK = @GenderIDFK)
                AND (@MaritalStatusIDFK = 0 OR P.MaritalStatusIDFK = @MaritalStatusIDFK)
                AND (@CityIDFK = 0 OR LC.CityId = @CityIDFK)
                AND (@IsDeleted IS NULL OR P.IsDeleted = @IsDeleted)
        ),
        Numbered AS
        (
            SELECT
                PB.*,
                COUNT(1) OVER () AS TotalRows,
                ROW_NUMBER() OVER (ORDER BY PB.LastName ASC, PB.FirstName ASC, PB.PatientId ASC) AS RowNum
            FROM PatientBase PB
        )
        -- Materialize the filtered set once so the page slice and total count stay in sync.
        SELECT
            PatientId,
            FirstName,
            LastName,
            ID_Number,
            DateOfBirth,
            GenderIDFK,
            MaritalStatusIDFK,
            ClientIdFK,
            MedicationList,
            IsDeleted,
            Email,
            PhoneNumber,
            Line1,
            Line2,
            CityId,
            CityName,
            ProvinceId,
            ProvinceName,
            CountryId,
            CountryName,
            CreatedDate,
            UpdatedDate,
            TotalRows,
            RowNum
        INTO #Numbered
        FROM Numbered;

        SELECT
            PatientId,
            FirstName,
            LastName,
            ID_Number,
            DateOfBirth,
            GenderIDFK,
            MaritalStatusIDFK,
            ClientIdFK,
            MedicationList,
            IsDeleted,
            Email,
            PhoneNumber,
            Line1,
            Line2,
            CityId,
            CityName,
            ProvinceId,
            ProvinceName,
            CountryId,
            CountryName,
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

        SET @TotalRecords = 0;
        SET @Message = 'Failed to retrieve patient list.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
