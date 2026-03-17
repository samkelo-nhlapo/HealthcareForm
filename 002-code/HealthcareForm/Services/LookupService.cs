using HealthcareForm.Contracts.Lookups;
using System.Data;
using System.Data.SqlClient;

namespace HealthcareForm.Services;

public sealed class LookupService : ILookupService
{
    private const string ConnectionStringKey = "HealthcareEntity";

    private readonly IConfiguration _configuration;
    private readonly ILogger<LookupService> _logger;

    public LookupService(IConfiguration configuration, ILogger<LookupService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public Task<IReadOnlyList<LookupOptionDto>> GetGendersAsync(CancellationToken cancellationToken = default)
        => ExecuteLookupProcedureAsync("Profile.spGetGender", cancellationToken);

    public Task<IReadOnlyList<LookupOptionDto>> GetMaritalStatusesAsync(CancellationToken cancellationToken = default)
        => ExecuteLookupProcedureAsync("Profile.spGetMaritalStatus", cancellationToken);

    public Task<IReadOnlyList<LookupOptionDto>> GetCountriesAsync(CancellationToken cancellationToken = default)
        => ExecuteLookupProcedureAsync("Location.spGetCountries", cancellationToken);

    public Task<IReadOnlyList<LookupOptionDto>> GetProvincesAsync(CancellationToken cancellationToken = default)
        => ExecuteLookupProcedureAsync("Location.spGetProvinces", cancellationToken);

    public Task<IReadOnlyList<LookupOptionDto>> GetCitiesAsync(CancellationToken cancellationToken = default)
        => ExecuteLookupProcedureAsync("Location.spGetCities", cancellationToken);

    public Task<IReadOnlyList<AllergyLookupDto>> GetAllergiesAsync(CancellationToken cancellationToken = default)
        => ExecuteAllergyLookupAsync("Lookup.spGetAllergies", cancellationToken);

    public Task<IReadOnlyList<MedicationLookupDto>> GetMedicationsAsync(CancellationToken cancellationToken = default)
        => ExecuteMedicationLookupAsync("Lookup.spGetMedications", cancellationToken);

    private async Task<IReadOnlyList<LookupOptionDto>> ExecuteLookupProcedureAsync(string procedureName, CancellationToken cancellationToken)
    {
        try
        {
            var options = new List<LookupOptionDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand(procedureName, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            while (await reader.ReadAsync(cancellationToken))
            {
                var idText = reader.IsDBNull(0) ? string.Empty : Convert.ToString(reader[0]) ?? string.Empty;
                var name = reader.IsDBNull(1) ? string.Empty : Convert.ToString(reader[1]) ?? string.Empty;

                _ = int.TryParse(idText, out var id);
                options.Add(new LookupOptionDto
                {
                    Id = id,
                    Name = name
                });
            }

            return options;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to execute lookup stored procedure {ProcedureName}.", procedureName);
            return [];
        }
    }

    private async Task<IReadOnlyList<AllergyLookupDto>> ExecuteAllergyLookupAsync(string procedureName, CancellationToken cancellationToken)
    {
        try
        {
            var options = new List<AllergyLookupDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand(procedureName, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idOrdinal = reader.GetOrdinal("AllergyId");
            var nameOrdinal = reader.GetOrdinal("AllergyName");
            var categoryOrdinal = reader.GetOrdinal("AllergyCategory");
            var severityOrdinal = reader.GetOrdinal("Severity");
            var reactionOrdinal = reader.GetOrdinal("ReactionDescription");
            var criticalOrdinal = reader.GetOrdinal("IsCritical");
            var activeOrdinal = reader.GetOrdinal("IsActive");

            while (await reader.ReadAsync(cancellationToken))
            {
                options.Add(new AllergyLookupDto
                {
                    AllergyId = reader.IsDBNull(idOrdinal) ? Guid.Empty : reader.GetGuid(idOrdinal),
                    AllergyName = GetReaderString(reader, nameOrdinal),
                    AllergyCategory = GetReaderString(reader, categoryOrdinal),
                    Severity = GetReaderString(reader, severityOrdinal),
                    ReactionDescription = GetReaderString(reader, reactionOrdinal),
                    IsCritical = GetReaderBoolean(reader, criticalOrdinal),
                    IsActive = GetReaderBoolean(reader, activeOrdinal)
                });
            }

            return options;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to execute allergy lookup stored procedure {ProcedureName}.", procedureName);
            return [];
        }
    }

    private async Task<IReadOnlyList<MedicationLookupDto>> ExecuteMedicationLookupAsync(string procedureName, CancellationToken cancellationToken)
    {
        try
        {
            var options = new List<MedicationLookupDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand(procedureName, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idOrdinal = reader.GetOrdinal("MedicationId");
            var nameOrdinal = reader.GetOrdinal("MedicationName");
            var genericOrdinal = reader.GetOrdinal("MedicationGenericName");
            var categoryOrdinal = reader.GetOrdinal("MedicationCategory");
            var strengthOrdinal = reader.GetOrdinal("Strength");
            var unitOrdinal = reader.GetOrdinal("Unit");
            var routeOrdinal = reader.GetOrdinal("RouteOfAdministration");
            var manufacturerOrdinal = reader.GetOrdinal("ManufacturerName");
            var activeOrdinal = reader.GetOrdinal("IsActive");

            while (await reader.ReadAsync(cancellationToken))
            {
                options.Add(new MedicationLookupDto
                {
                    MedicationId = reader.IsDBNull(idOrdinal) ? Guid.Empty : reader.GetGuid(idOrdinal),
                    MedicationName = GetReaderString(reader, nameOrdinal),
                    MedicationGenericName = GetReaderString(reader, genericOrdinal),
                    MedicationCategory = GetReaderString(reader, categoryOrdinal),
                    Strength = GetReaderString(reader, strengthOrdinal),
                    Unit = GetReaderString(reader, unitOrdinal),
                    RouteOfAdministration = GetReaderString(reader, routeOrdinal),
                    ManufacturerName = GetReaderString(reader, manufacturerOrdinal),
                    IsActive = GetReaderBoolean(reader, activeOrdinal)
                });
            }

            return options;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to execute medication lookup stored procedure {ProcedureName}.", procedureName);
            return [];
        }
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

    private static string GetReaderString(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? string.Empty : Convert.ToString(reader.GetValue(ordinal)) ?? string.Empty;

    private static bool GetReaderBoolean(SqlDataReader reader, int ordinal)
        => !reader.IsDBNull(ordinal) && Convert.ToBoolean(reader.GetValue(ordinal));
}
