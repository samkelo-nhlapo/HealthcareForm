USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Updates one client department while preserving per-client name uniqueness.
CREATE OR ALTER PROC [Profile].[spUpdateClientDepartment]
(
    @ClientDepartmentId UNIQUEIDENTIFIER,
    @DepartmentName VARCHAR(100),
    @DepartmentCode VARCHAR(50) = NULL,
    @DepartmentType VARCHAR(50),
    @IsActive BIT = 1,
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE(),
            @ClientIdFK UNIQUEIDENTIFIER,
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

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientDepartmentId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientDepartmentId is required.';
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

    SELECT @ClientIdFK = ClientIdFK
    FROM Profile.ClientDepartments
    WHERE ClientDepartmentId = @ClientDepartmentId
      AND IsDeleted = 0;

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client department not found or already deleted.';
        RETURN;
    END

    BEGIN TRY
        IF EXISTS
        (
            SELECT 1
            FROM Profile.ClientDepartments
            WHERE ClientIdFK = @ClientIdFK
              AND DepartmentName = LTRIM(RTRIM(@DepartmentName))
              AND ClientDepartmentId <> @ClientDepartmentId
              AND IsDeleted = 0
        )
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'Department name already exists for this client.';
            RETURN;
        END

        UPDATE Profile.ClientDepartments
        SET DepartmentCode = NULLIF(LTRIM(RTRIM(ISNULL(@DepartmentCode, ''))), ''),
            DepartmentName = LTRIM(RTRIM(@DepartmentName)),
            DepartmentType = @DepartmentType,
            IsActive = @IsActive,
            UpdatedDate = @Now,
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ClientDepartmentId = @ClientDepartmentId
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
        SET @Message = 'Failed to update client department.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
