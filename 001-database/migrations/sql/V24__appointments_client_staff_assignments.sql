USE HealthcareForm;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientIdFK') IS NULL
BEGIN
    ALTER TABLE [Profile].[Appointments] ADD [ClientIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientStaffIdFK') IS NULL
BEGIN
    ALTER TABLE [Profile].[Appointments] ADD [ClientStaffIdFK] UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
BEGIN
    DECLARE @PatientClientsHasIsDeleted BIT = CASE
        WHEN COL_LENGTH('Profile.PatientClients', 'IsDeleted') IS NULL THEN 0
        ELSE 1
    END;
    DECLARE @PatientHasClientId BIT = CASE
        WHEN COL_LENGTH('Profile.Patient', 'ClientIdFK') IS NULL THEN 0
        ELSE 1
    END;
    DECLARE @ResolveClientSql NVARCHAR(MAX) = N'';
    DECLARE @BackfillActor VARCHAR(250) = 'V24_APPOINTMENT_CLIENTSTAFF';
    DECLARE @Now DATETIME = GETDATE();
    DECLARE @DoctorRoleId UNIQUEIDENTIFIER = NULL;

    SELECT TOP 1 @DoctorRoleId = R.RoleId
    FROM Auth.Roles R
    WHERE UPPER(R.RoleName) = 'DOCTOR';

    IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
    BEGIN
        SET @ResolveClientSql = N'
            UPDATE A
            SET A.ClientIdFK = Membership.ClientIdFK
            FROM Profile.Appointments A
            OUTER APPLY
            (
                SELECT TOP 1 PC.ClientIdFK
                FROM Profile.PatientClients PC
                INNER JOIN Profile.Clients C
                    ON C.ClientId = PC.ClientIdFK
                   AND C.IsDeleted = 0
                   AND C.IsActive = 1
                WHERE PC.PatientIdFK = A.PatientIdFK'
                + CASE
                    WHEN @PatientClientsHasIsDeleted = 1
                        THEN N' AND (PC.IsDeleted = 0 OR PC.IsDeleted IS NULL)'
                    ELSE N''
                  END
                + N'
                ORDER BY
                    CASE WHEN ISNULL(PC.IsPrimary, 0) = 1 THEN 0 ELSE 1 END,
                    COALESCE(PC.UpdatedDate, PC.CreatedDate) DESC
            ) Membership
            WHERE A.ClientIdFK IS NULL
              AND Membership.ClientIdFK IS NOT NULL;';

        EXEC sys.sp_executesql @ResolveClientSql;
    END

    IF @PatientHasClientId = 1
    BEGIN
        UPDATE A
        SET A.ClientIdFK = P.ClientIdFK
        FROM Profile.Appointments A
        INNER JOIN Profile.Patient P
            ON P.PatientId = A.PatientIdFK
        INNER JOIN Profile.Clients C
            ON C.ClientId = P.ClientIdFK
           AND C.IsDeleted = 0
           AND C.IsActive = 1
        WHERE A.ClientIdFK IS NULL
          AND P.ClientIdFK IS NOT NULL;
    END

    UPDATE A
    SET A.ClientIdFK = SingleAssignment.ClientIdFK
    FROM Profile.Appointments A
    OUTER APPLY
    (
        SELECT
            ClientIdFK = CASE
                WHEN COUNT(DISTINCT CS.ClientIdFK) = 1 THEN MIN(CS.ClientIdFK)
                ELSE NULL
            END
        FROM Profile.ClientStaff CS
        WHERE CS.ProviderIdFK = A.ProviderIdFK
          AND CS.IsDeleted = 0
          AND CS.IsActive = 1
    ) SingleAssignment
    WHERE A.ClientIdFK IS NULL
      AND SingleAssignment.ClientIdFK IS NOT NULL;

    ;WITH MissingAssignments AS
    (
        SELECT DISTINCT
            A.ClientIdFK,
            A.ProviderIdFK
        FROM Profile.Appointments A
        WHERE A.ClientIdFK IS NOT NULL
          AND A.ProviderIdFK IS NOT NULL
    )
    INSERT INTO Profile.ClientStaff
    (
        ClientStaffId,
        ClientIdFK,
        RoleIdFK,
        UserIdFK,
        ProviderIdFK,
        StaffCode,
        FirstName,
        LastName,
        Email,
        PhoneNumber,
        JobTitle,
        Department,
        StaffType,
        EmploymentType,
        HireDate,
        TerminationDate,
        IsPrimaryContact,
        IsActive,
        IsDeleted,
        CreatedDate,
        CreatedBy,
        UpdatedDate,
        UpdatedBy
    )
    SELECT
        NEWID(),
        M.ClientIdFK,
        @DoctorRoleId,
        NULL,
        M.ProviderIdFK,
        CONCAT(
            'APT-',
            LEFT(REPLACE(CONVERT(VARCHAR(36), M.ClientIdFK), '-', ''), 8),
            '-',
            LEFT(REPLACE(CONVERT(VARCHAR(36), M.ProviderIdFK), '-', ''), 8)
        ),
        COALESCE(NULLIF(LTRIM(RTRIM(HP.FirstName)), ''), 'Assigned'),
        COALESCE(NULLIF(LTRIM(RTRIM(HP.LastName)), ''), 'Doctor'),
        NULL,
        NULL,
        'Medical Doctor',
        'Clinical',
        'Clinical',
        'Full-Time',
        @Now,
        NULL,
        0,
        1,
        0,
        @Now,
        @BackfillActor,
        @Now,
        @BackfillActor
    FROM MissingAssignments M
    INNER JOIN Profile.Clients C
        ON C.ClientId = M.ClientIdFK
       AND C.IsDeleted = 0
       AND C.IsActive = 1
    INNER JOIN Profile.HealthcareProviders HP
        ON HP.ProviderId = M.ProviderIdFK
       AND HP.IsActive = 1
    LEFT JOIN Profile.ClientStaff Existing
        ON Existing.ClientIdFK = M.ClientIdFK
       AND Existing.ProviderIdFK = M.ProviderIdFK
    WHERE Existing.ClientStaffId IS NULL;

    UPDATE A
    SET A.ClientStaffIdFK = Resolved.ClientStaffId,
        A.ClientIdFK = COALESCE(A.ClientIdFK, Resolved.ClientIdFK)
    FROM Profile.Appointments A
    OUTER APPLY
    (
        SELECT TOP 1
            CS.ClientStaffId,
            CS.ClientIdFK
        FROM Profile.ClientStaff CS
        LEFT JOIN Auth.Roles R
            ON R.RoleId = CS.RoleIdFK
        WHERE CS.ProviderIdFK = A.ProviderIdFK
          AND CS.IsDeleted = 0
          AND CS.IsActive = 1
          AND
          (
              A.ClientIdFK IS NULL
              OR CS.ClientIdFK = A.ClientIdFK
          )
          AND
          (
              UPPER(ISNULL(R.RoleName, '')) = 'DOCTOR'
              OR
              (
                  R.RoleId IS NULL
                  AND UPPER(ISNULL(CS.StaffType, '')) = 'CLINICAL'
              )
          )
        ORDER BY
            CASE
                WHEN A.ClientIdFK IS NOT NULL AND CS.ClientIdFK = A.ClientIdFK THEN 0
                ELSE 1
            END,
            COALESCE(CS.UpdatedDate, CS.CreatedDate) DESC,
            CS.ClientStaffId DESC
    ) Resolved
    WHERE A.ClientStaffIdFK IS NULL
      AND Resolved.ClientStaffId IS NOT NULL;

    IF EXISTS (SELECT 1 FROM Profile.Appointments WHERE ClientIdFK IS NULL)
    BEGIN
        THROW 52001, 'Unable to backfill Appointments.ClientIdFK for all existing rows.', 1;
    END

    IF EXISTS (SELECT 1 FROM Profile.Appointments WHERE ClientStaffIdFK IS NULL)
    BEGIN
        THROW 52002, 'Unable to backfill Appointments.ClientStaffIdFK for all existing rows.', 1;
    END
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientIdFK') IS NOT NULL
AND EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND name = N'ClientIdFK'
      AND is_nullable = 1
)
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]')
          AND name = N'IX_Appointments_ClientIdFK_AppointmentDateTime'
    )
    BEGIN
        DROP INDEX IX_Appointments_ClientIdFK_AppointmentDateTime ON [Profile].[Appointments];
    END

    ALTER TABLE [Profile].[Appointments] ALTER COLUMN [ClientIdFK] UNIQUEIDENTIFIER NOT NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientStaffIdFK') IS NOT NULL
AND EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND name = N'ClientStaffIdFK'
      AND is_nullable = 1
)
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]')
          AND name = N'IX_Appointments_ClientStaffIdFK'
    )
    BEGIN
        DROP INDEX IX_Appointments_ClientStaffIdFK ON [Profile].[Appointments];
    END

    ALTER TABLE [Profile].[Appointments] ALTER COLUMN [ClientStaffIdFK] UNIQUEIDENTIFIER NOT NULL;
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[Clients]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientIdFK') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Appointments]'), N'ClientIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[Clients]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Clients]'), N'ClientId', 'ColumnId')
)
BEGIN
    ALTER TABLE [Profile].[Appointments] WITH CHECK
    ADD CONSTRAINT [FK_Appointments_Client] FOREIGN KEY([ClientIdFK]) REFERENCES [Profile].[Clients]([ClientId]);
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND COL_LENGTH(N'[Profile].[Appointments]', N'ClientStaffIdFK') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_key_columns AS fkc
    WHERE fkc.parent_object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND fkc.parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[Appointments]'), N'ClientStaffIdFK', 'ColumnId')
      AND fkc.referenced_object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND fkc.referenced_column_id = COLUMNPROPERTY(OBJECT_ID(N'[Profile].[ClientStaff]'), N'ClientStaffId', 'ColumnId')
)
BEGIN
    ALTER TABLE [Profile].[Appointments] WITH CHECK
    ADD CONSTRAINT [FK_Appointments_ClientStaff] FOREIGN KEY([ClientStaffIdFK]) REFERENCES [Profile].[ClientStaff]([ClientStaffId]);
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND name = N'IX_Appointments_ClientStaffIdFK'
)
BEGIN
    CREATE INDEX IX_Appointments_ClientStaffIdFK ON [Profile].[Appointments]([ClientStaffIdFK]);
END
GO

IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[Appointments]')
      AND name = N'IX_Appointments_ClientIdFK_AppointmentDateTime'
)
BEGIN
    CREATE INDEX IX_Appointments_ClientIdFK_AppointmentDateTime ON [Profile].[Appointments]([ClientIdFK], [AppointmentDateTime]);
END
GO

USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns active providers for the scheduling dashboard.
-- The API derives display labels, capacity, and clinic grouping on top of this lightweight shape.
CREATE OR ALTER PROC [Profile].[spGetSchedulingProviders]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CS.ClientStaffId,
        C.ClientId,
        ClientName = CASE
            WHEN LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, '')))) = ''
                THEN COALESCE(NULLIF(LTRIM(RTRIM(C.ClientCode)), ''), 'Client')
            ELSE LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, ''))))
        END,
        HP.ProviderId,
        HP.FirstName,
        HP.LastName,
        HP.Title,
        HP.Specialization
    FROM Profile.ClientStaff CS
    INNER JOIN Profile.Clients C
        ON C.ClientId = CS.ClientIdFK
       AND C.IsDeleted = 0
       AND C.IsActive = 1
    LEFT JOIN Auth.Roles R
        ON R.RoleId = CS.RoleIdFK
    INNER JOIN Profile.HealthcareProviders HP
        ON HP.ProviderId = CS.ProviderIdFK
       AND HP.IsActive = 1
    WHERE CS.IsDeleted = 0
      AND CS.IsActive = 1
      AND
      (
          UPPER(ISNULL(R.RoleName, '')) = 'DOCTOR'
          OR
          (
              R.RoleId IS NULL
              AND UPPER(ISNULL(CS.StaffType, '')) = 'CLINICAL'
          )
      )
    ORDER BY
        ClientName,
        HP.LastName,
        HP.FirstName,
        CS.ClientStaffId;
END
GO

USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns appointments inside a requested scheduling window.
-- The API layers clinic normalization and capacity calculations on top of the raw rows.
CREATE OR ALTER PROC [Profile].[spGetSchedulingAppointments]
(
    @WindowStart DATETIME = NULL,
    @WindowEnd DATETIME = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Default to a same-day window because the dashboard is optimized for today's load.
    IF @WindowStart IS NULL
    BEGIN
        SET @WindowStart = CAST(GETDATE() AS DATE);
    END

    IF @WindowEnd IS NULL OR @WindowEnd <= @WindowStart
    BEGIN
        SET @WindowEnd = DATEADD(DAY, 1, @WindowStart);
    END

    SELECT
        ClientStaffIdFK = COALESCE(A.ClientStaffIdFK, ResolvedStaff.ClientStaffId),
        ClientIdFK = COALESCE(A.ClientIdFK, ResolvedStaff.ClientIdFK),
        ClientName = CASE
            WHEN LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, '')))) = ''
                THEN COALESCE(NULLIF(LTRIM(RTRIM(C.ClientCode)), ''), 'Client')
            ELSE LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, ''))))
        END,
        ProviderId = COALESCE(ResolvedStaff.ProviderIdFK, A.ProviderIdFK),
        A.AppointmentDateTime,
        A.DurationMinutes,
        A.Status,
        A.Location,
        HP.Specialization
    FROM Profile.Appointments A
    OUTER APPLY
    (
        SELECT TOP 1
            CS.ClientStaffId,
            CS.ClientIdFK,
            CS.ProviderIdFK
        FROM Profile.ClientStaff CS
        LEFT JOIN Auth.Roles R
            ON R.RoleId = CS.RoleIdFK
        WHERE CS.IsDeleted = 0
          AND CS.IsActive = 1
          AND CS.ProviderIdFK = A.ProviderIdFK
          AND
          (
              A.ClientIdFK IS NULL
              OR CS.ClientIdFK = A.ClientIdFK
          )
          AND
          (
              UPPER(ISNULL(R.RoleName, '')) = 'DOCTOR'
              OR
              (
                  R.RoleId IS NULL
                  AND UPPER(ISNULL(CS.StaffType, '')) = 'CLINICAL'
              )
          )
        ORDER BY
            CASE
                WHEN A.ClientIdFK IS NOT NULL AND CS.ClientIdFK = A.ClientIdFK THEN 0
                ELSE 1
            END,
            COALESCE(CS.UpdatedDate, CS.CreatedDate) DESC,
            CS.ClientStaffId DESC
    ) ResolvedStaff
    LEFT JOIN Profile.HealthcareProviders HP
        ON HP.ProviderId = COALESCE(ResolvedStaff.ProviderIdFK, A.ProviderIdFK)
    LEFT JOIN Profile.Clients C
        ON C.ClientId = COALESCE(A.ClientIdFK, ResolvedStaff.ClientIdFK)
    WHERE A.AppointmentDateTime >= @WindowStart
      AND A.AppointmentDateTime < @WindowEnd;
END
GO

USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns clinic/hospital options with linked doctor providers for appointment booking.
CREATE OR ALTER PROC [Profile].[spGetSchedulingBookingOptions]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT
        C.ClientId,
        C.ClientCode,
        ClientName = CASE
            WHEN LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, '')))) = ''
                THEN COALESCE(NULLIF(LTRIM(RTRIM(C.ClientCode)), ''), 'Client')
            ELSE LTRIM(RTRIM(CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, ''))))
        END,
        ClientCategory = COALESCE(NULLIF(LTRIM(RTRIM(CCC.CategoryName)), ''), 'Uncategorized'),
        CS.ClientStaffId,
        HP.ProviderId,
        Provider = LTRIM(RTRIM(CONCAT(
            CASE
                WHEN NULLIF(LTRIM(RTRIM(ISNULL(HP.Title, ''))), '') IS NULL THEN ''
                ELSE LTRIM(RTRIM(HP.Title)) + ' '
            END,
            CASE
                WHEN LTRIM(RTRIM(CONCAT(ISNULL(HP.FirstName, ''), ' ', ISNULL(HP.LastName, '')))) = ''
                    THEN 'Provider'
                ELSE LTRIM(RTRIM(CONCAT(ISNULL(HP.FirstName, ''), ' ', ISNULL(HP.LastName, ''))))
            END
        ))),
        Clinic = COALESCE(NULLIF(LTRIM(RTRIM(HP.Specialization)), ''), 'General')
    FROM Profile.Clients C
    INNER JOIN Profile.ClientStaff CS
        ON CS.ClientIdFK = C.ClientId
       AND CS.IsDeleted = 0
       AND CS.IsActive = 1
       AND CS.ProviderIdFK IS NOT NULL
    LEFT JOIN Auth.Roles R
        ON R.RoleId = CS.RoleIdFK
    INNER JOIN Profile.HealthcareProviders HP
        ON HP.ProviderId = CS.ProviderIdFK
       AND HP.IsActive = 1
    LEFT JOIN Profile.ClientClinicCategories CCC
        ON CCC.ClientClinicCategoryId = C.ClientClinicCategoryIDFK
    WHERE C.IsDeleted = 0
      AND C.IsActive = 1
      AND
      (
          UPPER(ISNULL(R.RoleName, '')) = 'DOCTOR'
          OR
          (
              R.RoleId IS NULL
              AND UPPER(ISNULL(CS.StaffType, '')) = 'CLINICAL'
          )
      )
    ORDER BY
        ClientName ASC,
        Provider ASC;

    SET NOCOUNT OFF;
END
GO

USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Inserts a new appointment row for an existing patient and a clinic-linked doctor assignment.
CREATE OR ALTER PROC [Profile].[spAddAppointment]
(
    @ClientIdFK UNIQUEIDENTIFIER,
    @PatientIdNumber VARCHAR(250),
    @ClientStaffIdFK UNIQUEIDENTIFIER,
    @AppointmentDateTime DATETIME,
    @DurationMinutes INT = 30,
    @AppointmentType VARCHAR(100) = 'Consultation',
    @Reason VARCHAR(MAX) = NULL,
    @Location VARCHAR(250) = NULL,
    @CreatedBy VARCHAR(250) = NULL,
    @AppointmentIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Now DATETIME = GETDATE();
    DECLARE @PatientIdFK UNIQUEIDENTIFIER = NULL;
    DECLARE @ResolvedClientIdFK UNIQUEIDENTIFIER = NULL;
    DECLARE @ResolvedProviderIdFK UNIQUEIDENTIFIER = NULL;
    DECLARE @PatientClientsHasIsDeleted BIT = CASE
        WHEN COL_LENGTH('Profile.PatientClients', 'IsDeleted') IS NULL THEN 0
        ELSE 1
    END;
    DECLARE @HasPatientMembership BIT = 0;
    DECLARE @HasRequiredPatientMembership BIT = 0;
    DECLARE @PatientMembershipSql NVARCHAR(MAX) = N'';
    DECLARE @AppointmentsHasClientId BIT = CASE
        WHEN COL_LENGTH('Profile.Appointments', 'ClientIdFK') IS NULL THEN 0
        ELSE 1
    END;
    DECLARE @AppointmentsHasClientStaffId BIT = CASE
        WHEN COL_LENGTH('Profile.Appointments', 'ClientStaffIdFK') IS NULL THEN 0
        ELSE 1
    END;
    DECLARE @AppointmentsHasProviderId BIT = CASE
        WHEN COL_LENGTH('Profile.Appointments', 'ProviderIdFK') IS NULL THEN 0
        ELSE 1
    END;
    DECLARE @InsertColumns NVARCHAR(MAX) = N'AppointmentId, PatientIdFK';
    DECLARE @InsertValues NVARCHAR(MAX) = N'@AppointmentIdOutput, @PatientIdFK';
    DECLARE @InsertSql NVARCHAR(MAX) = N'';
    DECLARE @NormalizedIdNumber VARCHAR(250) = LTRIM(RTRIM(ISNULL(@PatientIdNumber, '')));
    DECLARE @NormalizedType VARCHAR(100) = LEFT(LTRIM(RTRIM(ISNULL(@AppointmentType, ''))), 100);
    DECLARE @NormalizedReason VARCHAR(MAX) = NULLIF(LTRIM(RTRIM(ISNULL(@Reason, ''))), '');
    DECLARE @NormalizedLocation VARCHAR(250) = NULLIF(LTRIM(RTRIM(ISNULL(@Location, ''))), '');
    DECLARE @Actor VARCHAR(250) = COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(@CreatedBy, ''))), ''), SUSER_SNAME());

    SET @AppointmentIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientIdFK IS NULL OR @ClientIdFK = '00000000-0000-0000-0000-000000000000'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientIdFK is required.';
        RETURN;
    END

    IF @NormalizedIdNumber = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Patient ID number is required.';
        RETURN;
    END

    IF @ClientStaffIdFK IS NULL OR @ClientStaffIdFK = '00000000-0000-0000-0000-000000000000'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientStaffIdFK is required.';
        RETURN;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM Profile.Clients C
        WHERE C.ClientId = @ClientIdFK
          AND C.IsDeleted = 0
          AND C.IsActive = 1
    )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Selected clinic or hospital does not exist or is inactive.';
        RETURN;
    END

    IF @AppointmentDateTime IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'AppointmentDateTime is required.';
        RETURN;
    END

    IF @AppointmentDateTime < DATEADD(DAY, -1, @Now)
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'AppointmentDateTime cannot be in the distant past.';
        RETURN;
    END

    IF @DurationMinutes IS NULL OR @DurationMinutes < 5 OR @DurationMinutes > 480
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'DurationMinutes must be between 5 and 480.';
        RETURN;
    END

    IF @NormalizedType = ''
    BEGIN
        SET @NormalizedType = 'Consultation';
    END

    IF @NormalizedReason IS NULL
    BEGIN
        SET @NormalizedReason = 'General consultation';
    END

    SELECT TOP 1 @PatientIdFK = P.PatientId
    FROM Profile.Patient P
    WHERE P.ID_Number = @NormalizedIdNumber
      AND P.IsDeleted = 0
    ORDER BY COALESCE(P.UpdatedDate, P.CreatedDate) DESC, P.PatientId DESC;

    IF @PatientIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Patient was not found for the supplied ID number.';
        RETURN;
    END

    IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
    BEGIN
        SET @PatientMembershipSql = N'
            SELECT @HasMembershipOut =
                CASE
                    WHEN EXISTS
                    (
                        SELECT 1
                        FROM Profile.PatientClients ExistingMembership
                        WHERE ExistingMembership.PatientIdFK = @PatientIdFK'
                        + CASE
                            WHEN @PatientClientsHasIsDeleted = 1
                                THEN N' AND (ExistingMembership.IsDeleted = 0 OR ExistingMembership.IsDeleted IS NULL)'
                            ELSE N''
                          END
                        + N'
                    )
                    THEN 1
                    ELSE 0
                END;

            SELECT @HasRequiredMembershipOut =
                CASE
                    WHEN EXISTS
                    (
                        SELECT 1
                        FROM Profile.PatientClients RequiredMembership
                        WHERE RequiredMembership.PatientIdFK = @PatientIdFK
                          AND RequiredMembership.ClientIdFK = @ClientIdFK'
                        + CASE
                            WHEN @PatientClientsHasIsDeleted = 1
                                THEN N' AND (RequiredMembership.IsDeleted = 0 OR RequiredMembership.IsDeleted IS NULL)'
                            ELSE N''
                          END
                        + N'
                    )
                    THEN 1
                    ELSE 0
                END;';

        EXEC sys.sp_executesql
            @PatientMembershipSql,
            N'@PatientIdFK UNIQUEIDENTIFIER, @ClientIdFK UNIQUEIDENTIFIER, @HasMembershipOut BIT OUTPUT, @HasRequiredMembershipOut BIT OUTPUT',
            @PatientIdFK = @PatientIdFK,
            @ClientIdFK = @ClientIdFK,
            @HasMembershipOut = @HasPatientMembership OUTPUT,
            @HasRequiredMembershipOut = @HasRequiredPatientMembership OUTPUT;

        IF @HasPatientMembership = 1 AND @HasRequiredPatientMembership = 0
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Patient is not linked to the selected clinic or hospital.';
            RETURN;
        END
    END

    SELECT TOP 1
        @ResolvedClientIdFK = CS.ClientIdFK,
        @ResolvedProviderIdFK = CS.ProviderIdFK
    FROM Profile.ClientStaff CS
    LEFT JOIN Auth.Roles R
        ON R.RoleId = CS.RoleIdFK
    INNER JOIN Profile.HealthcareProviders HP
        ON HP.ProviderId = CS.ProviderIdFK
       AND HP.IsActive = 1
    WHERE CS.ClientStaffId = @ClientStaffIdFK
      AND CS.IsDeleted = 0
      AND CS.IsActive = 1
      AND
      (
          UPPER(ISNULL(R.RoleName, '')) = 'DOCTOR'
          OR
          (
              R.RoleId IS NULL
              AND UPPER(ISNULL(CS.StaffType, '')) = 'CLINICAL'
          )
      )
    ORDER BY COALESCE(CS.UpdatedDate, CS.CreatedDate) DESC, CS.ClientStaffId DESC;

    IF @ResolvedProviderIdFK IS NULL
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Selected doctor is not an active clinic-linked provider.';
        RETURN;
    END

    IF @ResolvedClientIdFK <> @ClientIdFK
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Selected doctor is not linked to the chosen clinic or hospital.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.Appointments A
        WHERE A.ProviderIdFK = @ResolvedProviderIdFK
          AND UPPER(LTRIM(RTRIM(ISNULL(A.Status, '')))) NOT IN ('CANCELLED', 'NO-SHOW', 'NO SHOW', 'COMPLETED')
          AND A.AppointmentDateTime < DATEADD(MINUTE, @DurationMinutes, @AppointmentDateTime)
          AND DATEADD(
                MINUTE,
                CASE
                    WHEN ISNULL(A.DurationMinutes, 0) < 5 THEN 30
                    ELSE A.DurationMinutes
                END,
                A.AppointmentDateTime
              ) > @AppointmentDateTime
    )
    BEGIN
        SET @StatusCode = 2;
        SET @Message = 'Provider already has an overlapping appointment.';
        RETURN;
    END

    SET @AppointmentIdOutput = NEWID();

    IF @AppointmentsHasClientId = 1
    BEGIN
        SET @InsertColumns += N', ClientIdFK';
        SET @InsertValues += N', @ClientIdFK';
    END

    IF @AppointmentsHasClientStaffId = 1
    BEGIN
        SET @InsertColumns += N', ClientStaffIdFK';
        SET @InsertValues += N', @ClientStaffIdFK';
    END

    IF @AppointmentsHasProviderId = 1
    BEGIN
        SET @InsertColumns += N', ProviderIdFK';
        SET @InsertValues += N', @ResolvedProviderIdFK';
    END

    SET @InsertColumns += N', AppointmentDateTime, DurationMinutes, AppointmentType, Reason, Location, Status, Reminders, Notes, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy';
    SET @InsertValues += N', @AppointmentDateTime, @DurationMinutes, @NormalizedType, @NormalizedReason, @NormalizedLocation, ''Scheduled'', NULL, ''Created via operations scheduling API.'', @Now, @Actor, @Now, @Actor';

    SET @InsertSql = N'INSERT INTO Profile.Appointments (' + @InsertColumns + N') VALUES (' + @InsertValues + N');';

    EXEC sys.sp_executesql
        @InsertSql,
        N'@AppointmentIdOutput UNIQUEIDENTIFIER, @PatientIdFK UNIQUEIDENTIFIER, @ClientIdFK UNIQUEIDENTIFIER, @ClientStaffIdFK UNIQUEIDENTIFIER, @ResolvedProviderIdFK UNIQUEIDENTIFIER, @AppointmentDateTime DATETIME, @DurationMinutes INT, @NormalizedType VARCHAR(100), @NormalizedReason VARCHAR(MAX), @NormalizedLocation VARCHAR(250), @Now DATETIME, @Actor VARCHAR(250)',
        @AppointmentIdOutput = @AppointmentIdOutput,
        @PatientIdFK = @PatientIdFK,
        @ClientIdFK = @ClientIdFK,
        @ClientStaffIdFK = @ClientStaffIdFK,
        @ResolvedProviderIdFK = @ResolvedProviderIdFK,
        @AppointmentDateTime = @AppointmentDateTime,
        @DurationMinutes = @DurationMinutes,
        @NormalizedType = @NormalizedType,
        @NormalizedReason = @NormalizedReason,
        @NormalizedLocation = @NormalizedLocation,
        @Now = @Now,
        @Actor = @Actor;

    SET @StatusCode = 0;
    SET @Message = '';

    SET NOCOUNT OFF;
END
GO
