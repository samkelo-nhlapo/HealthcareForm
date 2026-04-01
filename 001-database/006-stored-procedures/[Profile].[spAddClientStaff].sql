USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Adds a staff member for a client and optionally links the row to auth, provider, and department records.
CREATE OR ALTER PROC [Profile].[spAddClientStaff]
(
    @ClientIdFK UNIQUEIDENTIFIER,
    @RoleIdFK UNIQUEIDENTIFIER = NULL,
    @UserIdFK UNIQUEIDENTIFIER = NULL,
    @ProviderIdFK UNIQUEIDENTIFIER = NULL,
    @StaffCode VARCHAR(50),
    @FirstName VARCHAR(250),
    @LastName VARCHAR(250),
    @Email VARCHAR(250) = NULL,
    @PhoneNumber VARCHAR(25) = NULL,
    @JobTitle VARCHAR(150) = NULL,
    @Department VARCHAR(100) = NULL,
    @StaffType VARCHAR(50) = 'Administrative',
    @EmploymentType VARCHAR(50) = 'Full-Time',
    @HireDate DATETIME = NULL,
    @IsPrimaryContact BIT = 0,
    @CreatedBy VARCHAR(250) = NULL,
    @StaffDesignationIdFK UNIQUEIDENTIFIER = NULL,
    @PrimaryDepartmentIdFK UNIQUEIDENTIFIER = NULL,
    @ClientStaffIdOutput UNIQUEIDENTIFIER OUTPUT,
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

    SET @ClientStaffIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientIdFK is required.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientId = @ClientIdFK AND IsDeleted = 0)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client does not exist or is deleted.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@StaffCode, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'StaffCode is required.';
        RETURN;
    END

    IF LTRIM(RTRIM(ISNULL(@FirstName, ''))) = '' OR LTRIM(RTRIM(ISNULL(@LastName, ''))) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'FirstName and LastName are required.';
        RETURN;
    END

    IF @RoleIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Auth.Roles WHERE RoleId = @RoleIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'RoleIdFK does not exist.';
        RETURN;
    END

    IF @UserIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Auth.Users WHERE UserId = @UserIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'UserIdFK does not exist.';
        RETURN;
    END

    IF @ProviderIdFK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Profile.HealthcareProviders WHERE ProviderId = @ProviderIdFK)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ProviderIdFK does not exist.';
        RETURN;
    END

    IF @StaffDesignationIdFK IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Profile.StaffDesignations WHERE StaffDesignationId = @StaffDesignationIdFK AND IsActive = 1)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'StaffDesignationIdFK does not exist or is inactive.';
        RETURN;
    END

    IF @PrimaryDepartmentIdFK IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Profile.ClientDepartments
           WHERE ClientDepartmentId = @PrimaryDepartmentIdFK
             AND ClientIdFK = @ClientIdFK
             AND IsDeleted = 0
       )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'PrimaryDepartmentIdFK does not belong to this client.';
        RETURN;
    END

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
       AND @Email NOT LIKE '%_@_%._%'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Invalid email format.';
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
        IF EXISTS (SELECT 1 FROM Profile.ClientStaff WHERE StaffCode = @StaffCode)
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'StaffCode already exists.';
            RETURN;
        END

        IF NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), '') IS NOT NULL
           AND EXISTS
           (
               SELECT 1
               FROM Profile.ClientStaff
               WHERE ClientIdFK = @ClientIdFK
                 AND Email = LTRIM(RTRIM(@Email))
                 AND IsDeleted = 0
           )
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'Email already exists for this client.';
            RETURN;
        END

        SET @ClientStaffIdOutput = NEWID();

        INSERT INTO Profile.ClientStaff
        (
            ClientStaffId, ClientIdFK, RoleIdFK, UserIdFK, ProviderIdFK,
            StaffCode, FirstName, LastName, Email, PhoneNumber,
            JobTitle, Department, StaffDesignationIdFK, PrimaryDepartmentIdFK, StaffType, EmploymentType, HireDate,
            IsPrimaryContact, IsActive, IsDeleted,
            CreatedDate, CreatedBy, UpdatedDate, UpdatedBy
        )
        VALUES
        (
            @ClientStaffIdOutput, @ClientIdFK, @RoleIdFK, @UserIdFK, @ProviderIdFK,
            @StaffCode, @FirstName, @LastName,
            NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''), @FormattedPhone,
            NULLIF(LTRIM(RTRIM(ISNULL(@JobTitle, ''))), ''),
            NULLIF(LTRIM(RTRIM(ISNULL(@Department, ''))), ''),
            @StaffDesignationIdFK, @PrimaryDepartmentIdFK,
            @StaffType, @EmploymentType, @HireDate,
            @IsPrimaryContact, 1, 0,
            @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME()), @Now, COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
        );

        -- Normalize the rest of the staff rows so only one primary contact remains for the client.
        IF @IsPrimaryContact = 1
        BEGIN
            UPDATE Profile.ClientStaff
            SET IsPrimaryContact = CASE WHEN ClientStaffId = @ClientStaffIdOutput THEN 1 ELSE 0 END,
                UpdatedDate = @Now,
                UpdatedBy = COALESCE(NULLIF(@CreatedBy, ''), SUSER_SNAME())
            WHERE ClientIdFK = @ClientIdFK
              AND IsDeleted = 0;
        END

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

        SET @ClientStaffIdOutput = NULL;
        SET @StatusCode = -1;
        SET @Message = 'Failed to add client staff record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
