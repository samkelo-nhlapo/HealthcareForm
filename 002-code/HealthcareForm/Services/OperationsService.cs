using HealthcareForm.Contracts.Operations;
using System.Data;
using System.Data.SqlClient;

namespace HealthcareForm.Services;

public sealed class OperationsService : IOperationsService
{
    private const string ConnectionStringKey = "HealthcareEntity";
    private const int DefaultProviderCapacity = 12;
    private const int SlotsPerBlockPerProvider = 4;
    private const int MaxTaskQueueRows = 300;

    private static readonly string[] ClinicOrder =
    [
        "General",
        "Cardiology",
        "Pediatrics",
        "Oncology"
    ];

    private readonly IConfiguration _configuration;
    private readonly ILogger<OperationsService> _logger;

    public OperationsService(IConfiguration configuration, ILogger<OperationsService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<SchedulingSnapshotDto> GetSchedulingSnapshotAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await connection.OpenAsync(cancellationToken);

            var providers = await GetProvidersAsync(connection, cancellationToken);
            var appointments = await GetAppointmentsAsync(connection, cancellationToken);

            var providerLoads = BuildProviderLoads(providers, appointments);
            var resourceLoads = BuildResourceLoads(providerLoads, appointments);
            var timeBlocks = BuildTimeBlocks(providerLoads, appointments);

            return new SchedulingSnapshotDto
            {
                Providers = providerLoads,
                Resources = resourceLoads,
                Blocks = timeBlocks
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to build operations scheduling snapshot.");
            return new SchedulingSnapshotDto();
        }
    }

    public async Task<TaskQueueSnapshotDto> GetTaskQueueSnapshotAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await connection.OpenAsync(cancellationToken);

            var sourceRows = new List<TaskQueueSourceRow>();
            sourceRows.AddRange(await GetAppointmentQueueRowsAsync(connection, cancellationToken));
            sourceRows.AddRange(await GetLabQueueRowsAsync(connection, cancellationToken));
            sourceRows.AddRange(await GetBillingQueueRowsAsync(connection, cancellationToken));

            var now = DateTime.Now;
            var tasks = sourceRows
                .Select(row => new
                {
                    row,
                    item = ToTaskQueueItem(row, now)
                })
                .OrderByDescending(item => CalculateTaskSortScore(item.item))
                .ThenBy(item => item.row.DueAt)
                .Take(MaxTaskQueueRows)
                .Select(item => item.item)
                .ToList();

            return new TaskQueueSnapshotDto
            {
                Tasks = tasks
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to build operations task queue snapshot.");
            return new TaskQueueSnapshotDto();
        }
    }

    private async Task<IReadOnlyList<ProviderRow>> GetProvidersAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        var providers = new List<ProviderRow>();

        await using var command = new SqlCommand(
            @"
SELECT
    HP.ProviderId,
    HP.FirstName,
    HP.LastName,
    HP.Title,
    HP.Specialization
FROM Profile.HealthcareProviders HP
WHERE HP.IsActive = 1
ORDER BY HP.LastName, HP.FirstName;",
            connection);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var providerIdOrdinal = reader.GetOrdinal("ProviderId");
        var firstNameOrdinal = reader.GetOrdinal("FirstName");
        var lastNameOrdinal = reader.GetOrdinal("LastName");
        var titleOrdinal = reader.GetOrdinal("Title");
        var specializationOrdinal = reader.GetOrdinal("Specialization");

        while (await reader.ReadAsync(cancellationToken))
        {
            var providerId = reader.GetGuid(providerIdOrdinal);
            var firstName = GetString(reader, firstNameOrdinal);
            var lastName = GetString(reader, lastNameOrdinal);
            var title = GetString(reader, titleOrdinal);
            var specialization = GetString(reader, specializationOrdinal);

            var displayName = BuildProviderDisplayName(title, firstName, lastName);

            providers.Add(new ProviderRow
            {
                ProviderId = providerId,
                DisplayName = displayName,
                Clinic = NormalizeClinic(specialization)
            });
        }

        return providers;
    }

    private async Task<IReadOnlyList<AppointmentRow>> GetAppointmentsAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        var appointments = new List<AppointmentRow>();
        var windowStart = DateTime.Today;
        var windowEnd = windowStart.AddDays(1);

        await using var command = new SqlCommand(
            @"
SELECT
    A.ProviderIdFK,
    A.AppointmentDateTime,
    A.DurationMinutes,
    A.Status,
    A.Location,
    HP.Specialization
FROM Profile.Appointments A
LEFT JOIN Profile.HealthcareProviders HP
    ON HP.ProviderId = A.ProviderIdFK
WHERE A.AppointmentDateTime >= @WindowStart
  AND A.AppointmentDateTime < @WindowEnd;",
            connection);

        command.Parameters.Add(new SqlParameter("@WindowStart", SqlDbType.DateTime) { Value = windowStart });
        command.Parameters.Add(new SqlParameter("@WindowEnd", SqlDbType.DateTime) { Value = windowEnd });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var providerIdOrdinal = reader.GetOrdinal("ProviderIdFK");
        var appointmentDateTimeOrdinal = reader.GetOrdinal("AppointmentDateTime");
        var durationMinutesOrdinal = reader.GetOrdinal("DurationMinutes");
        var statusOrdinal = reader.GetOrdinal("Status");
        var locationOrdinal = reader.GetOrdinal("Location");
        var specializationOrdinal = reader.GetOrdinal("Specialization");

        while (await reader.ReadAsync(cancellationToken))
        {
            if (reader.IsDBNull(providerIdOrdinal))
            {
                continue;
            }

            var duration = reader.IsDBNull(durationMinutesOrdinal)
                ? 30
                : Math.Max(5, Convert.ToInt32(reader.GetValue(durationMinutesOrdinal)));

            appointments.Add(new AppointmentRow
            {
                ProviderId = reader.GetGuid(providerIdOrdinal),
                AppointmentDateTime = Convert.ToDateTime(reader.GetValue(appointmentDateTimeOrdinal)),
                DurationMinutes = duration,
                Status = GetString(reader, statusOrdinal),
                Location = GetString(reader, locationOrdinal),
                Clinic = NormalizeClinic(GetString(reader, specializationOrdinal))
            });
        }

        return appointments;
    }

    private async Task<IReadOnlyList<TaskQueueSourceRow>> GetAppointmentQueueRowsAsync(
        SqlConnection connection,
        CancellationToken cancellationToken)
    {
        var rows = new List<TaskQueueSourceRow>();

        await using var command = new SqlCommand(
            @"
SELECT TOP (@MaxRows)
    A.AppointmentId,
    A.AppointmentType,
    A.Reason,
    A.Status,
    A.DurationMinutes,
    A.AppointmentDateTime,
    A.CreatedDate,
    A.UpdatedDate,
    HP.Specialization,
    HP.Title,
    HP.FirstName AS ProviderFirstName,
    HP.LastName AS ProviderLastName,
    P.FirstName AS PatientFirstName,
    P.LastName AS PatientLastName,
    P.ID_Number AS IdNumber
FROM Profile.Appointments A
INNER JOIN Profile.Patient P
    ON P.PatientId = A.PatientIdFK
LEFT JOIN Profile.HealthcareProviders HP
    ON HP.ProviderId = A.ProviderIdFK
WHERE P.IsDeleted = 0
  AND A.AppointmentDateTime >= DATEADD(day, -2, GETDATE())
ORDER BY A.AppointmentDateTime ASC, COALESCE(A.UpdatedDate, A.CreatedDate) DESC;",
            connection);

        command.Parameters.Add(new SqlParameter("@MaxRows", SqlDbType.Int) { Value = MaxTaskQueueRows });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var appointmentIdOrdinal = reader.GetOrdinal("AppointmentId");
        var appointmentTypeOrdinal = reader.GetOrdinal("AppointmentType");
        var reasonOrdinal = reader.GetOrdinal("Reason");
        var statusOrdinal = reader.GetOrdinal("Status");
        var durationOrdinal = reader.GetOrdinal("DurationMinutes");
        var appointmentDateTimeOrdinal = reader.GetOrdinal("AppointmentDateTime");
        var createdDateOrdinal = reader.GetOrdinal("CreatedDate");
        var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");
        var specializationOrdinal = reader.GetOrdinal("Specialization");
        var providerTitleOrdinal = reader.GetOrdinal("Title");
        var providerFirstNameOrdinal = reader.GetOrdinal("ProviderFirstName");
        var providerLastNameOrdinal = reader.GetOrdinal("ProviderLastName");
        var patientFirstNameOrdinal = reader.GetOrdinal("PatientFirstName");
        var patientLastNameOrdinal = reader.GetOrdinal("PatientLastName");
        var idNumberOrdinal = reader.GetOrdinal("IdNumber");

        while (await reader.ReadAsync(cancellationToken))
        {
            var appointmentId = GetGuid(reader, appointmentIdOrdinal);
            var appointmentType = GetString(reader, appointmentTypeOrdinal, "Consultation");
            var reason = GetString(reader, reasonOrdinal);
            var sourceStatus = GetString(reader, statusOrdinal, "Open");
            var specialization = GetString(reader, specializationOrdinal);
            var providerTitle = GetString(reader, providerTitleOrdinal);
            var providerFirstName = GetString(reader, providerFirstNameOrdinal);
            var providerLastName = GetString(reader, providerLastNameOrdinal);
            var owner = BuildProviderDisplayName(providerTitle, providerFirstName, providerLastName);
            var dueAt = GetDateTime(reader, appointmentDateTimeOrdinal, DateTime.Now);
            var createdAt = GetDateTime(reader, createdDateOrdinal, dueAt.AddMinutes(-30));
            var startedAt = GetDateTime(reader, updatedDateOrdinal, createdAt);
            var durationMinutes = GetInt(reader, durationOrdinal, 30);

            rows.Add(new TaskQueueSourceRow
            {
                TaskId = BuildTaskId("APT", appointmentId),
                Title = BuildAppointmentTaskTitle(appointmentType, reason),
                Team = ResolveAppointmentTeam(appointmentType, reason, specialization),
                Owner = string.IsNullOrWhiteSpace(owner) ? "Care Team" : owner,
                Patient = BuildPatientName(
                    GetString(reader, patientFirstNameOrdinal),
                    GetString(reader, patientLastNameOrdinal)),
                IdNumber = GetString(reader, idNumberOrdinal),
                SourceStatus = sourceStatus,
                DueAt = dueAt,
                StartedAt = startedAt,
                SlaMinutes = Math.Max(15, durationMinutes)
            });
        }

        return rows;
    }

    private async Task<IReadOnlyList<TaskQueueSourceRow>> GetLabQueueRowsAsync(
        SqlConnection connection,
        CancellationToken cancellationToken)
    {
        var rows = new List<TaskQueueSourceRow>();

        await using var command = new SqlCommand(
            @"
SELECT TOP (@MaxRows)
    LR.LabResultId,
    LR.TestName,
    LR.Status,
    LR.CollectionDate,
    LR.ResultDate,
    LR.CreatedDate,
    LR.UpdatedDate,
    LR.OrderedBy,
    P.FirstName AS PatientFirstName,
    P.LastName AS PatientLastName,
    P.ID_Number AS IdNumber
FROM Profile.LabResults LR
INNER JOIN Profile.Patient P
    ON P.PatientId = LR.PatientIdFK
WHERE P.IsDeleted = 0
  AND COALESCE(LR.ResultDate, LR.CollectionDate, LR.CreatedDate) >= DATEADD(day, -21, GETDATE())
ORDER BY COALESCE(LR.ResultDate, LR.CollectionDate, LR.CreatedDate) DESC;",
            connection);

        command.Parameters.Add(new SqlParameter("@MaxRows", SqlDbType.Int) { Value = MaxTaskQueueRows });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var labResultIdOrdinal = reader.GetOrdinal("LabResultId");
        var testNameOrdinal = reader.GetOrdinal("TestName");
        var statusOrdinal = reader.GetOrdinal("Status");
        var collectionDateOrdinal = reader.GetOrdinal("CollectionDate");
        var resultDateOrdinal = reader.GetOrdinal("ResultDate");
        var createdDateOrdinal = reader.GetOrdinal("CreatedDate");
        var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");
        var orderedByOrdinal = reader.GetOrdinal("OrderedBy");
        var patientFirstNameOrdinal = reader.GetOrdinal("PatientFirstName");
        var patientLastNameOrdinal = reader.GetOrdinal("PatientLastName");
        var idNumberOrdinal = reader.GetOrdinal("IdNumber");

        while (await reader.ReadAsync(cancellationToken))
        {
            var sourceStatus = GetString(reader, statusOrdinal, "Pending");
            var resultDate = GetDateTime(
                reader,
                resultDateOrdinal,
                GetDateTime(reader, collectionDateOrdinal, DateTime.Now));
            var createdAt = GetDateTime(reader, createdDateOrdinal, resultDate.AddMinutes(-60));
            var startedAt = GetDateTime(reader, updatedDateOrdinal, createdAt);
            var testName = GetString(reader, testNameOrdinal, "Lab Result");

            rows.Add(new TaskQueueSourceRow
            {
                TaskId = BuildTaskId("LAB", GetGuid(reader, labResultIdOrdinal)),
                Title = BuildLabTaskTitle(testName, sourceStatus),
                Team = "Laboratory",
                Owner = GetString(reader, orderedByOrdinal, "Lab Team"),
                Patient = BuildPatientName(
                    GetString(reader, patientFirstNameOrdinal),
                    GetString(reader, patientLastNameOrdinal)),
                IdNumber = GetString(reader, idNumberOrdinal),
                SourceStatus = sourceStatus,
                DueAt = resultDate,
                StartedAt = startedAt,
                SlaMinutes = ResolveLabSla(sourceStatus)
            });
        }

        return rows;
    }

    private async Task<IReadOnlyList<TaskQueueSourceRow>> GetBillingQueueRowsAsync(
        SqlConnection connection,
        CancellationToken cancellationToken)
    {
        var rows = new List<TaskQueueSourceRow>();

        await using var command = new SqlCommand(
            @"
SELECT TOP (@MaxRows)
    I.InvoiceId,
    I.InvoiceNumber,
    I.Status,
    I.Description,
    I.InvoiceDate,
    I.DueDate,
    I.CreatedDate,
    I.UpdatedDate,
    I.CreatedBy,
    I.UpdatedBy,
    BC.Code AS BillingCode,
    P.FirstName AS PatientFirstName,
    P.LastName AS PatientLastName,
    P.ID_Number AS IdNumber
FROM Profile.Invoices I
INNER JOIN Profile.Patient P
    ON P.PatientId = I.PatientIdFK
LEFT JOIN Profile.BillingCodes BC
    ON BC.BillingCodeId = I.BillingCodeIdFK
WHERE P.IsDeleted = 0
ORDER BY COALESCE(I.DueDate, I.InvoiceDate) ASC, COALESCE(I.UpdatedDate, I.InvoiceDate) DESC;",
            connection);

        command.Parameters.Add(new SqlParameter("@MaxRows", SqlDbType.Int) { Value = MaxTaskQueueRows });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var invoiceIdOrdinal = reader.GetOrdinal("InvoiceId");
        var invoiceNumberOrdinal = reader.GetOrdinal("InvoiceNumber");
        var statusOrdinal = reader.GetOrdinal("Status");
        var descriptionOrdinal = reader.GetOrdinal("Description");
        var invoiceDateOrdinal = reader.GetOrdinal("InvoiceDate");
        var dueDateOrdinal = reader.GetOrdinal("DueDate");
        var createdDateOrdinal = reader.GetOrdinal("CreatedDate");
        var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");
        var createdByOrdinal = reader.GetOrdinal("CreatedBy");
        var updatedByOrdinal = reader.GetOrdinal("UpdatedBy");
        var billingCodeOrdinal = reader.GetOrdinal("BillingCode");
        var patientFirstNameOrdinal = reader.GetOrdinal("PatientFirstName");
        var patientLastNameOrdinal = reader.GetOrdinal("PatientLastName");
        var idNumberOrdinal = reader.GetOrdinal("IdNumber");

        while (await reader.ReadAsync(cancellationToken))
        {
            var sourceStatus = GetString(reader, statusOrdinal, "Draft");
            var invoiceNumber = GetString(reader, invoiceNumberOrdinal);
            var description = GetString(reader, descriptionOrdinal);
            var billingCode = GetString(reader, billingCodeOrdinal);
            var invoiceDate = GetDateTime(reader, invoiceDateOrdinal, DateTime.Today);
            var dueDate = GetDateTime(reader, dueDateOrdinal, invoiceDate.AddDays(7));
            var createdAt = GetDateTime(reader, createdDateOrdinal, invoiceDate);
            var startedAt = GetDateTime(reader, updatedDateOrdinal, createdAt);
            var owner = GetString(reader, updatedByOrdinal);
            if (string.IsNullOrWhiteSpace(owner))
            {
                owner = GetString(reader, createdByOrdinal, "Revenue Team");
            }

            rows.Add(new TaskQueueSourceRow
            {
                TaskId = ResolveInvoiceTaskId(invoiceNumber, GetGuid(reader, invoiceIdOrdinal)),
                Title = BuildBillingTaskTitle(invoiceNumber, billingCode, description),
                Team = "Billing",
                Owner = owner,
                Patient = BuildPatientName(
                    GetString(reader, patientFirstNameOrdinal),
                    GetString(reader, patientLastNameOrdinal)),
                IdNumber = GetString(reader, idNumberOrdinal),
                SourceStatus = sourceStatus,
                DueAt = dueDate,
                StartedAt = startedAt,
                SlaMinutes = ResolveBillingSla(sourceStatus)
            });
        }

        return rows;
    }

    private static IReadOnlyList<SchedulingProviderLoadDto> BuildProviderLoads(
        IReadOnlyList<ProviderRow> providers,
        IReadOnlyList<AppointmentRow> appointments)
    {
        var now = DateTime.Now;
        var appointmentsByProvider = appointments
            .Where(item => IsCountableAppointment(item.Status))
            .GroupBy(item => item.ProviderId)
            .ToDictionary(group => group.Key, group => group.ToList());

        var loads = new List<SchedulingProviderLoadDto>(providers.Count);

        foreach (var provider in providers)
        {
            appointmentsByProvider.TryGetValue(provider.ProviderId, out var providerAppointments);
            providerAppointments ??= [];

            var booked = providerAppointments.Count;
            var capacity = booked <= DefaultProviderCapacity
                ? DefaultProviderCapacity
                : ((booked + SlotsPerBlockPerProvider - 1) / SlotsPerBlockPerProvider) * SlotsPerBlockPerProvider;

            var room = providerAppointments
                .OrderByDescending(item => item.AppointmentDateTime)
                .Select(item => item.Location)
                .FirstOrDefault(location => !string.IsNullOrWhiteSpace(location))
                ?? "Unassigned";

            var nextSlot = providerAppointments
                .Where(item => item.AppointmentDateTime >= now)
                .OrderBy(item => item.AppointmentDateTime)
                .Select(item => item.AppointmentDateTime)
                .FirstOrDefault();

            loads.Add(new SchedulingProviderLoadDto
            {
                Provider = provider.DisplayName,
                Clinic = provider.Clinic,
                Room = room,
                Booked = booked,
                Capacity = capacity,
                NextSlot = nextSlot == default
                    ? "N/A"
                    : nextSlot.ToString("HH:mm")
            });
        }

        return loads
            .OrderBy(item => GetClinicSortOrder(item.Clinic))
            .ThenBy(item => item.Provider, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static IReadOnlyList<SchedulingResourceLoadDto> BuildResourceLoads(
        IReadOnlyList<SchedulingProviderLoadDto> providerLoads,
        IReadOnlyList<AppointmentRow> appointments)
    {
        var activeAppointments = appointments
            .Where(item => IsCountableAppointment(item.Status))
            .ToList();

        var providerCapacityByClinic = providerLoads
            .GroupBy(item => item.Clinic, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(
                group => group.Key,
                group => group.Sum(item => item.Capacity),
                StringComparer.OrdinalIgnoreCase);

        var groupedResources = activeAppointments
            .GroupBy(item => new ResourceGroupKey(item.Clinic, NormalizeResourceName(item.Location, item.Clinic)))
            .Select(group => new ResourceGroupValue(
                group.Key.Clinic,
                group.Key.ResourceName,
                group.Count(),
                Math.Max(5, (int)Math.Round(group.Average(item => item.DurationMinutes)))))
            .ToList();

        if (groupedResources.Count == 0)
        {
            return providerCapacityByClinic
                .Where(item => item.Value > 0)
                .OrderBy(item => GetClinicSortOrder(item.Key))
                .Select(item => new SchedulingResourceLoadDto
                {
                    Resource = $"{item.Key} Resource Pool",
                    Clinic = item.Key,
                    Allocated = 0,
                    Available = item.Value,
                    TurnaroundMinutes = 15
                })
                .ToList();
        }

        var resourcesByClinic = groupedResources
            .GroupBy(item => item.Clinic, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(group => group.Key, group => group.ToList(), StringComparer.OrdinalIgnoreCase);

        var output = new List<SchedulingResourceLoadDto>();

        foreach (var clinicGroup in resourcesByClinic)
        {
            var clinic = clinicGroup.Key;
            var resources = clinicGroup.Value
                .OrderBy(item => item.ResourceName, StringComparer.OrdinalIgnoreCase)
                .ToList();

            var clinicCapacity = providerCapacityByClinic.TryGetValue(clinic, out var value)
                ? value
                : 0;

            var totalAllocated = resources.Sum(item => item.Allocated);
            var remainingCapacity = Math.Max(0, clinicCapacity - totalAllocated);
            var baseAvailable = resources.Count == 0 ? 0 : remainingCapacity / resources.Count;
            var remainder = resources.Count == 0 ? 0 : remainingCapacity % resources.Count;

            for (var index = 0; index < resources.Count; index++)
            {
                var resource = resources[index];
                var available = baseAvailable + (index < remainder ? 1 : 0);

                output.Add(new SchedulingResourceLoadDto
                {
                    Resource = resource.ResourceName,
                    Clinic = resource.Clinic,
                    Allocated = resource.Allocated,
                    Available = available,
                    TurnaroundMinutes = Math.Min(120, resource.TurnaroundMinutes)
                });
            }
        }

        return output
            .OrderBy(item => GetClinicSortOrder(item.Clinic))
            .ThenBy(item => item.Resource, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static IReadOnlyList<SchedulingTimeBlockDto> BuildTimeBlocks(
        IReadOnlyList<SchedulingProviderLoadDto> providerLoads,
        IReadOnlyList<AppointmentRow> appointments)
    {
        var providerCountByClinic = providerLoads
            .GroupBy(item => item.Clinic, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(
                group => group.Key,
                group => group.Count(),
                StringComparer.OrdinalIgnoreCase);

        var activeAppointments = appointments
            .Where(item => IsCountableAppointment(item.Status))
            .ToList();

        var blockDefinitions = new[]
        {
            new { Label = "08:00", StartHour = 8 },
            new { Label = "10:00", StartHour = 10 },
            new { Label = "12:00", StartHour = 12 },
            new { Label = "14:00", StartHour = 14 },
            new { Label = "16:00", StartHour = 16 }
        };

        var blocks = new List<SchedulingTimeBlockDto>(blockDefinitions.Length);
        var day = DateTime.Today;

        foreach (var block in blockDefinitions)
        {
            var start = day.AddHours(block.StartHour);
            var end = start.AddHours(2);

            blocks.Add(new SchedulingTimeBlockDto
            {
                Time = block.Label,
                General = ResolveBlockUtilization("General", start, end, providerCountByClinic, activeAppointments),
                Cardiology = ResolveBlockUtilization("Cardiology", start, end, providerCountByClinic, activeAppointments),
                Pediatrics = ResolveBlockUtilization("Pediatrics", start, end, providerCountByClinic, activeAppointments),
                Oncology = ResolveBlockUtilization("Oncology", start, end, providerCountByClinic, activeAppointments)
            });
        }

        return blocks;
    }

    private static TaskQueueItemDto ToTaskQueueItem(TaskQueueSourceRow row, DateTime now)
    {
        var status = ResolveQueueStatus(row.SourceStatus);
        var slaMinutes = ResolveSlaMinutes(row.Team, row.SourceStatus, row.SlaMinutes);
        var elapsedMinutes = ResolveElapsedMinutes(now, row.StartedAt);
        var priority = ResolvePriority(row.SourceStatus, status, elapsedMinutes, slaMinutes);

        return new TaskQueueItemDto
        {
            TaskId = row.TaskId,
            Title = row.Title,
            Team = row.Team,
            Owner = row.Owner,
            Patient = row.Patient,
            IdNumber = row.IdNumber,
            Priority = priority,
            Status = status,
            DueAt = row.DueAt.ToString("yyyy-MM-dd HH:mm"),
            SlaMinutes = slaMinutes,
            ElapsedMinutes = elapsedMinutes
        };
    }

    private static int CalculateTaskSortScore(TaskQueueItemDto row)
    {
        var isBreached = !row.Status.Equals("Completed", StringComparison.OrdinalIgnoreCase)
            && row.ElapsedMinutes > row.SlaMinutes;
        var breachScore = isBreached ? 1000 : 0;
        var priorityScore = row.Priority.Equals("Critical", StringComparison.OrdinalIgnoreCase)
            ? 95
            : row.Priority.Equals("Urgent", StringComparison.OrdinalIgnoreCase)
                ? 65
                : 35;
        var statusScore = row.Status.Equals("Escalated", StringComparison.OrdinalIgnoreCase)
            ? 120
            : row.Status.Equals("Blocked", StringComparison.OrdinalIgnoreCase)
                ? 80
                : row.Status.Equals("In Progress", StringComparison.OrdinalIgnoreCase)
                    ? 40
                    : 0;

        var slaUsageScore = row.SlaMinutes > 0
            ? Math.Min(250, (int)Math.Round((row.ElapsedMinutes / (double)row.SlaMinutes) * 100))
            : 0;

        return breachScore + priorityScore + statusScore + slaUsageScore;
    }

    private static string ResolveQueueStatus(string sourceStatus)
    {
        var normalized = (sourceStatus ?? string.Empty).Trim().ToUpperInvariant();

        if (normalized.Contains("COMPLETE", StringComparison.Ordinal)
            || (normalized.Contains("PAID", StringComparison.Ordinal)
                && !normalized.Contains("PARTIAL", StringComparison.Ordinal)))
        {
            return "Completed";
        }

        if (normalized.Contains("ESCALAT", StringComparison.Ordinal)
            || normalized.Contains("CRITIC", StringComparison.Ordinal)
            || normalized.Contains("OVERDUE", StringComparison.Ordinal))
        {
            return "Escalated";
        }

        if (normalized.Contains("BLOCK", StringComparison.Ordinal)
            || normalized.Contains("DENIED", StringComparison.Ordinal)
            || normalized.Contains("REJECT", StringComparison.Ordinal)
            || normalized.Contains("CANCEL", StringComparison.Ordinal))
        {
            return "Blocked";
        }

        if (normalized.Contains("PROGRESS", StringComparison.Ordinal)
            || normalized.Contains("REVIEW", StringComparison.Ordinal)
            || normalized.Contains("PARTIAL", StringComparison.Ordinal))
        {
            return "In Progress";
        }

        return "Open";
    }

    private static string ResolvePriority(string sourceStatus, string queueStatus, int elapsedMinutes, int slaMinutes)
    {
        if (queueStatus.Equals("Escalated", StringComparison.OrdinalIgnoreCase))
        {
            return "Critical";
        }

        var normalized = (sourceStatus ?? string.Empty).Trim().ToUpperInvariant();
        if (normalized.Contains("CRITIC", StringComparison.Ordinal) || normalized.Contains("STAT", StringComparison.Ordinal))
        {
            return "Critical";
        }

        if (elapsedMinutes > slaMinutes && !queueStatus.Equals("Completed", StringComparison.OrdinalIgnoreCase))
        {
            return "Critical";
        }

        if (queueStatus.Equals("Blocked", StringComparison.OrdinalIgnoreCase)
            || queueStatus.Equals("In Progress", StringComparison.OrdinalIgnoreCase)
            || normalized.Contains("ABNORMAL", StringComparison.Ordinal)
            || normalized.Contains("URGENT", StringComparison.Ordinal))
        {
            return "Urgent";
        }

        if (slaMinutes > 0 && elapsedMinutes >= (int)Math.Round(slaMinutes * 0.75))
        {
            return "Urgent";
        }

        return "Routine";
    }

    private static int ResolveSlaMinutes(string team, string sourceStatus, int suggestedMinutes)
    {
        if (suggestedMinutes > 0)
        {
            return Math.Max(15, suggestedMinutes);
        }

        var normalizedTeam = (team ?? string.Empty).Trim().ToUpperInvariant();
        var normalizedStatus = (sourceStatus ?? string.Empty).Trim().ToUpperInvariant();

        var defaultSla = normalizedTeam switch
        {
            "NURSING" => 30,
            "CLINICAL" => 45,
            "LABORATORY" => 60,
            "PHARMACY" => 45,
            "BILLING" => 180,
            _ => 60
        };

        if (normalizedStatus.Contains("CRITIC", StringComparison.Ordinal))
        {
            return Math.Min(defaultSla, 20);
        }

        if (normalizedStatus.Contains("OVERDUE", StringComparison.Ordinal))
        {
            return Math.Min(defaultSla, 45);
        }

        return defaultSla;
    }

    private static int ResolveElapsedMinutes(DateTime now, DateTime startedAt)
    {
        if (startedAt == default || startedAt > now)
        {
            return 0;
        }

        return Math.Max(0, (int)Math.Round((now - startedAt).TotalMinutes));
    }

    private static string ResolveAppointmentTeam(string appointmentType, string reason, string specialization)
    {
        var combined = $"{appointmentType} {reason} {specialization}".Trim().ToUpperInvariant();

        if (combined.Contains("MEDICATION", StringComparison.Ordinal)
            || combined.Contains("PRESCRIPTION", StringComparison.Ordinal)
            || combined.Contains("REFILL", StringComparison.Ordinal)
            || combined.Contains("PHARM", StringComparison.Ordinal))
        {
            return "Pharmacy";
        }

        if (combined.Contains("TRIAGE", StringComparison.Ordinal)
            || combined.Contains("VITAL", StringComparison.Ordinal)
            || combined.Contains("FOLLOW-UP", StringComparison.Ordinal)
            || combined.Contains("FOLLOW UP", StringComparison.Ordinal)
            || combined.Contains("NURSE", StringComparison.Ordinal))
        {
            return "Nursing";
        }

        if (combined.Contains("LAB", StringComparison.Ordinal) || combined.Contains("PATHO", StringComparison.Ordinal))
        {
            return "Laboratory";
        }

        return "Clinical";
    }

    private static int ResolveLabSla(string sourceStatus)
    {
        var normalized = (sourceStatus ?? string.Empty).Trim().ToUpperInvariant();
        if (normalized.Contains("CRITIC", StringComparison.Ordinal))
        {
            return 20;
        }

        if (normalized.Contains("ABNORMAL", StringComparison.Ordinal))
        {
            return 45;
        }

        return 90;
    }

    private static int ResolveBillingSla(string sourceStatus)
    {
        var normalized = (sourceStatus ?? string.Empty).Trim().ToUpperInvariant();
        if (normalized.Contains("OVERDUE", StringComparison.Ordinal))
        {
            return 120;
        }

        if (normalized.Contains("DENIED", StringComparison.Ordinal))
        {
            return 90;
        }

        return 180;
    }

    private static string BuildAppointmentTaskTitle(string appointmentType, string reason)
    {
        var normalizedType = string.IsNullOrWhiteSpace(appointmentType)
            ? "Consultation"
            : appointmentType.Trim();
        var normalizedReason = TrimToLength(reason, 72);

        if (string.IsNullOrWhiteSpace(normalizedReason))
        {
            return $"{normalizedType} follow-up";
        }

        return $"{normalizedType}: {normalizedReason}";
    }

    private static string BuildLabTaskTitle(string testName, string status)
    {
        var normalizedName = string.IsNullOrWhiteSpace(testName)
            ? "Lab result"
            : testName.Trim();

        var normalizedStatus = (status ?? string.Empty).Trim();
        if (normalizedStatus.Length == 0)
        {
            return $"{normalizedName} review";
        }

        return $"{normalizedName} ({normalizedStatus})";
    }

    private static string BuildBillingTaskTitle(string invoiceNumber, string billingCode, string description)
    {
        var trimmedCode = billingCode.Trim();
        var baseTitle = string.IsNullOrWhiteSpace(invoiceNumber)
            ? "Claim follow-up"
            : $"Claim {invoiceNumber.Trim()}";

        if (!string.IsNullOrWhiteSpace(trimmedCode))
        {
            baseTitle = $"{baseTitle} ({trimmedCode})";
        }

        var notes = TrimToLength(description, 48);
        if (!string.IsNullOrWhiteSpace(notes))
        {
            return $"{baseTitle}: {notes}";
        }

        return baseTitle;
    }

    private static string BuildTaskId(string prefix, Guid? sourceId)
    {
        if (sourceId.HasValue)
        {
            return $"{prefix}-{sourceId.Value.ToString("N")[..8].ToUpperInvariant()}";
        }

        return $"{prefix}-UNKNOWN";
    }

    private static string ResolveInvoiceTaskId(string invoiceNumber, Guid? invoiceId)
    {
        var normalized = (invoiceNumber ?? string.Empty).Trim();
        if (normalized.Length > 0)
        {
            return normalized;
        }

        return BuildTaskId("INV", invoiceId);
    }

    private static string BuildPatientName(string firstName, string lastName)
    {
        var fullName = $"{firstName} {lastName}".Trim();
        return string.IsNullOrWhiteSpace(fullName) ? "Unknown Patient" : fullName;
    }

    private static string TrimToLength(string value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var normalized = value.Trim();
        if (normalized.Length <= maxLength)
        {
            return normalized;
        }

        return $"{normalized[..maxLength].TrimEnd()}...";
    }

    private static int ResolveBlockUtilization(
        string clinic,
        DateTime blockStart,
        DateTime blockEnd,
        IReadOnlyDictionary<string, int> providerCountByClinic,
        IReadOnlyList<AppointmentRow> appointments)
    {
        var providerCount = providerCountByClinic.TryGetValue(clinic, out var value)
            ? value
            : 0;

        if (providerCount <= 0)
        {
            return 0;
        }

        var booked = appointments.Count(item =>
            item.Clinic.Equals(clinic, StringComparison.OrdinalIgnoreCase)
            && item.AppointmentDateTime >= blockStart
            && item.AppointmentDateTime < blockEnd);

        var capacity = providerCount * SlotsPerBlockPerProvider;
        return Math.Min(100, (int)Math.Round((booked / (double)capacity) * 100));
    }

    private static bool IsCountableAppointment(string status)
    {
        var normalized = (status ?? string.Empty).Trim().ToUpperInvariant();

        return !normalized.Contains("CANCEL", StringComparison.Ordinal)
            && !normalized.Contains("NO-SHOW", StringComparison.Ordinal)
            && !normalized.Contains("NO SHOW", StringComparison.Ordinal);
    }

    private static string NormalizeClinic(string specialization)
    {
        var normalized = (specialization ?? string.Empty).Trim().ToUpperInvariant();

        if (normalized.Contains("CARDIO", StringComparison.Ordinal))
        {
            return "Cardiology";
        }

        if (normalized.Contains("PEDI", StringComparison.Ordinal))
        {
            return "Pediatrics";
        }

        if (normalized.Contains("ONCO", StringComparison.Ordinal))
        {
            return "Oncology";
        }

        return "General";
    }

    private static string NormalizeResourceName(string location, string clinic)
    {
        return string.IsNullOrWhiteSpace(location)
            ? $"{clinic} Room Pool"
            : location.Trim();
    }

    private static string BuildProviderDisplayName(string title, string firstName, string lastName)
    {
        var fullName = $"{firstName} {lastName}".Trim();
        if (string.IsNullOrWhiteSpace(fullName))
        {
            fullName = "Provider";
        }

        if (string.IsNullOrWhiteSpace(title))
        {
            return fullName;
        }

        return $"{title.Trim()} {fullName}".Trim();
    }

    private static int GetClinicSortOrder(string clinic)
    {
        for (var index = 0; index < ClinicOrder.Length; index++)
        {
            if (ClinicOrder[index].Equals(clinic, StringComparison.OrdinalIgnoreCase))
            {
                return index;
            }
        }

        return ClinicOrder.Length;
    }

    private string GetConnectionString()
    {
        var connection = _configuration.GetConnectionString(ConnectionStringKey);
        if (string.IsNullOrWhiteSpace(connection) || connection.StartsWith("__SET_CONNECTIONSTRINGS__", StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"Connection string '{ConnectionStringKey}' is not configured.");
        }

        return connection;
    }

    private static string GetString(SqlDataReader reader, int ordinal, string fallback = "")
    {
        if (reader.IsDBNull(ordinal))
        {
            return fallback;
        }

        return Convert.ToString(reader.GetValue(ordinal))?.Trim() ?? fallback;
    }

    private static DateTime GetDateTime(SqlDataReader reader, int ordinal, DateTime fallback)
    {
        if (reader.IsDBNull(ordinal))
        {
            return fallback;
        }

        return Convert.ToDateTime(reader.GetValue(ordinal));
    }

    private static Guid? GetGuid(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return null;
        }

        return reader.GetGuid(ordinal);
    }

    private static int GetInt(SqlDataReader reader, int ordinal, int fallback)
    {
        if (reader.IsDBNull(ordinal))
        {
            return fallback;
        }

        var value = Convert.ToInt32(reader.GetValue(ordinal));
        return value < 0 ? fallback : value;
    }

    private sealed class ProviderRow
    {
        public Guid ProviderId { get; init; }
        public string DisplayName { get; init; } = string.Empty;
        public string Clinic { get; init; } = "General";
    }

    private sealed class AppointmentRow
    {
        public Guid ProviderId { get; init; }
        public DateTime AppointmentDateTime { get; init; }
        public int DurationMinutes { get; init; }
        public string Status { get; init; } = string.Empty;
        public string Location { get; init; } = string.Empty;
        public string Clinic { get; init; } = "General";
    }

    private sealed class TaskQueueSourceRow
    {
        public string TaskId { get; init; } = string.Empty;
        public string Title { get; init; } = string.Empty;
        public string Team { get; init; } = "Clinical";
        public string Owner { get; init; } = "Care Team";
        public string Patient { get; init; } = "Unknown Patient";
        public string IdNumber { get; init; } = string.Empty;
        public string SourceStatus { get; init; } = "Open";
        public DateTime DueAt { get; init; } = DateTime.Now;
        public DateTime StartedAt { get; init; } = DateTime.Now;
        public int SlaMinutes { get; init; } = 60;
    }

    private sealed record ResourceGroupKey(string Clinic, string ResourceName);

    private sealed record ResourceGroupValue(
        string Clinic,
        string ResourceName,
        int Allocated,
        int TurnaroundMinutes);
}
