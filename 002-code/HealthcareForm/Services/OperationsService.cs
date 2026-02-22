using HealthcareForm.Contracts.Operations;
using System.Data;
using System.Data.SqlClient;

namespace HealthcareForm.Services;

public sealed class OperationsService : IOperationsService
{
    private const string ConnectionStringKey = "HealthcareEntity";
    private const int DefaultProviderCapacity = 12;
    private const int SlotsPerBlockPerProvider = 4;

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

    private static string GetString(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return string.Empty;
        }

        return Convert.ToString(reader.GetValue(ordinal))?.Trim() ?? string.Empty;
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

    private sealed record ResourceGroupKey(string Clinic, string ResourceName);

    private sealed record ResourceGroupValue(
        string Clinic,
        string ResourceName,
        int Allocated,
        int TurnaroundMinutes);
}
