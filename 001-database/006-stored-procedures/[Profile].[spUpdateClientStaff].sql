USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spUpdateClientStaff]
(
    @ClientStaffId UNIQUEIDENTIFIER,
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
    @StaffType VARCHAR(50),
    @EmploymentType VARCHAR(50),
    @HireDate DATETIME = NULL,
    @TerminationDate DATETIME = NULL,
    @IsPrimaryContact BIT = 0,
    @IsActive BIT = 1,
    @UpdatedBy VARCHAR(250) = NULL,
    @StaffDesignationIdFK UNIQUEIDENTIFIER = NULL,
    @PrimaryDepartmentIdFK UNIQUEIDENTIFIER = NULL,
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
            @ErrorDateTime DATETIME,
            @NormalizedPhone VARCHAR(25),
            @FormattedPhone VARCHAR(25);

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientStaffId IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientStaffId is required.';
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

    IF @TerminationDate IS NOT NULL AND @HireDate IS NOT NULL AND @TerminationDate < @HireDate
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'TerminationDate cannot be before HireDate.';
        RETURN;
    END

    SELECT @ClientIdFK = ClientIdFK
    FROM Profile.ClientStaff
    WHERE ClientStaffId = @ClientStaffId
      AND IsDeleted = 0;

    IF @ClientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client staff not found or already deleted.';
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
        IF EXISTS (SELECT 1 FROM Profile.ClientStaff WHERE StaffCode = @StaffCode AND ClientStaffId <> @ClientStaffId)
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
                 AND ClientStaffId <> @ClientStaffId
           )
        BEGIN
            SET @StatusCode = 2;
            SET @Message = 'Email already exists for this client.';
            RETURN;
        END

        UPDATE Profile.ClientStaff
        SET RoleIdFK = @RoleIdFK,
            UserIdFK = @UserIdFK,
            ProviderIdFK = @ProviderIdFK,
            StaffCode = @StaffCode,
            FirstName = @FirstName,
            LastName = @LastName,
            Email = NULLIF(LTRIM(RTRIM(ISNULL(@Email, ''))), ''),
            PhoneNumber = @FormattedPhone,
            JobTitle = NULLIF(LTRIM(RTRIM(ISNULL(@JobTitle, ''))), ''),
            Department = NULLIF(LTRIM(RTRIM(ISNULL(@Department, ''))), ''),
            StaffDesignationIdFK = COALESCE(@StaffDesignationIdFK, StaffDesignationIdFK),
            PrimaryDepartmentIdFK = COALESCE(@PrimaryDepartmentIdFK, PrimaryDepartmentIdFK),
            StaffType = @StaffType,
            EmploymentType = @EmploymentType,
            HireDate = @HireDate,
            TerminationDate = @TerminationDate,
            IsPrimaryContact = @IsPrimaryContact,
            IsActive = @IsActive,
            UpdatedDate = @Now,
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ClientStaffId = @ClientStaffId
          AND IsDeleted = 0;

        IF @IsPrimaryContact = 1
        BEGIN
            UPDATE Profile.ClientStaff
            SET IsPrimaryContact = CASE WHEN ClientStaffId = @ClientStaffId THEN 1 ELSE 0 END,
                UpdatedDate = @Now,
                UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
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

        SET @StatusCode = -1;
        SET @Message = 'Failed to update client staff record.';
    END CATCH

    SET NOCOUNT OFF;
END
GO
