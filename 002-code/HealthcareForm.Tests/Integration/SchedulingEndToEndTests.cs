using HealthcareForm.Contracts.Operations;
using System.Data.SqlClient;
using System.Net;
using System.Net.Http.Json;

namespace HealthcareForm.Tests.Integration;

public sealed class SchedulingEndToEndTests
{
    [Fact]
    public async Task SchedulingAppointment_CreatesAppointment_AndCanBeTracedAcrossApis()
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        var traceId = Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
        SchedulingSeed? seed = null;
        AppointmentRow? appointmentRow = null;
        Guid? appointmentId = null;

        try
        {
            seed = await EnsureSchedulingSeedAsync(connectionString, traceId);
            var appointmentDateTime = await FindAvailableAppointmentTimeAsync(connectionString, seed.ProviderId);

            using var factory = new TestApplicationFactory(connectionString);
            using var client = factory.CreateClient();

            var bookingOptionsResponse = await client.GetAsync("/api/operations/scheduling/booking-options");
            Assert.Equal(HttpStatusCode.OK, bookingOptionsResponse.StatusCode);

            var bookingOptions = await bookingOptionsResponse.Content.ReadFromJsonAsync<SchedulingBookingOptionsDto>();
            Assert.NotNull(bookingOptions);
            Assert.Contains(bookingOptions!.Clients, item => item.ClientId == seed.ClientId.ToString());
            Assert.Contains(
                bookingOptions.Providers,
                item => item.ClientId == seed.ClientId.ToString()
                    && item.ClientProviderAffiliationId == seed.ClientProviderAffiliationId.ToString());

            var createResponse = await client.PostAsJsonAsync(
                "/api/operations/scheduling/appointments",
                new SchedulingAppointmentCreateRequest
                {
                    ClientId = seed.ClientId,
                    PatientIdNumber = seed.PatientIdNumber,
                    ClientProviderAffiliationId = seed.ClientProviderAffiliationId,
                    ClientStaffId = seed.ClientStaffId == Guid.Empty ? null : seed.ClientStaffId,
                    AppointmentDateTime = appointmentDateTime,
                    DurationMinutes = 30,
                    AppointmentType = $"Integration Scheduling {traceId}",
                    Reason = $"Scheduling integration trace {traceId}",
                    Location = "Integration Trace Room"
                });

            Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

            var createPayload = await createResponse.Content.ReadFromJsonAsync<SchedulingAppointmentCommandResult>();
            Assert.NotNull(createPayload);
            Assert.True(createPayload!.Success);
            Assert.True(createPayload.AppointmentId.HasValue);

            appointmentId = createPayload.AppointmentId.Value;
            appointmentRow = await LoadAppointmentAsync(connectionString, appointmentId.Value);

            Assert.NotNull(appointmentRow);
            Assert.Equal(seed.PatientId, appointmentRow!.PatientId);
            Assert.Equal(seed.ClientId, appointmentRow.ClientId);
            Assert.Equal(seed.ClientProviderAffiliationId, appointmentRow.ClientProviderAffiliationId);
            Assert.Equal(seed.ClientStaffId == Guid.Empty ? null : seed.ClientStaffId, appointmentRow.ClientStaffId);
            Assert.Equal(seed.ProviderId, appointmentRow.ProviderId);
            Assert.Equal("Scheduled", appointmentRow.Status);
            Assert.Equal("Integration Trace Room", appointmentRow.Location);

            var snapshotResponse = await client.GetAsync("/api/operations/scheduling");
            Assert.Equal(HttpStatusCode.OK, snapshotResponse.StatusCode);

            var snapshot = await snapshotResponse.Content.ReadFromJsonAsync<SchedulingSnapshotDto>();
            Assert.NotNull(snapshot);

            var providerLoad = Assert.Single(
                snapshot!.Providers,
                item => item.ClientProviderAffiliationId == seed.ClientProviderAffiliationId.ToString());
            if (appointmentDateTime.Date == DateTime.Today)
            {
                Assert.True(providerLoad.Booked > 0);
            }
        }
        finally
        {
            if (appointmentId.HasValue)
            {
                await DeleteAppointmentAsync(connectionString, appointmentId.Value);
            }

            if (seed is { InsertedClientProviderAffiliation: true } && seed.ClientProviderAffiliationId != Guid.Empty)
            {
                await DeleteClientProviderAffiliationAsync(connectionString, seed.ClientProviderAffiliationId);
            }

            if (seed is { InsertedClientStaff: true } && seed.ClientStaffId != Guid.Empty)
            {
                await DeleteClientStaffAsync(connectionString, seed.ClientStaffId);
            }
        }
    }

    private static async Task<SchedulingSeed> EnsureSchedulingSeedAsync(string connectionString, string traceId)
    {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand(
            """
            SET NOCOUNT ON;

            DECLARE @PatientClientsHasIsDeleted BIT = CASE
                WHEN COL_LENGTH('Profile.PatientClients', 'IsDeleted') IS NULL THEN 0
                ELSE 1
            END;
            DECLARE @PatientId UNIQUEIDENTIFIER = NULL;
            DECLARE @PatientIdNumber VARCHAR(250) = NULL;
            DECLARE @ClientId UNIQUEIDENTIFIER = NULL;
            DECLARE @ProviderId UNIQUEIDENTIFIER = NULL;
            DECLARE @ClientProviderAffiliationId UNIQUEIDENTIFIER = NULL;
            DECLARE @ClientStaffId UNIQUEIDENTIFIER = NULL;
            DECLARE @InsertedClientStaff BIT = 0;
            DECLARE @InsertedClientProviderAffiliation BIT = 0;
            DECLARE @DoctorRoleId UNIQUEIDENTIFIER = NULL;
            DECLARE @ResolvePatientClientSql NVARCHAR(MAX) = N'';

            SELECT TOP 1
                @PatientId = P.PatientId,
                @PatientIdNumber = LTRIM(RTRIM(P.ID_Number))
            FROM Profile.Patient P
            WHERE P.IsDeleted = 0
              AND LEN(LTRIM(RTRIM(ISNULL(P.ID_Number, '')))) = 13
              AND LTRIM(RTRIM(P.ID_Number)) NOT LIKE '%[^0-9]%'
            ORDER BY COALESCE(P.UpdatedDate, P.CreatedDate) DESC, P.PatientId DESC;

            IF @PatientId IS NULL
                THROW 50001, 'No valid patient record was found for scheduling integration.', 1;

            IF OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL
            BEGIN
                SET @ResolvePatientClientSql = N'
                    SELECT TOP 1 @ResolvedClientId = PC.ClientIdFK
                    FROM Profile.PatientClients PC
                    INNER JOIN Profile.Clients C
                        ON C.ClientId = PC.ClientIdFK
                       AND C.IsDeleted = 0
                       AND C.IsActive = 1
                    WHERE PC.PatientIdFK = @PatientId'
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
                    N'@PatientId UNIQUEIDENTIFIER, @ResolvedClientId UNIQUEIDENTIFIER OUTPUT',
                    @PatientId = @PatientId,
                    @ResolvedClientId = @ClientId OUTPUT;
            END

            IF @ClientId IS NULL AND COL_LENGTH('Profile.Patient', 'ClientIdFK') IS NOT NULL
            BEGIN
                SELECT TOP 1 @ClientId = P.ClientIdFK
                FROM Profile.Patient P
                INNER JOIN Profile.Clients C
                    ON C.ClientId = P.ClientIdFK
                   AND C.IsDeleted = 0
                   AND C.IsActive = 1
                WHERE P.PatientId = @PatientId;
            END

            IF @ClientId IS NULL
            BEGIN
                SELECT TOP 1 @ClientId = C.ClientId
                FROM Profile.Clients C
                WHERE C.IsDeleted = 0
                  AND C.IsActive = 1
                ORDER BY COALESCE(C.UpdatedDate, C.CreatedDate) DESC, C.ClientId DESC;
            END

            IF @ClientId IS NULL
                THROW 50002, 'No active client record was found for scheduling integration.', 1;

            SELECT TOP 1
                @ClientProviderAffiliationId = CPA.ClientProviderAffiliationId,
                @ProviderId = CPA.ProviderIdFK,
                @ClientStaffId = CPA.ClientStaffIdFK
            FROM Profile.ClientProviderAffiliations CPA
            INNER JOIN Profile.HealthcareProviders HP
                ON HP.ProviderId = CPA.ProviderIdFK
               AND HP.IsActive = 1
            LEFT JOIN Profile.ClientStaff CS
                ON CS.ClientStaffId = CPA.ClientStaffIdFK
            WHERE CPA.ClientIdFK = @ClientId
              AND CPA.IsActive = 1
              AND CPA.CanBookAppointments = 1
              AND CPA.StartDate <= GETDATE()
              AND (CPA.EndDate IS NULL OR CPA.EndDate >= GETDATE())
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

            IF @ClientProviderAffiliationId IS NULL
            BEGIN
                SELECT TOP 1
                    @ProviderId = CS.ProviderIdFK,
                    @ClientStaffId = CS.ClientStaffId
                FROM Profile.ClientStaff CS
                LEFT JOIN Auth.Roles R
                    ON R.RoleId = CS.RoleIdFK
                INNER JOIN Profile.HealthcareProviders HP
                    ON HP.ProviderId = CS.ProviderIdFK
                   AND HP.IsActive = 1
                WHERE CS.ClientIdFK = @ClientId
                  AND CS.ProviderIdFK IS NOT NULL
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

                IF @ProviderId IS NULL
                BEGIN
                    SELECT TOP 1 @DoctorRoleId = R.RoleId
                    FROM Auth.Roles R
                    WHERE UPPER(R.RoleName) = 'DOCTOR';

                    SELECT TOP 1 @ProviderId = HP.ProviderId
                    FROM Profile.HealthcareProviders HP
                    WHERE HP.IsActive = 1
                    ORDER BY COALESCE(HP.UpdatedDate, HP.CreatedDate) DESC, HP.ProviderId DESC;

                    IF @ProviderId IS NULL OR @DoctorRoleId IS NULL
                        THROW 50003, 'No active provider or doctor role was found for scheduling integration.', 1;

                    SET @ClientStaffId = NEWID();

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
                        UpdatedBy,
                        StaffDesignationIdFK,
                        PrimaryDepartmentIdFK
                    )
                    VALUES
                    (
                        @ClientStaffId,
                        @ClientId,
                        @DoctorRoleId,
                        NULL,
                        @ProviderId,
                        'E2E-SCHED-' + @TraceId,
                        'Integration',
                        'Doctor',
                        LOWER('e2e.scheduling.' + @TraceId + '@healthcareform.local'),
                        '+27100000000',
                        'Medical Doctor',
                        'Clinical',
                        'Clinical',
                        'Full-Time',
                        GETDATE(),
                        NULL,
                        0,
                        1,
                        0,
                        GETDATE(),
                        'E2E_SCHED',
                        GETDATE(),
                        'E2E_SCHED',
                        NULL,
                        NULL
                    );

                    SET @InsertedClientStaff = 1;
                END

                SET @ClientProviderAffiliationId = NEWID();

                INSERT INTO Profile.ClientProviderAffiliations
                (
                    ClientProviderAffiliationId,
                    ClientIdFK,
                    ProviderIdFK,
                    ClientStaffIdFK,
                    PrimaryDepartmentIdFK,
                    RelationshipType,
                    CanBookAppointments,
                    CanReceiveReferrals,
                    StartDate,
                    EndDate,
                    IsActive,
                    Notes,
                    CreatedDate,
                    CreatedBy,
                    UpdatedDate,
                    UpdatedBy
                )
                VALUES
                (
                    @ClientProviderAffiliationId,
                    @ClientId,
                    @ProviderId,
                    @ClientStaffId,
                    NULL,
                    'Employee',
                    1,
                    1,
                    GETDATE(),
                    NULL,
                    1,
                    'Scheduling integration seed row.',
                    GETDATE(),
                    'E2E_SCHED',
                    GETDATE(),
                    'E2E_SCHED'
                );

                SET @InsertedClientProviderAffiliation = 1;
            END

            SELECT
                PatientId = @PatientId,
                PatientIdNumber = @PatientIdNumber,
                ClientId = @ClientId,
                ProviderId = @ProviderId,
                ClientProviderAffiliationId = @ClientProviderAffiliationId,
                ClientStaffId = @ClientStaffId,
                InsertedClientStaff = @InsertedClientStaff,
                InsertedClientProviderAffiliation = @InsertedClientProviderAffiliation;
            """,
            connection);

        command.Parameters.AddWithValue("@TraceId", traceId);

        await using var reader = await command.ExecuteReaderAsync();
        Assert.True(await reader.ReadAsync(), "Expected scheduling seed data to be prepared.");

        return new SchedulingSeed(
            reader.GetGuid(reader.GetOrdinal("PatientId")),
            reader.GetString(reader.GetOrdinal("PatientIdNumber")),
            reader.GetGuid(reader.GetOrdinal("ClientId")),
            reader.GetGuid(reader.GetOrdinal("ProviderId")),
            reader.GetGuid(reader.GetOrdinal("ClientProviderAffiliationId")),
            reader.IsDBNull(reader.GetOrdinal("ClientStaffId"))
                ? Guid.Empty
                : reader.GetGuid(reader.GetOrdinal("ClientStaffId")),
            reader.GetBoolean(reader.GetOrdinal("InsertedClientStaff")),
            reader.GetBoolean(reader.GetOrdinal("InsertedClientProviderAffiliation")));
    }

    private static async Task<DateTime> FindAvailableAppointmentTimeAsync(string connectionString, Guid providerId)
    {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand(
            """
            SELECT
                AppointmentDateTime,
                DurationMinutes = CASE
                    WHEN ISNULL(DurationMinutes, 0) < 5 THEN 30
                    ELSE DurationMinutes
                END
            FROM Profile.Appointments
            WHERE ProviderIdFK = @ProviderId
              AND UPPER(LTRIM(RTRIM(ISNULL(Status, '')))) NOT IN ('CANCELLED', 'NO-SHOW', 'NO SHOW', 'COMPLETED')
              AND AppointmentDateTime >= DATEADD(MINUTE, -30, GETDATE())
              AND AppointmentDateTime < DATEADD(DAY, 2, GETDATE())
            ORDER BY AppointmentDateTime;
            """,
            connection);

        command.Parameters.AddWithValue("@ProviderId", providerId);

        var occupiedSlots = new List<(DateTime Start, DateTime End)>();
        await using (var reader = await command.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
            {
                var start = reader.GetDateTime(reader.GetOrdinal("AppointmentDateTime"));
                var durationMinutes = reader.GetInt32(reader.GetOrdinal("DurationMinutes"));
                occupiedSlots.Add((start, start.AddMinutes(durationMinutes)));
            }
        }

        var candidate = RoundUpToNextHalfHour(DateTime.Now.AddMinutes(15));
        for (var index = 0; index < 96; index += 1)
        {
            var slotStart = candidate.AddMinutes(index * 30);
            var slotEnd = slotStart.AddMinutes(30);
            var overlaps = occupiedSlots.Any((slot) => slot.Start < slotEnd && slot.End > slotStart);
            if (!overlaps)
            {
                return slotStart;
            }
        }

        throw new InvalidOperationException("Unable to find an available scheduling slot for the seeded provider.");
    }

    private static async Task<AppointmentRow?> LoadAppointmentAsync(string connectionString, Guid appointmentId)
    {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand(
            """
            SELECT
                AppointmentId,
                PatientIdFK,
                ClientProviderAffiliationIdFK,
                ClientStaffIdFK,
                ProviderIdFK,
                ClientIdFK,
                Status,
                Location
            FROM Profile.Appointments
            WHERE AppointmentId = @AppointmentId;
            """,
            connection);

        command.Parameters.AddWithValue("@AppointmentId", appointmentId);

        await using var reader = await command.ExecuteReaderAsync();
        if (!await reader.ReadAsync())
        {
            return null;
        }

        return new AppointmentRow(
            reader.GetGuid(reader.GetOrdinal("AppointmentId")),
            reader.GetGuid(reader.GetOrdinal("PatientIdFK")),
            reader.GetGuid(reader.GetOrdinal("ClientProviderAffiliationIdFK")),
            reader.IsDBNull(reader.GetOrdinal("ClientStaffIdFK"))
                ? null
                : reader.GetGuid(reader.GetOrdinal("ClientStaffIdFK")),
            reader.GetGuid(reader.GetOrdinal("ProviderIdFK")),
            reader.IsDBNull(reader.GetOrdinal("ClientIdFK"))
                ? Guid.Empty
                : reader.GetGuid(reader.GetOrdinal("ClientIdFK")),
            reader.GetString(reader.GetOrdinal("Status")),
            reader.IsDBNull(reader.GetOrdinal("Location"))
                ? string.Empty
                : reader.GetString(reader.GetOrdinal("Location")));
    }

    private static async Task DeleteAppointmentAsync(string connectionString, Guid appointmentId)
    {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand(
            "DELETE FROM Profile.Appointments WHERE AppointmentId = @AppointmentId;",
            connection);

        command.Parameters.AddWithValue("@AppointmentId", appointmentId);
        await command.ExecuteNonQueryAsync();
    }

    private static async Task DeleteClientProviderAffiliationAsync(string connectionString, Guid clientProviderAffiliationId)
    {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand(
            "DELETE FROM Profile.ClientProviderAffiliations WHERE ClientProviderAffiliationId = @ClientProviderAffiliationId;",
            connection);

        command.Parameters.AddWithValue("@ClientProviderAffiliationId", clientProviderAffiliationId);
        await command.ExecuteNonQueryAsync();
    }

    private static async Task DeleteClientStaffAsync(string connectionString, Guid clientStaffId)
    {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand(
            "DELETE FROM Profile.ClientStaff WHERE ClientStaffId = @ClientStaffId;",
            connection);

        command.Parameters.AddWithValue("@ClientStaffId", clientStaffId);
        await command.ExecuteNonQueryAsync();
    }

    private static DateTime RoundUpToNextHalfHour(DateTime value)
    {
        var normalized = new DateTime(value.Year, value.Month, value.Day, value.Hour, value.Minute, 0);
        var remainder = normalized.Minute % 30;
        if (remainder == 0)
        {
            return normalized;
        }

        return normalized.AddMinutes(30 - remainder);
    }

    private sealed record SchedulingSeed(
        Guid PatientId,
        string PatientIdNumber,
        Guid ClientId,
        Guid ProviderId,
        Guid ClientProviderAffiliationId,
        Guid ClientStaffId,
        bool InsertedClientStaff,
        bool InsertedClientProviderAffiliation);

    private sealed record AppointmentRow(
        Guid AppointmentId,
        Guid PatientId,
        Guid ClientProviderAffiliationId,
        Guid? ClientStaffId,
        Guid ProviderId,
        Guid ClientId,
        string Status,
        string Location);
}
