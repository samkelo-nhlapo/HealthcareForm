SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Inserts a new appointment row for an existing patient and provider.
CREATE OR ALTER PROC [Profile].[spAddAppointment]
(
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
    DECLARE @ClientIdFK UNIQUEIDENTIFIER = NULL;
    DECLARE @PatientClientsHasIsDeleted BIT = CASE
        WHEN COL_LENGTH('Profile.PatientClients', 'IsDeleted') IS NULL THEN 0
        ELSE 1
    END;
    DECLARE @ResolvePatientClientSql NVARCHAR(MAX) = N'';
    DECLARE @NormalizedIdNumber VARCHAR(250) = LTRIM(RTRIM(ISNULL(@PatientIdNumber, '')));
    DECLARE @NormalizedType VARCHAR(100) = LEFT(LTRIM(RTRIM(ISNULL(@AppointmentType, ''))), 100);
    DECLARE @NormalizedReason VARCHAR(MAX) = NULLIF(LTRIM(RTRIM(ISNULL(@Reason, ''))), '');
    DECLARE @NormalizedLocation VARCHAR(250) = NULLIF(LTRIM(RTRIM(ISNULL(@Location, ''))), '');
    DECLARE @Actor VARCHAR(250) = COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(@CreatedBy, ''))), ''), SUSER_SNAME());

    SET @AppointmentIdOutput = NULL;
    SET @StatusCode = -1;
    SET @Message = '';

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

    IF NOT EXISTS
    (
        SELECT 1
        FROM Profile.HealthcareProviders HP
        WHERE HP.ProviderId = @ProviderIdFK
          AND HP.IsActive = 1
    )
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Provider does not exist or is inactive.';
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

    IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
    BEGIN
        SET @ResolvePatientClientSql = N'
            SELECT TOP 1 @ResolvedClientId = PC.ClientIdFK
            FROM Profile.PatientClients PC
            WHERE PC.PatientIdFK = @PatientIdFK'
            + CASE
                WHEN @PatientClientsHasIsDeleted = 1
                    THEN N' AND (PC.IsDeleted = 0 OR PC.IsDeleted IS NULL)'
                ELSE N''
              END
            + N'
            ORDER BY
                CASE WHEN ISNULL(PC.IsPrimary, 0) = 1 THEN 0 ELSE 1 END,
                COALESCE(PC.UpdatedDate, PC.CreatedDate) DESC;';

        EXEC sys.sp_executesql
            @ResolvePatientClientSql,
            N'@PatientIdFK UNIQUEIDENTIFIER, @ResolvedClientId UNIQUEIDENTIFIER OUTPUT',
            @PatientIdFK = @PatientIdFK,
            @ResolvedClientId = @ClientIdFK OUTPUT;
    END

    IF @ClientIdFK IS NULL AND COL_LENGTH('Profile.Patient', 'ClientIdFK') IS NOT NULL
    BEGIN
        SELECT TOP 1 @ClientIdFK = P.ClientIdFK
        FROM Profile.Patient P
        WHERE P.PatientId = @PatientIdFK;
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
