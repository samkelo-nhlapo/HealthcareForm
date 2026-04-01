USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns a paged department list for one client or across all clients.
-- The join to clients keeps enough context in the row for directory-style UI screens.
CREATE OR ALTER PROC [Profile].[spListClientDepartments]
(
    @ClientIdFK UNIQUEIDENTIFIER = NULL,
    @DepartmentType VARCHAR(50) = '',
    @SearchTerm VARCHAR(100) = '',
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

    IF @DepartmentType <> ''
       AND @DepartmentType NOT IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied')
    BEGIN
        SET @TotalRecords = 0;
        SET @Message = 'Invalid DepartmentType.';
        RETURN;
    END

    SET @Offset = (@PageNumber - 1) * @PageSize;
    SET @TotalRecords = 0;
    SET @Message = '';

    BEGIN TRY
        ;WITH Base AS
        (
            SELECT
                CD.ClientDepartmentId,
                CD.ClientIdFK,
                C.ClientCode,
                C.FirstName AS ClientFirstName,
                C.LastName AS ClientLastName,
                CD.DepartmentCode,
                CD.DepartmentName,
                CD.DepartmentType,
                CD.IsActive,
                CD.IsDeleted,
                CD.CreatedDate,
                CD.CreatedBy,
                CD.UpdatedDate,
                CD.UpdatedBy
            FROM Profile.ClientDepartments CD
            INNER JOIN Profile.Clients C ON C.ClientId = CD.ClientIdFK
            WHERE (@ClientIdFK IS NULL OR CD.ClientIdFK = @ClientIdFK)
              AND (@DepartmentType = '' OR CD.DepartmentType = @DepartmentType)
              AND (@IsActive IS NULL OR CD.IsActive = @IsActive)
              AND (@IsDeleted IS NULL OR CD.IsDeleted = @IsDeleted)
              AND
              (
                    @SearchTerm = ''
                    OR CD.DepartmentName LIKE '%' + @SearchTerm + '%'
                    OR ISNULL(CD.DepartmentCode, '') LIKE '%' + @SearchTerm + '%'
                    OR C.ClientCode LIKE '%' + @SearchTerm + '%'
              )
        ),
        Numbered AS
        (
            SELECT
                B.*,
                COUNT(1) OVER () AS TotalRows,
                ROW_NUMBER() OVER (ORDER BY B.DepartmentName ASC, B.ClientDepartmentId ASC) AS RowNum
            FROM Base B
        )
        -- Materialize the filtered set once so the page slice and total count stay in sync.
        SELECT
            ClientDepartmentId,
            ClientIdFK,
            ClientCode,
            ClientFirstName,
            ClientLastName,
            DepartmentCode,
            DepartmentName,
            DepartmentType,
            IsActive,
            IsDeleted,
            CreatedDate,
            CreatedBy,
            UpdatedDate,
            UpdatedBy,
            TotalRows,
            RowNum
        INTO #Numbered
        FROM Numbered;

        SELECT
            ClientDepartmentId,
            ClientIdFK,
            ClientCode,
            ClientFirstName,
            ClientLastName,
            DepartmentCode,
            DepartmentName,
            DepartmentType,
            IsActive,
            IsDeleted,
            CreatedDate,
            CreatedBy,
            UpdatedDate,
            UpdatedBy
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
        SET @Message = 'Failed to list client departments.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
