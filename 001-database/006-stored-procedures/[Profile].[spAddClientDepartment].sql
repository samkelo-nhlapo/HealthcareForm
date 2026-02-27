USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAddClientDepartment]
(
    @ClientIdFK UNIQUEIDENTIFIER,
    @DepartmentName VARCHAR(100),
    @DepartmentCode VARCHAR(50) = NULL,
    @DepartmentType VARCHAR(50) = 'Clinical',
    @CreatedBy VARCHAR(250) = NULL,
    @ClientDepartmentIdOutput UNIQUEIDENTIFIER OUTPUT,
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
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ClientDepartmentIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientIdFK is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@DepartmentName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DepartmentName is required.';
        RETURN;
    END

    IF @DepartmentType NOT IN ('Clinical', 'Administrative', 'Support', 'Management', 'Allied')
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid DepartmentType.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client does not exist or is deleted.';
        RETURN;
    END

    BEGIN TRY
        IF EXISTS
        (
            SELECT 1
            FROM Profile.ClientDepartments
            WHERE ClientIdFK = @ClientIdFK
              AND DepartmentName = LTRIM(RTRIM(@DepartmentName))
              AND IsDeleted = 0
        )
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'Department already exists for this client.';
            RETURN;
        END

        SET @ClientDepartmentIdOutput = NEWID();

        INSERT INTO Profile.ClientDepartments
        (
            ClientDepartmentId,
            ClientIdFK,
            DepartmentCode,
            DepartmentName,
            DepartmentType,
            IsActive,
            IsDeleted,
            CreatedDate,
            CreatedBy,
            UpdatedDate,
            UpdatedBy
        )
        VALUES
        (
            @ClientDepartmentIdOutput,
            @ClientIdFK,
            NULLIF(LTRIM(RTRIM(ISNULL(@DepartmentCode, ''))), ''),
            LTRIM(RTRIM(@DepartmentName)),
            @DepartmentType,
            1,
            0,
            @Now,
            COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME()),
            @Now,
            COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
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

        SET @ClientDepartmentIdOutput = NULL;
        SET @StatusCode = -1;
        SET @Message = 'Failed to add client department.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
