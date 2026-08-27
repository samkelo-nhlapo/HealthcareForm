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

    public async Task<SchedulingBookingOptionsDto> GetSchedulingBookingOptionsAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await connection.OpenAsync(cancellationToken);

            await using var command = new SqlCommand("Profile.spGetSchedulingBookingOptions", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var clientIdOrdinal = reader.GetOrdinal("ClientId");
            var clientCodeOrdinal = reader.GetOrdinal("ClientCode");
            var clientNameOrdinal = reader.GetOrdinal("ClientName");
            var clientCategoryOrdinal = reader.GetOrdinal("ClientCategory");
            var clientProviderAffiliationIdOrdinal = reader.GetOrdinal("ClientProviderAffiliationId");
            var clientStaffIdOrdinal = reader.GetOrdinal("ClientStaffId");
            var providerIdOrdinal = reader.GetOrdinal("ProviderId");
            var providerOrdinal = reader.GetOrdinal("Provider");
            var clinicOrdinal = reader.GetOrdinal("Clinic");

            var clientsById = new Dictionary<Guid, SchedulingBookingClientDto>();
            var providerKeys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var providers = new List<SchedulingBookingProviderDto>();

            while (await reader.ReadAsync(cancellationToken))
            {
                if (reader.IsDBNull(clientIdOrdinal))
                {
                    continue;
                }

                var clientId = reader.GetGuid(clientIdOrdinal);
                var clientIdText = clientId.ToString();

                if (!clientsById.ContainsKey(clientId))
                {
                    clientsById[clientId] = new SchedulingBookingClientDto
                    {
                        ClientId = clientIdText,
                        ClientCode = GetString(reader, clientCodeOrdinal),
                        ClientName = GetString(reader, clientNameOrdinal, "Client"),
                        ClientCategory = GetString(reader, clientCategoryOrdinal, "Uncategorized")
                    };
                }

                if (reader.IsDBNull(providerIdOrdinal))
                {
                    continue;
                }

                if (reader.IsDBNull(clientProviderAffiliationIdOrdinal))
                {
                    continue;
                }

                var clientProviderAffiliationId = reader.GetGuid(clientProviderAffiliationIdOrdinal).ToString();
                var clientStaffId = reader.IsDBNull(clientStaffIdOrdinal)
                    ? string.Empty
                    : reader.GetGuid(clientStaffIdOrdinal).ToString();
                var providerId = reader.GetGuid(providerIdOrdinal).ToString();
                if (!providerKeys.Add(clientProviderAffiliationId))
                {
                    continue;
                }

                providers.Add(new SchedulingBookingProviderDto
                {
                    ClientProviderAffiliationId = clientProviderAffiliationId,
                    ClientStaffId = clientStaffId,
                    ProviderId = providerId,
                    ClientId = clientIdText,
                    Provider = GetString(reader, providerOrdinal, "Provider"),
                    Clinic = NormalizeClinic(GetString(reader, clinicOrdinal))
                });
            }

            var clients = clientsById.Values
                .OrderBy(item => item.ClientName, StringComparer.OrdinalIgnoreCase)
                .ToList();

            var orderedProviders = providers
                .OrderBy(item => item.ClientId, StringComparer.OrdinalIgnoreCase)
                .ThenBy(item => item.Provider, StringComparer.OrdinalIgnoreCase)
                .ToList();

            return new SchedulingBookingOptionsDto
            {
                Clients = clients,
                Providers = orderedProviders
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load scheduling booking options.");
            throw;
        }
    }

    public async Task<SchedulingAppointmentCommandResult> AddSchedulingAppointmentAsync(
        SchedulingAppointmentCreateRequest request,
        string actor,
        CancellationToken cancellationToken = default)
    {
        var clientId = request.ClientId.GetValueOrDefault();
        var clientProviderAffiliationId = request.ClientProviderAffiliationId.GetValueOrDefault();
        var clientStaffId = request.ClientStaffId.GetValueOrDefault();
        var patientIdNumber = NormalizeText(request.PatientIdNumber);
        var appointmentType = NormalizeText(request.AppointmentType, "Consultation");
        var reason = NormalizeText(request.Reason, "General consultation");
        var location = NormalizeText(request.Location);
        var normalizedActor = NormalizeText(actor, "SYSTEM");
        var appointmentDateTime = request.AppointmentDateTime.GetValueOrDefault();

        if (!request.ClientId.HasValue || clientId == Guid.Empty)
        {
            return new SchedulingAppointmentCommandResult
            {
                Success = false,
                Message = "A valid clinic or hospital is required.",
                StatusCode = 1,
                AppointmentId = null
            };
        }

        if (!IsValidPatientIdNumber(patientIdNumber))
        {
            return new SchedulingAppointmentCommandResult
            {
                Success = false,
                Message = "Patient ID number must be exactly 13 digits.",
                StatusCode = 1,
                AppointmentId = null
            };
        }

        var hasClientProviderAffiliation = request.ClientProviderAffiliationId.HasValue && clientProviderAffiliationId != Guid.Empty;
        var hasClientStaff = request.ClientStaffId.HasValue && clientStaffId != Guid.Empty;

        if (!hasClientProviderAffiliation && !hasClientStaff)
        {
            return new SchedulingAppointmentCommandResult
            {
                Success = false,
                Message = "A valid provider affiliation is required.",
                StatusCode = 1,
                AppointmentId = null
            };
        }

        if (!request.AppointmentDateTime.HasValue || appointmentDateTime == default)
        {
            return new SchedulingAppointmentCommandResult
            {
                Success = false,
                Message = "A valid appointment date and time is required.",
                StatusCode = 1,
                AppointmentId = null
            };
        }

        if (request.DurationMinutes < 5 || request.DurationMinutes > 480)
        {
            return new SchedulingAppointmentCommandResult
            {
                Success = false,
                Message = "DurationMinutes must be between 5 and 480.",
                StatusCode = 1,
                AppointmentId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spAddAppointment", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientIdFK", SqlDbType.UniqueIdentifier) { Value = clientId });
            command.Parameters.Add(new SqlParameter("@PatientIdNumber", SqlDbType.VarChar, 250) { Value = patientIdNumber });
            command.Parameters.Add(new SqlParameter("@ClientStaffIdFK", SqlDbType.UniqueIdentifier)
            {
                Value = hasClientStaff ? clientStaffId : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@ClientProviderAffiliationIdFK", SqlDbType.UniqueIdentifier)
            {
                Value = hasClientProviderAffiliation ? clientProviderAffiliationId : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@AppointmentDateTime", SqlDbType.DateTime) { Value = appointmentDateTime });
            command.Parameters.Add(new SqlParameter("@DurationMinutes", SqlDbType.Int) { Value = request.DurationMinutes });
            command.Parameters.Add(new SqlParameter("@AppointmentType", SqlDbType.VarChar, 100) { Value = appointmentType });
            command.Parameters.Add(new SqlParameter("@Reason", SqlDbType.VarChar, -1) { Value = ToDbString(reason) });
            command.Parameters.Add(new SqlParameter("@Location", SqlDbType.VarChar, 250) { Value = ToDbString(location) });
            command.Parameters.Add(new SqlParameter("@CreatedBy", SqlDbType.VarChar, 250) { Value = normalizedActor });
            command.Parameters.Add(new SqlParameter("@AppointmentIdOutput", SqlDbType.UniqueIdentifier)
            {
                Direction = ParameterDirection.Output
            });
            command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            });
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            var statusCode = GetNullableIntOutput(command, "@StatusCode");
            var appointmentId = GetGuidOutput(command, "@AppointmentIdOutput");
            var success = string.IsNullOrWhiteSpace(message) && statusCode == 0 && appointmentId.HasValue;

            return new SchedulingAppointmentCommandResult
            {
                Success = success,
                Message = success ? "Appointment scheduled successfully." : message,
                StatusCode = statusCode,
                AppointmentId = appointmentId
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to add scheduling appointment for patient {PatientIdNumber}.", patientIdNumber);
            return new SchedulingAppointmentCommandResult
            {
                Success = false,
                Message = "Unable to add appointment right now. Please try again.",
                StatusCode = null,
                AppointmentId = null
            };
        }
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
            throw;
        }
    }

    public async Task<TaskQueueSnapshotDto> GetTaskQueueSnapshotAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await connection.OpenAsync(cancellationToken);

            var sourceRows = await GetTaskQueueSourceRowsAsync(connection, cancellationToken);

            var now = DateTime.Now;
            var tasks = sourceRows
                .Select(row => new
                {
                    row,
                    item = ToTaskQueueItem(row, now)
                })
                // Keep the queue biased toward SLA pressure first, then use due
                // time as a stable tiebreaker for tasks with similar urgency.
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

        await using var command = new SqlCommand("Profile.spGetSchedulingProviders", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var clientProviderAffiliationIdOrdinal = reader.GetOrdinal("ClientProviderAffiliationId");
        var clientStaffIdOrdinal = reader.GetOrdinal("ClientStaffId");
        var clientIdOrdinal = reader.GetOrdinal("ClientId");
        var clientNameOrdinal = reader.GetOrdinal("ClientName");
        var providerIdOrdinal = reader.GetOrdinal("ProviderId");
        var firstNameOrdinal = reader.GetOrdinal("FirstName");
        var lastNameOrdinal = reader.GetOrdinal("LastName");
        var titleOrdinal = reader.GetOrdinal("Title");
        var specializationOrdinal = reader.GetOrdinal("Specialization");

        while (await reader.ReadAsync(cancellationToken))
        {
            if (reader.IsDBNull(clientProviderAffiliationIdOrdinal))
            {
                continue;
            }

            var clientProviderAffiliationId = reader.GetGuid(clientProviderAffiliationIdOrdinal);
            var clientStaffId = reader.IsDBNull(clientStaffIdOrdinal)
                ? (Guid?)null
                : reader.GetGuid(clientStaffIdOrdinal);
            var clientId = reader.GetGuid(clientIdOrdinal);
            var clientName = GetString(reader, clientNameOrdinal, "Client");
            var providerId = reader.GetGuid(providerIdOrdinal);
            var firstName = GetString(reader, firstNameOrdinal);
            var lastName = GetString(reader, lastNameOrdinal);
            var title = GetString(reader, titleOrdinal);
            var specialization = GetString(reader, specializationOrdinal);

            var displayName = BuildProviderDisplayName(title, firstName, lastName);

            providers.Add(new ProviderRow
            {
                ClientProviderAffiliationId = clientProviderAffiliationId,
                ProviderId = providerId,
                ClientStaffId = clientStaffId,
                ClientId = clientId,
                ClientName = clientName,
                DisplayName = displayName,
                Clinic = NormalizeClinic(specialization)
            });
        }

        return providers;
    }

    private async Task<IReadOnlyList<AppointmentRow>> GetAppointmentsAsync(SqlConnection connection, CancellationToken cancellationToken)
    {
        var appointments = new List<AppointmentRow>();
        // Scheduling is intentionally a same-day view so the dashboard reflects
        // what operators need to react to right now.
        var windowStart = DateTime.Today;
        var windowEnd = windowStart.AddDays(1);

        await using var command = new SqlCommand("Profile.spGetSchedulingAppointments", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.Add(new SqlParameter("@WindowStart", SqlDbType.DateTime) { Value = windowStart });
        command.Parameters.Add(new SqlParameter("@WindowEnd", SqlDbType.DateTime) { Value = windowEnd });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var clientProviderAffiliationIdOrdinal = reader.GetOrdinal("ClientProviderAffiliationIdFK");
        var clientStaffIdOrdinal = reader.GetOrdinal("ClientStaffIdFK");
        var appointmentDateTimeOrdinal = reader.GetOrdinal("AppointmentDateTime");
        var durationMinutesOrdinal = reader.GetOrdinal("DurationMinutes");
        var statusOrdinal = reader.GetOrdinal("Status");
        var locationOrdinal = reader.GetOrdinal("Location");
        var specializationOrdinal = reader.GetOrdinal("Specialization");

        while (await reader.ReadAsync(cancellationToken))
        {
            if (reader.IsDBNull(clientProviderAffiliationIdOrdinal))
            {
                continue;
            }

            var duration = reader.IsDBNull(durationMinutesOrdinal)
                ? 30
                : Math.Max(5, Convert.ToInt32(reader.GetValue(durationMinutesOrdinal)));

            appointments.Add(new AppointmentRow
            {
                ClientProviderAffiliationId = reader.GetGuid(clientProviderAffiliationIdOrdinal),
                ClientStaffId = reader.IsDBNull(clientStaffIdOrdinal)
                    ? (Guid?)null
                    : reader.GetGuid(clientStaffIdOrdinal),
                AppointmentDateTime = Convert.ToDateTime(reader.GetValue(appointmentDateTimeOrdinal)),
                DurationMinutes = duration,
                Status = GetString(reader, statusOrdinal),
                Location = GetString(reader, locationOrdinal),
                Clinic = NormalizeClinic(GetString(reader, specializationOrdinal))
            });
        }

        return appointments;
    }

    private async Task<IReadOnlyList<TaskQueueSourceRow>> GetTaskQueueSourceRowsAsync(
        SqlConnection connection,
        CancellationToken cancellationToken)
    {
        var rows = new List<TaskQueueSourceRow>();

        await using var command = new SqlCommand("Profile.spGetTaskQueueSourceRows", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.Add(new SqlParameter("@MaxRows", SqlDbType.Int) { Value = MaxTaskQueueRows });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var taskIdOrdinal = reader.GetOrdinal("TaskId");
        var titleOrdinal = reader.GetOrdinal("Title");
        var teamOrdinal = reader.GetOrdinal("Team");
        var ownerOrdinal = reader.GetOrdinal("Owner");
        var patientOrdinal = reader.GetOrdinal("Patient");
        var idNumberOrdinal = reader.GetOrdinal("IdNumber");
        var sourceStatusOrdinal = reader.GetOrdinal("SourceStatus");
        var dueAtOrdinal = reader.GetOrdinal("DueAt");
        var startedAtOrdinal = reader.GetOrdinal("StartedAt");
        var slaMinutesOrdinal = reader.GetOrdinal("SlaMinutes");

        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new TaskQueueSourceRow
            {
                TaskId = GetString(reader, taskIdOrdinal, "TASK-UNKNOWN"),
                Title = GetString(reader, titleOrdinal, "Untitled Task"),
                Team = GetString(reader, teamOrdinal, "Clinical"),
                Owner = GetString(reader, ownerOrdinal, "Care Team"),
                Patient = GetString(reader, patientOrdinal, "Unknown Patient"),
                IdNumber = GetString(reader, idNumberOrdinal),
                SourceStatus = GetString(reader, sourceStatusOrdinal, "Open"),
                DueAt = GetDateTime(reader, dueAtOrdinal, DateTime.Now),
                StartedAt = GetDateTime(reader, startedAtOrdinal, DateTime.Now),
                SlaMinutes = Math.Max(15, GetInt(reader, slaMinutesOrdinal, 60))
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
            .GroupBy(item => item.ClientProviderAffiliationId)
            .ToDictionary(group => group.Key, group => group.ToList());

        var loads = new List<SchedulingProviderLoadDto>(providers.Count);

        foreach (var provider in providers)
        {
            appointmentsByProvider.TryGetValue(provider.ClientProviderAffiliationId, out var providerAppointments);
            providerAppointments ??= [];

            var booked = providerAppointments.Count;
            // Once the baseline capacity is exceeded, grow in small blocks so the
            // dashboard still communicates usable headroom instead of a hard cap.
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
                ClientProviderAffiliationId = provider.ClientProviderAffiliationId.ToString(),
                ClientStaffId = provider.ClientStaffId?.ToString() ?? string.Empty,
                ClientId = provider.ClientId.ToString(),
                ClientName = provider.ClientName,
                ProviderId = provider.ProviderId.ToString(),
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

    private static bool IsValidPatientIdNumber(string value)
        => value.Length == 13 && value.All(char.IsDigit);

    private static string NormalizeText(string? value, string fallback = "")
    {
        var normalized = (value ?? string.Empty).Trim();
        return normalized.Length == 0 ? fallback : normalized;
    }

    private static object ToDbString(string? value)
    {
        return string.IsNullOrWhiteSpace(value)
            ? DBNull.Value
            : value.Trim();
    }

    private static string GetStringOutput(SqlCommand command, string parameterName)
    {
        var value = command.Parameters[parameterName].Value;
        return value == DBNull.Value ? string.Empty : Convert.ToString(value)?.Trim() ?? string.Empty;
    }

    private static int? GetNullableIntOutput(SqlCommand command, string parameterName)
    {
        var value = command.Parameters[parameterName].Value;
        if (value == DBNull.Value)
        {
            return null;
        }

        return Convert.ToInt32(value);
    }

    private static Guid? GetGuidOutput(SqlCommand command, string parameterName)
    {
        var value = command.Parameters[parameterName].Value;
        if (value == DBNull.Value)
        {
            return null;
        }

        return value is Guid guid ? guid : Guid.TryParse(Convert.ToString(value), out var parsed) ? parsed : null;
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
        public Guid ClientProviderAffiliationId { get; init; }
        public Guid? ClientStaffId { get; init; }
        public Guid ClientId { get; init; }
        public string ClientName { get; init; } = string.Empty;
        public Guid ProviderId { get; init; }
        public string DisplayName { get; init; } = string.Empty;
        public string Clinic { get; init; } = "General";
    }

    private sealed class AppointmentRow
    {
        public Guid ClientProviderAffiliationId { get; init; }
        public Guid? ClientStaffId { get; init; }
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
