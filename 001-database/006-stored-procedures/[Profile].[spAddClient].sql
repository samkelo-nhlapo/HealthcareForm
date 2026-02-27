USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spAddClient]
(
    @ClientCode VARCHAR(50),
    @FirstName VARCHAR(250),
    @LastName VARCHAR(250),
    @DateOfBirth DATETIME = NULL,
    @ID_Number VARCHAR(250) = NULL,
    @Email VARCHAR(250) = NULL,
    @PhoneNumber VARCHAR(25) = NULL,
    @AddressIDFK UNIQUEIDENTIFIER = NULL,
    @PatientIdFK UNIQUEIDENTIFIER = NULL,
    @ClientClinicCategoryIDFK INT = NULL,
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
            @NormalizedPhone VARCHAR(25),
            @FormattedPhone VARCHAR(25);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ClientIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    IF LTRIM(RTRIM(ISNULL(@ClientCode, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientCode is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@FirstName, ''))) = '' OR LTRIM(RTRIM(ISNULL(@LastName, ''))) = ''
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

    IF @AddressIDFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Location.Address WHERE AddressId = @AddressIDFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'AddressIDFK does not exist.';
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

    SET @NormalizedPhone = LTRIM(RTRIM(ISNULL(@PhoneNumber, '')));
    IF @NormalizedPhone <> ''
    BEGIN
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '-', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ' ', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '+', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, '(', '');
        SET @NormalizedPhone = REPLACE(@NormalizedPhone, ')', '');

        IF LEN(@NormalizedPhone) <> 10 OR @NormalizedPhone LIKE '%[^0-9]%'
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'PhoneNumber must contain exactly 10 digits.';
            RETURN;
        END

        SET @FormattedPhone = SUBSTRING(@NormalizedPhone, 1, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 4, 3) + '-' +
                              SUBSTRING(@NormalizedPhone, 7, 4);
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
            ClientId, PatientIdFK, ClientClinicCategoryIDFK, ClientCode, FirstName, LastName,
            DateOfBirth, ID_Number, Email, PhoneNumber, AddressIDFK,
            IsActive, IsDeleted, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy
        )
        VALUES
        (
            @ClientIdOutput, @PatientIdFK, @ClientClinicCategoryIDFK, @ClientCode, @FirstName, @LastName,
            @DateOfBirth, NULLIF(LTRIM(RTRIM(ISNULL(@ID_Number, ''))), ''),
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
