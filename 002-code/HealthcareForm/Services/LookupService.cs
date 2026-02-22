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

    private string GetConnectionString()
    {
        var connection = _configuration.GetConnectionString(ConnectionStringKey);
        if (string.IsNullOrWhiteSpace(connection) || connection.StartsWith("__SET_CONNECTIONSTRINGS__", StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"Connection string '{ConnectionStringKey}' is not configured.");
        }

        return connection;
    }
}
