USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spDeleteClient]
(
    @ClientId UNIQUEIDENTIFIER = NULL,
    @ClientCode VARCHAR(50) = '',
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
            @ErrorDateTime DATETIME;

    SET NOCOUNT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    BEGIN TRY
        IF @ClientId IS NULL AND LTRIM(RTRIM(@ClientCode)) = ''
        BEGIN
            SET @StatusCode = 1;
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
                AND C.IsDeleted = 0
        )
        BEGIN
            UPDATE C
            SET IsDeleted = 1,
                IsActive = 0,
                UpdatedDate = @Now,
                UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
            FROM Profile.Clients C
            WHERE
                ((@ClientId IS NOT NULL AND C.ClientId = @ClientId)
                 OR (@ClientId IS NULL AND C.ClientCode = @ClientCode))
                AND C.IsDeleted = 0;

            SET @StatusCode = 0;
            SET @Message = '';
        END
        ELSE
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Client does not exist or is already deleted.';
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

        SET @StatusCode = -1;
        SET @Message = 'Failed to delete client record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
