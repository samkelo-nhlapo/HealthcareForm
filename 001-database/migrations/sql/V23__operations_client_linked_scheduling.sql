SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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

-- Inserts a new appointment row for an existing patient and client-linked provider.
CREATE OR ALTER PROC [Profile].[spAddAppointment]
(
    @ClientIdFK UNIQUEIDENTIFIER,
    @PatientIdNumber VARCHAR(250),
    @ProviderIdFK UNIQUEIDENTIFIER,
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
    DECLARE @PatientClientsHasIsDeleted BIT = CASE
        WHEN COL_LENGTH('Profile.PatientClients', 'IsDeleted') IS NULL THEN 0
        ELSE 1
    END;
    DECLARE @HasPatientMembership BIT = 0;
    DECLARE @HasRequiredPatientMembership BIT = 0;
    DECLARE @PatientMembershipSql NVARCHAR(MAX) = N'';
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

    IF @ProviderIdFK IS NULL OR @ProviderIdFK = '00000000-0000-0000-0000-000000000000'
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ProviderIdFK is required.';
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

    IF NOT EXISTS
    (
        SELECT 1
        FROM Profile.ClientStaff CS
        LEFT JOIN Auth.Roles R
            ON R.RoleId = CS.RoleIdFK
        INNER JOIN Profile.HealthcareProviders HP
            ON HP.ProviderId = CS.ProviderIdFK
           AND HP.IsActive = 1
        WHERE CS.ClientIdFK = @ClientIdFK
          AND CS.ProviderIdFK = @ProviderIdFK
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
    )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Provider is not an active doctor linked to the selected clinic or hospital.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.Appointments A
        WHERE A.ProviderIdFK = @ProviderIdFK
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

    IF COL_LENGTH('Profile.Appointments', 'ClientIdFK') IS NULL
    BEGIN
        INSERT INTO Profile.Appointments
        (
            AppointmentId,
            PatientIdFK,
            ProviderIdFK,
            AppointmentDateTime,
            DurationMinutes,
            AppointmentType,
            Reason,
            Location,
            Status,
            Reminders,
            Notes,
            CreatedDate,
            CreatedBy,
            UpdatedDate,
            UpdatedBy
        )
        VALUES
        (
            @AppointmentIdOutput,
            @PatientIdFK,
            @ProviderIdFK,
            @AppointmentDateTime,
            @DurationMinutes,
            @NormalizedType,
            @NormalizedReason,
            @NormalizedLocation,
            'Scheduled',
            NULL,
            'Created via operations scheduling API.',
            @Now,
            @Actor,
            @Now,
            @Actor
        );
    END
    ELSE
    BEGIN
        INSERT INTO Profile.Appointments
        (
            AppointmentId,
            PatientIdFK,
            ProviderIdFK,
            AppointmentDateTime,
            DurationMinutes,
            AppointmentType,
            Reason,
            Location,
            Status,
            Reminders,
            Notes,
            CreatedDate,
            CreatedBy,
            UpdatedDate,
            UpdatedBy,
            ClientIdFK
        )
        VALUES
        (
            @AppointmentIdOutput,
            @PatientIdFK,
            @ProviderIdFK,
            @AppointmentDateTime,
            @DurationMinutes,
            @NormalizedType,
            @NormalizedReason,
            @NormalizedLocation,
            'Scheduled',
            NULL,
            'Created via operations scheduling API.',
            @Now,
            @Actor,
            @Now,
            @Actor,
            @ClientIdFK
        );
    END

    SET @StatusCode = 0;
    SET @Message = '';

    SET NOCOUNT OFF;
END
GO
