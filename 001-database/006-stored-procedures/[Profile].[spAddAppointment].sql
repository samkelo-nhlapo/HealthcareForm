USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Inserts a new appointment row for an existing patient and a clinic-linked provider affiliation.
CREATE OR ALTER PROC [Profile].[spAddAppointment]
(
    @ClientIdFK UNIQUEIDENTIFIER,
    @PatientIdNumber VARCHAR(250),
    @ClientStaffIdFK UNIQUEIDENTIFIER = NULL,
    @AppointmentDateTime DATETIME,
    @DurationMinutes INT = 30,
    @AppointmentType VARCHAR(100) = 'Consultation',
    @Reason VARCHAR(MAX) = NULL,
    @Location VARCHAR(250) = NULL,
    @CreatedBy VARCHAR(250) = NULL,
    @AppointmentIdOutput UNIQUEIDENTIFIER OUTPUT,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT,
    @ClientProviderAffiliationIdFK UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Now DATETIME = GETDATE();
    DECLARE @PatientIdFK UNIQUEIDENTIFIER = NULL;
    DECLARE @ResolvedClientIdFK UNIQUEIDENTIFIER = NULL;
    DECLARE @ResolvedProviderIdFK UNIQUEIDENTIFIER = NULL;
    DECLARE @ResolvedClientStaffIdFK UNIQUEIDENTIFIER = NULL;
    DECLARE @ResolvedClientProviderAffiliationIdFK UNIQUEIDENTIFIER = NULL;
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
    DECLARE @AppointmentsHasClientProviderAffiliationId BIT = CASE
        WHEN COL_LENGTH('Profile.Appointments', 'ClientProviderAffiliationIdFK') IS NULL THEN 0
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

    IF
    (
        @ClientStaffIdFK IS NULL
        OR @ClientStaffIdFK = '00000000-0000-0000-0000-000000000000'
    )
    AND
    (
        @ClientProviderAffiliationIdFK IS NULL
        OR @ClientProviderAffiliationIdFK = '00000000-0000-0000-0000-000000000000'
    )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientProviderAffiliationIdFK or ClientStaffIdFK is required.';
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

    IF @ClientProviderAffiliationIdFK IS NOT NULL
       AND @ClientProviderAffiliationIdFK <> '00000000-0000-0000-0000-000000000000'
    BEGIN
        SELECT TOP 1
            @ResolvedClientProviderAffiliationIdFK = CPA.ClientProviderAffiliationId,
            @ResolvedClientIdFK = CPA.ClientIdFK,
            @ResolvedProviderIdFK = CPA.ProviderIdFK,
            @ResolvedClientStaffIdFK = CPA.ClientStaffIdFK
        FROM Profile.ClientProviderAffiliations CPA
        INNER JOIN Profile.Clients C
            ON C.ClientId = CPA.ClientIdFK
           AND C.IsDeleted = 0
           AND C.IsActive = 1
        INNER JOIN Profile.HealthcareProviders HP
            ON HP.ProviderId = CPA.ProviderIdFK
           AND HP.IsActive = 1
        LEFT JOIN Profile.ClientStaff CS
            ON CS.ClientStaffId = CPA.ClientStaffIdFK
        WHERE CPA.ClientProviderAffiliationId = @ClientProviderAffiliationIdFK
          AND CPA.IsActive = 1
          AND CPA.CanBookAppointments = 1
          AND CPA.StartDate <= @AppointmentDateTime
          AND (CPA.EndDate IS NULL OR CPA.EndDate >= @AppointmentDateTime)
          AND
          (
              CPA.ClientStaffIdFK IS NULL
              OR (CS.ClientStaffId IS NOT NULL AND CS.IsDeleted = 0 AND CS.IsActive = 1)
          )
        ORDER BY
            CASE
                WHEN CPA.ClientStaffIdFK IS NOT NULL THEN 0
                ELSE 1
            END,
            COALESCE(CPA.UpdatedDate, CPA.CreatedDate) DESC,
            CPA.ClientProviderAffiliationId DESC;

        IF @ResolvedClientProviderAffiliationIdFK IS NULL
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Selected provider affiliation is not active or bookable.';
            RETURN;
        END

        IF @ClientStaffIdFK IS NOT NULL
           AND @ClientStaffIdFK <> '00000000-0000-0000-0000-000000000000'
           AND @ResolvedClientStaffIdFK IS NOT NULL
           AND @ResolvedClientStaffIdFK <> @ClientStaffIdFK
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Selected staff member does not match the chosen provider affiliation.';
            RETURN;
        END
    END
    ELSE
    BEGIN
        SELECT TOP 1
            @ResolvedClientProviderAffiliationIdFK = CPA.ClientProviderAffiliationId,
            @ResolvedClientIdFK = CS.ClientIdFK,
            @ResolvedProviderIdFK = CS.ProviderIdFK,
            @ResolvedClientStaffIdFK = CS.ClientStaffId
        FROM Profile.ClientStaff CS
        LEFT JOIN Auth.Roles R
            ON R.RoleId = CS.RoleIdFK
        INNER JOIN Profile.HealthcareProviders HP
            ON HP.ProviderId = CS.ProviderIdFK
           AND HP.IsActive = 1
        INNER JOIN Profile.ClientProviderAffiliations CPA
            ON CPA.ClientStaffIdFK = CS.ClientStaffId
           AND CPA.ClientIdFK = CS.ClientIdFK
           AND CPA.ProviderIdFK = CS.ProviderIdFK
           AND CPA.IsActive = 1
           AND CPA.CanBookAppointments = 1
           AND CPA.StartDate <= @AppointmentDateTime
           AND (CPA.EndDate IS NULL OR CPA.EndDate >= @AppointmentDateTime)
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
        ORDER BY
            CASE
                WHEN CPA.EndDate IS NULL THEN 0
                ELSE 1
            END,
            COALESCE(CPA.UpdatedDate, CPA.CreatedDate) DESC,
            CPA.ClientProviderAffiliationId DESC;

        IF @ResolvedClientProviderAffiliationIdFK IS NULL
        BEGIN
            SET @StatusCode = 1;
            SET @Message = 'Selected doctor is not linked to an active bookable provider affiliation.';
            RETURN;
        END
    END

    IF @ResolvedClientIdFK <> @ClientIdFK
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Selected provider affiliation is not linked to the chosen clinic or hospital.';
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

    IF @AppointmentsHasClientProviderAffiliationId = 1
    BEGIN
        SET @InsertColumns += N', ClientProviderAffiliationIdFK';
        SET @InsertValues += N', @ResolvedClientProviderAffiliationIdFK';
    END

    IF @AppointmentsHasClientStaffId = 1
    BEGIN
        SET @InsertColumns += N', ClientStaffIdFK';
        SET @InsertValues += N', @ResolvedClientStaffIdFK';
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
        N'@AppointmentIdOutput UNIQUEIDENTIFIER, @PatientIdFK UNIQUEIDENTIFIER, @ClientIdFK UNIQUEIDENTIFIER, @ResolvedClientProviderAffiliationIdFK UNIQUEIDENTIFIER, @ResolvedClientStaffIdFK UNIQUEIDENTIFIER, @ResolvedProviderIdFK UNIQUEIDENTIFIER, @AppointmentDateTime DATETIME, @DurationMinutes INT, @NormalizedType VARCHAR(100), @NormalizedReason VARCHAR(MAX), @NormalizedLocation VARCHAR(250), @Now DATETIME, @Actor VARCHAR(250)',
        @AppointmentIdOutput = @AppointmentIdOutput,
        @PatientIdFK = @PatientIdFK,
        @ClientIdFK = @ClientIdFK,
        @ResolvedClientProviderAffiliationIdFK = @ResolvedClientProviderAffiliationIdFK,
        @ResolvedClientStaffIdFK = @ResolvedClientStaffIdFK,
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
