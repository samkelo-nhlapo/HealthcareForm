using HealthcareForm.Contracts.Patients;
using System.Data;
using System.Data.SqlClient;

namespace HealthcareForm.Services;

public sealed class PatientService : IPatientService
{
    private const string ConnectionStringKey = "HealthcareEntity";

    private readonly IConfiguration _configuration;
    private readonly ILogger<PatientService> _logger;

    public PatientService(IConfiguration configuration, ILogger<PatientService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<PatientCommandResult> AddPatientAsync(PatientCreateRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spAddPatient", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@FirstName", request.FirstName));
            command.Parameters.Add(new SqlParameter("@LastName", request.LastName));
            command.Parameters.Add(new SqlParameter("@ID_Number", request.IdNumber));
            command.Parameters.Add(new SqlParameter("@DateOfBirth", request.DateOfBirth));
            command.Parameters.Add(new SqlParameter("@GenderIDFK", request.GenderId));
            command.Parameters.Add(new SqlParameter("@PhoneNumber", request.PhoneNumber));
            command.Parameters.Add(new SqlParameter("@Email", request.Email));
            command.Parameters.Add(new SqlParameter("@Line1", request.Line1));
            command.Parameters.Add(new SqlParameter("@Line2", request.Line2));
            command.Parameters.Add(new SqlParameter("@CityIDFK", request.CityId));
            command.Parameters.Add(new SqlParameter("@ProvinceIDFK", request.ProvinceId));
            command.Parameters.Add(new SqlParameter("@CountryIDFK", request.CountryId));
            command.Parameters.Add(new SqlParameter("@MaritalStatusIDFK", request.MaritalStatusId));
            command.Parameters.Add(new SqlParameter("@EmergencyName", request.EmergencyName));
            command.Parameters.Add(new SqlParameter("@EmergencyLastName", request.EmergencyLastName));
            command.Parameters.Add(new SqlParameter("@EmergencyPhoneNumber", request.EmergencyPhoneNumber));
            command.Parameters.Add(new SqlParameter("@Relationship", request.Relationship));
            command.Parameters.Add(new SqlParameter("@EmergancyDateOfBirth", request.EmergencyDateOfBirth));
            command.Parameters.Add(new SqlParameter("@MedicationList", request.MedicationList ?? string.Empty));
            command.Parameters.Add(new SqlParameter("@ClientIdFK", SqlDbType.UniqueIdentifier) { Value = DBNull.Value });

            var messageParameter = command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250));
            messageParameter.Direction = ParameterDirection.Output;

            var patientIdParameter = command.Parameters.Add(new SqlParameter("@PatientIdOutput", SqlDbType.UniqueIdentifier));
            patientIdParameter.Direction = ParameterDirection.Output;

            var statusCodeParameter = command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int));
            statusCodeParameter.Direction = ParameterDirection.Output;

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            var statusCode = GetIntOutput(command, "@StatusCode");
            var patientId = GetGuidOutput(command, "@PatientIdOutput");

            return new PatientCommandResult
            {
                Success = string.IsNullOrWhiteSpace(message),
                Message = message,
                StatusCode = statusCode,
                PatientId = patientId
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to add patient.");
            return new PatientCommandResult
            {
                Success = false,
                Message = "Unable to add patient right now. Please try again.",
                StatusCode = null,
                PatientId = null
            };
        }
    }

    public async Task<PatientLookupResult> GetPatientAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatient", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", idNumber));

            command.Parameters.Add(new SqlParameter("@FirstName", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@LastName", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@ID_Number", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@DateOfBirth", SqlDbType.DateTime) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@GenderIDFK", SqlDbType.Int) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@PhoneNumber", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@Email", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@Line1", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@Line2", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@CityIDFK", SqlDbType.Int) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@ProvinceIDFK", SqlDbType.Int) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@CountryIDFK", SqlDbType.Int) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@MaritalStatusIDFK", SqlDbType.Int) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@MedicationList", SqlDbType.VarChar, -1) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@EmergencyName", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@EmergencyLastName", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@EmergencyPhoneNumber", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@Relationship", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@EmergancyDateOfBirth", SqlDbType.DateTime) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            if (!string.IsNullOrWhiteSpace(message))
            {
                return new PatientLookupResult
                {
                    Found = false,
                    Message = message,
                    Patient = null
                };
            }

            return new PatientLookupResult
            {
                Found = true,
                Message = string.Empty,
                Patient = new PatientRecordDto
                {
                    IdNumber = GetStringOutput(command, "@ID_Number"),
                    FirstName = GetStringOutput(command, "@FirstName"),
                    LastName = GetStringOutput(command, "@LastName"),
                    DateOfBirth = GetDateTimeOutput(command, "@DateOfBirth"),
                    GenderId = GetIntOutput(command, "@GenderIDFK") ?? 0,
                    PhoneNumber = GetStringOutput(command, "@PhoneNumber"),
                    Email = GetStringOutput(command, "@Email"),
                    Line1 = GetStringOutput(command, "@Line1"),
                    Line2 = GetStringOutput(command, "@Line2"),
                    CityId = GetIntOutput(command, "@CityIDFK") ?? 0,
                    ProvinceId = GetIntOutput(command, "@ProvinceIDFK") ?? 0,
                    CountryId = GetIntOutput(command, "@CountryIDFK") ?? 0,
                    MaritalStatusId = GetIntOutput(command, "@MaritalStatusIDFK") ?? 0,
                    MedicationList = GetStringOutput(command, "@MedicationList"),
                    EmergencyName = GetStringOutput(command, "@EmergencyName"),
                    EmergencyLastName = GetStringOutput(command, "@EmergencyLastName"),
                    EmergencyPhoneNumber = GetStringOutput(command, "@EmergencyPhoneNumber"),
                    Relationship = GetStringOutput(command, "@Relationship"),
                    EmergencyDateOfBirth = GetDateTimeOutput(command, "@EmergancyDateOfBirth")
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch patient for ID number {IdNumber}.", idNumber);
            return new PatientLookupResult
            {
                Found = false,
                Message = "Unable to retrieve patient right now. Please try again.",
                Patient = null
            };
        }
    }

    public async Task<PatientCommandResult> UpdatePatientAsync(string idNumber, PatientUpdateRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spUpdatePatient", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@FirstName", request.FirstName));
            command.Parameters.Add(new SqlParameter("@LastName", request.LastName));
            command.Parameters.Add(new SqlParameter("@ID_Number", idNumber));
            command.Parameters.Add(new SqlParameter("@DateOfBirth", request.DateOfBirth));
            command.Parameters.Add(new SqlParameter("@GenderIDFK", request.GenderId));
            command.Parameters.Add(new SqlParameter("@PhoneNumber", request.PhoneNumber));
            command.Parameters.Add(new SqlParameter("@Email", request.Email));
            command.Parameters.Add(new SqlParameter("@Line1", request.Line1));
            command.Parameters.Add(new SqlParameter("@Line2", request.Line2));
            command.Parameters.Add(new SqlParameter("@CityIDFK", request.CityId));
            command.Parameters.Add(new SqlParameter("@ProvinceIDFK", request.ProvinceId));
            command.Parameters.Add(new SqlParameter("@CountryIDFK", request.CountryId));
            command.Parameters.Add(new SqlParameter("@MaritalStatusIDFK", request.MaritalStatusId));
            command.Parameters.Add(new SqlParameter("@MedicationList", request.MedicationList ?? string.Empty));
            command.Parameters.Add(new SqlParameter("@EmergencyName", request.EmergencyName));
            command.Parameters.Add(new SqlParameter("@EmergencyLastName", request.EmergencyLastName));
            command.Parameters.Add(new SqlParameter("@EmergencyPhoneNumber", request.EmergencyPhoneNumber));
            command.Parameters.Add(new SqlParameter("@Relationship", request.Relationship));
            command.Parameters.Add(new SqlParameter("@EmergancyDateOfBirth", request.EmergencyDateOfBirth));
            command.Parameters.Add(new SqlParameter("@ClientIdFK", SqlDbType.UniqueIdentifier) { Value = DBNull.Value });

            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            return new PatientCommandResult
            {
                Success = string.IsNullOrWhiteSpace(message),
                Message = message,
                StatusCode = null,
                PatientId = null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update patient for ID number {IdNumber}.", idNumber);
            return new PatientCommandResult
            {
                Success = false,
                Message = "Unable to update patient right now. Please try again.",
                StatusCode = null,
                PatientId = null
            };
        }
    }

    public async Task<PatientCommandResult> DeletePatientAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spDeletePatient", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", idNumber));
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            return new PatientCommandResult
            {
                Success = string.IsNullOrWhiteSpace(message),
                Message = message,
                StatusCode = null,
                PatientId = null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete patient for ID number {IdNumber}.", idNumber);
            return new PatientCommandResult
            {
                Success = false,
                Message = "Unable to delete patient right now. Please try again.",
                StatusCode = null,
                PatientId = null
            };
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

    private static string GetStringOutput(SqlCommand command, string parameterName)
    {
        var value = command.Parameters[parameterName].Value;
        return value == DBNull.Value ? string.Empty : Convert.ToString(value) ?? string.Empty;
    }

    private static int? GetIntOutput(SqlCommand command, string parameterName)
    {
        var value = command.Parameters[parameterName].Value;
        return value == DBNull.Value ? null : Convert.ToInt32(value);
    }

    private static Guid? GetGuidOutput(SqlCommand command, string parameterName)
    {
        var value = command.Parameters[parameterName].Value;
        return value == DBNull.Value ? null : (Guid?)value;
    }

    private static DateTime GetDateTimeOutput(SqlCommand command, string parameterName)
    {
        var value = command.Parameters[parameterName].Value;
        return value == DBNull.Value ? DateTime.MinValue : Convert.ToDateTime(value);
    }
}
