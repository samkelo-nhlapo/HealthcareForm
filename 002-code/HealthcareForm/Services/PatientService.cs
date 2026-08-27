using HealthcareForm.Contracts.Patients;
using System.Data;
using System.Data.SqlClient;

namespace HealthcareForm.Services;

public sealed class PatientService : IPatientService
{
    private const string ConnectionStringKey = "HealthcareEntity";
    private const int DefaultPageSize = 25;
    private const int MaxPageSize = 200;
    private const int MaxWorklistRows = 250;

    private readonly IConfiguration _configuration;
    private readonly ILogger<PatientService> _logger;

    public PatientService(IConfiguration configuration, ILogger<PatientService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<PatientCommandResult> AddPatientAsync(PatientCreateRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedRequest = NormalizeRequest(request);
        var clientSelection = BuildClientSelection(normalizedRequest.PrimaryClientId, normalizedRequest.SecondaryClientIds);
        if (!clientSelection.IsValid)
        {
            return new PatientCommandResult
            {
                Success = false,
                Message = "Please select a primary clinic or hospital for the patient.",
                StatusCode = 1,
                PatientId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spAddPatient", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@FirstName", normalizedRequest.FirstName));
            command.Parameters.Add(new SqlParameter("@LastName", normalizedRequest.LastName));
            command.Parameters.Add(new SqlParameter("@ID_Number", normalizedRequest.IdNumber));
            command.Parameters.Add(new SqlParameter("@DateOfBirth", normalizedRequest.DateOfBirth));
            command.Parameters.Add(new SqlParameter("@GenderIDFK", normalizedRequest.GenderId));
            command.Parameters.Add(new SqlParameter("@PhoneNumber", normalizedRequest.PhoneNumber));
            command.Parameters.Add(new SqlParameter("@Email", normalizedRequest.Email));
            command.Parameters.Add(new SqlParameter("@Line1", normalizedRequest.Line1));
            command.Parameters.Add(new SqlParameter("@Line2", normalizedRequest.Line2));
            command.Parameters.Add(new SqlParameter("@CityIDFK", normalizedRequest.CityId));
            command.Parameters.Add(new SqlParameter("@ProvinceIDFK", normalizedRequest.ProvinceId));
            command.Parameters.Add(new SqlParameter("@CountryIDFK", normalizedRequest.CountryId));
            command.Parameters.Add(new SqlParameter("@MaritalStatusIDFK", normalizedRequest.MaritalStatusId));
            command.Parameters.Add(new SqlParameter("@EmergencyName", normalizedRequest.EmergencyName));
            command.Parameters.Add(new SqlParameter("@EmergencyLastName", normalizedRequest.EmergencyLastName));
            command.Parameters.Add(new SqlParameter("@EmergencyPhoneNumber", normalizedRequest.EmergencyPhoneNumber));
            command.Parameters.Add(new SqlParameter("@Relationship", normalizedRequest.Relationship));
            command.Parameters.Add(new SqlParameter("@EmergancyDateOfBirth", normalizedRequest.EmergencyDateOfBirth));
            command.Parameters.Add(new SqlParameter("@MedicationList", normalizedRequest.MedicationList));
            command.Parameters.Add(new SqlParameter("@ClientIdFK", SqlDbType.UniqueIdentifier)
            {
                Value = clientSelection.PrimaryClientId
            });
            command.Parameters.Add(new SqlParameter("@AdditionalClientIds", SqlDbType.VarChar, -1)
            {
                Value = ToDbString(clientSelection.AdditionalClientIdsCsv)
            });

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

    public async Task<IReadOnlyList<PatientClientLookupItemDto>> GetClientLookupAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var clients = new List<PatientClientLookupItemDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand(
                """
                SELECT
                    C.ClientId,
                    C.ClientCode,
                    C.FirstName,
                    C.LastName,
                    ISNULL(CCC.CategoryName, '') AS ClientClinicCategoryName
                FROM Profile.Clients C
                LEFT JOIN Profile.ClientClinicCategories CCC
                    ON CCC.ClientClinicCategoryId = C.ClientClinicCategoryIDFK
                WHERE C.IsDeleted = 0
                  AND C.IsActive = 1
                ORDER BY C.FirstName ASC, C.LastName ASC, C.ClientCode ASC;
                """,
                connection);

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var clientIdOrdinal = reader.GetOrdinal("ClientId");
            var clientCodeOrdinal = reader.GetOrdinal("ClientCode");
            var firstNameOrdinal = reader.GetOrdinal("FirstName");
            var lastNameOrdinal = reader.GetOrdinal("LastName");
            var categoryNameOrdinal = reader.GetOrdinal("ClientClinicCategoryName");

            while (await reader.ReadAsync(cancellationToken))
            {
                var clientCode = GetReaderString(reader, clientCodeOrdinal);
                var firstName = GetReaderString(reader, firstNameOrdinal);
                var lastName = GetReaderString(reader, lastNameOrdinal);

                clients.Add(new PatientClientLookupItemDto
                {
                    ClientId = GetReaderGuid(reader, clientIdOrdinal),
                    ClientCode = clientCode,
                    ClientName = BuildClientDisplayName(firstName, lastName, clientCode),
                    ClientClinicCategoryName = GetReaderString(reader, categoryNameOrdinal)
                });
            }

            return clients;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load active client lookup values.");
            return [];
        }
    }

    public async Task<IReadOnlyList<PatientWorklistItemDto>> GetWorklistAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientWorklistSourceRows", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@MaxRows", SqlDbType.Int) { Value = MaxWorklistRows });

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idNumberOrdinal = reader.GetOrdinal("IdNumber");
            var firstNameOrdinal = reader.GetOrdinal("FirstName");
            var lastNameOrdinal = reader.GetOrdinal("LastName");
            var dateOfBirthOrdinal = reader.GetOrdinal("DateOfBirth");
            var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");
            var appointmentStatusOrdinal = reader.GetOrdinal("AppointmentStatus");
            var specializationOrdinal = reader.GetOrdinal("Specialization");
            var activeConditionsOrdinal = reader.GetOrdinal("ActiveConditions");
            var chronicConditionsOrdinal = reader.GetOrdinal("ChronicConditions");

            var rows = new List<PatientWorklistItemDto>();

            while (await reader.ReadAsync(cancellationToken))
            {
                var dateOfBirth = reader.IsDBNull(dateOfBirthOrdinal)
                    ? (DateTime?)null
                    : Convert.ToDateTime(reader.GetValue(dateOfBirthOrdinal));

                var updatedDate = reader.IsDBNull(updatedDateOrdinal)
                    ? DateTime.UtcNow
                    : Convert.ToDateTime(reader.GetValue(updatedDateOrdinal));

                var appointmentStatus = reader.IsDBNull(appointmentStatusOrdinal)
                    ? string.Empty
                    : Convert.ToString(reader.GetValue(appointmentStatusOrdinal)) ?? string.Empty;

                var specialization = reader.IsDBNull(specializationOrdinal)
                    ? string.Empty
                    : Convert.ToString(reader.GetValue(specializationOrdinal)) ?? string.Empty;

                var activeConditions = reader.IsDBNull(activeConditionsOrdinal)
                    ? 0
                    : Convert.ToInt32(reader.GetValue(activeConditionsOrdinal));

                var chronicConditions = reader.IsDBNull(chronicConditionsOrdinal)
                    ? 0
                    : Convert.ToInt32(reader.GetValue(chronicConditionsOrdinal));

                var firstName = reader.IsDBNull(firstNameOrdinal)
                    ? string.Empty
                    : Convert.ToString(reader.GetValue(firstNameOrdinal)) ?? string.Empty;

                var lastName = reader.IsDBNull(lastNameOrdinal)
                    ? string.Empty
                    : Convert.ToString(reader.GetValue(lastNameOrdinal)) ?? string.Empty;

                var patient = $"{firstName} {lastName}".Trim();
                if (string.IsNullOrWhiteSpace(patient))
                {
                    patient = "Unknown Patient";
                }

                // Normalize sparse source data here so the worklist UI can stay
                // focused on rendering instead of reconstructing fallbacks.
                rows.Add(new PatientWorklistItemDto
                {
                    IdNumber = reader.IsDBNull(idNumberOrdinal)
                        ? string.Empty
                        : Convert.ToString(reader.GetValue(idNumberOrdinal)) ?? string.Empty,
                    Patient = patient,
                    Status = ResolveWorklistStatus(appointmentStatus),
                    Clinic = ResolveWorklistClinic(specialization),
                    Risk = ResolveWorklistRisk(dateOfBirth, activeConditions, chronicConditions),
                    UpdatedOn = updatedDate.ToString("yyyy-MM-dd")
                });
            }

            return rows;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to build patient worklist snapshot.");
            return [];
        }
    }

    public async Task<PatientDirectorySnapshotDto> GetDirectoryAsync(PatientDirectoryQueryDto query, CancellationToken cancellationToken = default)
    {
        try
        {
            var (pageNumber, pageSize) = NormalizePage(query.PageNumber, query.PageSize);
            var patients = new List<PatientDirectoryItemDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spListPatients", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@SearchTerm", SqlDbType.VarChar, 250)
            {
                Value = (query.SearchTerm ?? string.Empty).Trim()
            });
            command.Parameters.Add(new SqlParameter("@GenderIDFK", SqlDbType.Int)
            {
                Value = query.GenderId.GetValueOrDefault() > 0 ? query.GenderId!.Value : 0
            });
            command.Parameters.Add(new SqlParameter("@MaritalStatusIDFK", SqlDbType.Int)
            {
                Value = query.MaritalStatusId.GetValueOrDefault() > 0 ? query.MaritalStatusId!.Value : 0
            });
            command.Parameters.Add(new SqlParameter("@CityIDFK", SqlDbType.Int) { Value = 0 });
            command.Parameters.Add(new SqlParameter("@IsDeleted", SqlDbType.Bit)
            {
                Value = query.IsDeleted.HasValue ? query.IsDeleted.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@PageNumber", SqlDbType.Int) { Value = pageNumber });
            command.Parameters.Add(new SqlParameter("@PageSize", SqlDbType.Int) { Value = pageSize });

            var totalRecordsParameter = new SqlParameter("@TotalRecords", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };
            var messageParameter = new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            };

            command.Parameters.Add(totalRecordsParameter);
            command.Parameters.Add(messageParameter);
            command.Parameters.Add(new SqlParameter("@ClientIdFK", SqlDbType.UniqueIdentifier)
            {
                Value = query.ClientId.HasValue ? query.ClientId.Value : DBNull.Value
            });

            await connection.OpenAsync(cancellationToken);
            await using (var reader = await command.ExecuteReaderAsync(cancellationToken))
            {
                var patientIdOrdinal = reader.GetOrdinal("PatientId");
                var firstNameOrdinal = reader.GetOrdinal("FirstName");
                var lastNameOrdinal = reader.GetOrdinal("LastName");
                var idNumberOrdinal = reader.GetOrdinal("ID_Number");
                var dateOfBirthOrdinal = reader.GetOrdinal("DateOfBirth");
                var genderIdOrdinal = reader.GetOrdinal("GenderIDFK");
                var maritalStatusIdOrdinal = reader.GetOrdinal("MaritalStatusIDFK");
                var clientIdOrdinal = reader.GetOrdinal("ClientIdFK");
                var medicationListOrdinal = reader.GetOrdinal("MedicationList");
                var isDeletedOrdinal = reader.GetOrdinal("IsDeleted");
                var emailOrdinal = reader.GetOrdinal("Email");
                var phoneOrdinal = reader.GetOrdinal("PhoneNumber");
                var line1Ordinal = reader.GetOrdinal("Line1");
                var line2Ordinal = reader.GetOrdinal("Line2");
                var cityIdOrdinal = reader.GetOrdinal("CityId");
                var cityNameOrdinal = reader.GetOrdinal("CityName");
                var provinceIdOrdinal = reader.GetOrdinal("ProvinceId");
                var provinceNameOrdinal = reader.GetOrdinal("ProvinceName");
                var countryIdOrdinal = reader.GetOrdinal("CountryId");
                var countryNameOrdinal = reader.GetOrdinal("CountryName");
                var createdDateOrdinal = reader.GetOrdinal("CreatedDate");
                var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");

                while (await reader.ReadAsync(cancellationToken))
                {
                    patients.Add(new PatientDirectoryItemDto
                    {
                        PatientId = GetReaderGuid(reader, patientIdOrdinal),
                        FirstName = GetReaderString(reader, firstNameOrdinal),
                        LastName = GetReaderString(reader, lastNameOrdinal),
                        IdNumber = GetReaderString(reader, idNumberOrdinal),
                        DateOfBirth = GetReaderNullableDateTime(reader, dateOfBirthOrdinal),
                        GenderId = GetReaderInt(reader, genderIdOrdinal),
                        MaritalStatusId = GetReaderInt(reader, maritalStatusIdOrdinal),
                        ClientId = GetReaderNullableGuid(reader, clientIdOrdinal),
                        MedicationList = GetReaderString(reader, medicationListOrdinal),
                        IsDeleted = GetReaderBoolean(reader, isDeletedOrdinal),
                        Email = GetReaderString(reader, emailOrdinal),
                        PhoneNumber = GetReaderString(reader, phoneOrdinal),
                        Line1 = GetReaderString(reader, line1Ordinal),
                        Line2 = GetReaderString(reader, line2Ordinal),
                        CityId = GetReaderInt(reader, cityIdOrdinal),
                        CityName = GetReaderString(reader, cityNameOrdinal),
                        ProvinceId = GetReaderInt(reader, provinceIdOrdinal),
                        ProvinceName = GetReaderString(reader, provinceNameOrdinal),
                        CountryId = GetReaderInt(reader, countryIdOrdinal),
                        CountryName = GetReaderString(reader, countryNameOrdinal),
                        CreatedDate = GetReaderDateTime(reader, createdDateOrdinal),
                        UpdatedDate = GetReaderDateTime(reader, updatedDateOrdinal)
                    });
                }
            }

            await PopulateClientSummariesAsync(patients, cancellationToken);
            await PopulateClientAssignmentsAsync(patients, cancellationToken);

            var totalRecords = GetIntOutput(command, "@TotalRecords") ?? 0;
            var message = GetStringOutput(command, "@Message");
            if (!string.IsNullOrWhiteSpace(message))
            {
                _logger.LogWarning("Patient directory returned message: {Message}", message);
            }

            return new PatientDirectorySnapshotDto
            {
                Patients = patients,
                TotalRecords = totalRecords
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to build patient directory snapshot.");
            return new PatientDirectorySnapshotDto();
        }
    }

    public async Task<PatientLookupResult> GetPatientAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        var normalizedIdNumber = PatientRequestRules.NormalizeText(idNumber);

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatient", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", normalizedIdNumber));

            // This stored procedure returns the patient record through output
            // parameters, so the null-safe materialization happens after execution.
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
            command.Parameters.Add(new SqlParameter("@ClientIdFK", SqlDbType.UniqueIdentifier) { Direction = ParameterDirection.Output });

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

            var clientId = GetGuidOutput(command, "@ClientIdFK");
            var patientId = await GetPatientIdByIdNumberAsync(normalizedIdNumber, false, cancellationToken);
            var clientAssignments = patientId.HasValue
                ? await GetPatientClientAssignmentsAsync(patientId.Value, cancellationToken)
                : [];

            var primaryAssignment = clientAssignments.FirstOrDefault((assignment) => assignment.IsPrimary)
                ?? clientAssignments.FirstOrDefault();
            PatientClientLookupItemDto? clientSummary = null;
            if (primaryAssignment is null && clientId.HasValue)
            {
                var clientLookup = await GetClientLookupMapAsync([clientId.Value], cancellationToken);
                clientLookup.TryGetValue(clientId.Value, out clientSummary);
            }

            return new PatientLookupResult
            {
                Found = true,
                Message = string.Empty,
                Patient = new PatientRecordDto
                {
                    ClientId = primaryAssignment?.ClientId ?? clientId,
                    ClientCode = primaryAssignment?.ClientCode ?? clientSummary?.ClientCode ?? string.Empty,
                    ClientName = primaryAssignment?.ClientName ?? clientSummary?.ClientName ?? string.Empty,
                    ClientClinicCategoryName = primaryAssignment?.ClientClinicCategoryName ?? clientSummary?.ClientClinicCategoryName ?? string.Empty,
                    Clients = clientAssignments,
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
            _logger.LogError(ex, "Failed to fetch patient for ID number {IdNumber}.", normalizedIdNumber);
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
        var normalizedIdNumber = PatientRequestRules.NormalizeText(idNumber);
        var normalizedRequest = NormalizeRequest(request);
        var clientSelection = BuildClientSelection(normalizedRequest.PrimaryClientId, normalizedRequest.SecondaryClientIds);
        if (!clientSelection.IsValid)
        {
            return new PatientCommandResult
            {
                Success = false,
                Message = "Please select a primary clinic or hospital for the patient.",
                StatusCode = 1,
                PatientId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spUpdatePatient", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@FirstName", normalizedRequest.FirstName));
            command.Parameters.Add(new SqlParameter("@LastName", normalizedRequest.LastName));
            command.Parameters.Add(new SqlParameter("@ID_Number", normalizedIdNumber));
            command.Parameters.Add(new SqlParameter("@DateOfBirth", normalizedRequest.DateOfBirth));
            command.Parameters.Add(new SqlParameter("@GenderIDFK", normalizedRequest.GenderId));
            command.Parameters.Add(new SqlParameter("@PhoneNumber", normalizedRequest.PhoneNumber));
            command.Parameters.Add(new SqlParameter("@Email", normalizedRequest.Email));
            command.Parameters.Add(new SqlParameter("@Line1", normalizedRequest.Line1));
            command.Parameters.Add(new SqlParameter("@Line2", normalizedRequest.Line2));
            command.Parameters.Add(new SqlParameter("@CityIDFK", normalizedRequest.CityId));
            command.Parameters.Add(new SqlParameter("@ProvinceIDFK", normalizedRequest.ProvinceId));
            command.Parameters.Add(new SqlParameter("@CountryIDFK", normalizedRequest.CountryId));
            command.Parameters.Add(new SqlParameter("@MaritalStatusIDFK", normalizedRequest.MaritalStatusId));
            command.Parameters.Add(new SqlParameter("@MedicationList", normalizedRequest.MedicationList));
            command.Parameters.Add(new SqlParameter("@EmergencyName", normalizedRequest.EmergencyName));
            command.Parameters.Add(new SqlParameter("@EmergencyLastName", normalizedRequest.EmergencyLastName));
            command.Parameters.Add(new SqlParameter("@EmergencyPhoneNumber", normalizedRequest.EmergencyPhoneNumber));
            command.Parameters.Add(new SqlParameter("@Relationship", normalizedRequest.Relationship));
            command.Parameters.Add(new SqlParameter("@EmergancyDateOfBirth", normalizedRequest.EmergencyDateOfBirth));
            command.Parameters.Add(new SqlParameter("@ClientIdFK", SqlDbType.UniqueIdentifier)
            {
                Value = clientSelection.PrimaryClientId
            });
            command.Parameters.Add(new SqlParameter("@AdditionalClientIds", SqlDbType.VarChar, -1)
            {
                Value = ToDbString(clientSelection.AdditionalClientIdsCsv)
            });

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
            _logger.LogError(ex, "Failed to update patient for ID number {IdNumber}.", normalizedIdNumber);
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
        var normalizedIdNumber = PatientRequestRules.NormalizeText(idNumber);

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spDeletePatient", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", normalizedIdNumber));
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
            _logger.LogError(ex, "Failed to delete patient for ID number {IdNumber}.", normalizedIdNumber);
            return new PatientCommandResult
            {
                Success = false,
                Message = "Unable to delete patient right now. Please try again.",
                StatusCode = null,
                PatientId = null
            };
        }
    }

    public async Task<PatientCommandResult> RestorePatientAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        var normalizedIdNumber = PatientRequestRules.NormalizeText(idNumber);

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spRestorePatient", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", normalizedIdNumber));
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250) { Direction = ParameterDirection.Output });
            command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int) { Direction = ParameterDirection.Output });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            var statusCode = GetIntOutput(command, "@StatusCode");

            return new PatientCommandResult
            {
                Success = statusCode == 0,
                Message = message,
                StatusCode = statusCode,
                PatientId = null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to restore patient for ID number {IdNumber}.", normalizedIdNumber);
            return new PatientCommandResult
            {
                Success = false,
                Message = "Unable to restore patient right now. Please try again.",
                StatusCode = null,
                PatientId = null
            };
        }
    }

    public async Task<IReadOnlyList<PatientAllergyDto>> GetPatientAllergiesAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        var normalizedIdNumber = PatientRequestRules.NormalizeText(idNumber);

        try
        {
            var items = new List<PatientAllergyDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientAllergies", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", normalizedIdNumber));

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idOrdinal = reader.GetOrdinal("AllergyId");
            var typeOrdinal = reader.GetOrdinal("AllergyType");
            var nameOrdinal = reader.GetOrdinal("AllergenName");
            var reactionOrdinal = reader.GetOrdinal("Reaction");
            var severityOrdinal = reader.GetOrdinal("Severity");
            var onsetOrdinal = reader.GetOrdinal("ReactionOnsetDate");
            var verifiedOrdinal = reader.GetOrdinal("VerifiedBy");
            var activeOrdinal = reader.GetOrdinal("IsActive");
            var updatedOrdinal = reader.GetOrdinal("UpdatedDate");

            while (await reader.ReadAsync(cancellationToken))
            {
                items.Add(new PatientAllergyDto
                {
                    AllergyId = GetReaderGuid(reader, idOrdinal),
                    AllergyType = GetReaderString(reader, typeOrdinal),
                    AllergenName = GetReaderString(reader, nameOrdinal),
                    Reaction = GetReaderString(reader, reactionOrdinal),
                    Severity = GetReaderString(reader, severityOrdinal),
                    ReactionOnsetDate = GetReaderNullableDateTime(reader, onsetOrdinal),
                    VerifiedBy = GetReaderString(reader, verifiedOrdinal),
                    IsActive = GetReaderBoolean(reader, activeOrdinal),
                    UpdatedDate = GetReaderNullableDateTime(reader, updatedOrdinal)
                });
            }

            return items;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load allergies for ID number {IdNumber}.", normalizedIdNumber);
            return [];
        }
    }

    public async Task<IReadOnlyList<PatientMedicationDto>> GetPatientMedicationsAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        var normalizedIdNumber = PatientRequestRules.NormalizeText(idNumber);

        try
        {
            var items = new List<PatientMedicationDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientMedications", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", normalizedIdNumber));

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idOrdinal = reader.GetOrdinal("MedicationId");
            var nameOrdinal = reader.GetOrdinal("MedicationName");
            var dosageOrdinal = reader.GetOrdinal("Dosage");
            var frequencyOrdinal = reader.GetOrdinal("Frequency");
            var routeOrdinal = reader.GetOrdinal("Route");
            var indicationOrdinal = reader.GetOrdinal("Indication");
            var prescribedOrdinal = reader.GetOrdinal("PrescribedBy");
            var prescriptionOrdinal = reader.GetOrdinal("PrescriptionDate");
            var startOrdinal = reader.GetOrdinal("StartDate");
            var endOrdinal = reader.GetOrdinal("EndDate");
            var statusOrdinal = reader.GetOrdinal("Status");
            var sideEffectsOrdinal = reader.GetOrdinal("SideEffects");
            var notesOrdinal = reader.GetOrdinal("Notes");
            var activeOrdinal = reader.GetOrdinal("IsActive");
            var updatedOrdinal = reader.GetOrdinal("UpdatedDate");

            while (await reader.ReadAsync(cancellationToken))
            {
                items.Add(new PatientMedicationDto
                {
                    MedicationId = GetReaderGuid(reader, idOrdinal),
                    MedicationName = GetReaderString(reader, nameOrdinal),
                    Dosage = GetReaderString(reader, dosageOrdinal),
                    Frequency = GetReaderString(reader, frequencyOrdinal),
                    Route = GetReaderString(reader, routeOrdinal),
                    Indication = GetReaderString(reader, indicationOrdinal),
                    PrescribedBy = GetReaderString(reader, prescribedOrdinal),
                    PrescriptionDate = GetReaderDateTime(reader, prescriptionOrdinal),
                    StartDate = GetReaderDateTime(reader, startOrdinal),
                    EndDate = GetReaderNullableDateTime(reader, endOrdinal),
                    Status = GetReaderString(reader, statusOrdinal),
                    SideEffects = GetReaderString(reader, sideEffectsOrdinal),
                    Notes = GetReaderString(reader, notesOrdinal),
                    IsActive = GetReaderBoolean(reader, activeOrdinal),
                    UpdatedDate = GetReaderNullableDateTime(reader, updatedOrdinal)
                });
            }

            return items;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load medications for ID number {IdNumber}.", normalizedIdNumber);
            return [];
        }
    }

    public async Task<PatientOrdersResultsSnapshotDto> GetPatientOrdersResultsAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        var normalizedIdNumber = PatientRequestRules.NormalizeText(idNumber);

        try
        {
            var rows = new List<PatientLabResultRow>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientLabResults", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", normalizedIdNumber));

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idOrdinal = reader.GetOrdinal("LabResultId");
            var testNameOrdinal = reader.GetOrdinal("TestName");
            var testCodeOrdinal = reader.GetOrdinal("TestCode");
            var specimenTypeOrdinal = reader.GetOrdinal("SpecimenType");
            var collectionOrdinal = reader.GetOrdinal("CollectionDate");
            var resultDateOrdinal = reader.GetOrdinal("ResultDate");
            var resultValueOrdinal = reader.GetOrdinal("ResultValue");
            var unitOrdinal = reader.GetOrdinal("Unit");
            var referenceRangeOrdinal = reader.GetOrdinal("ReferenceRange");
            var statusOrdinal = reader.GetOrdinal("Status");
            var orderedByOrdinal = reader.GetOrdinal("OrderedBy");
            var labOrdinal = reader.GetOrdinal("Lab");
            var interpretationOrdinal = reader.GetOrdinal("Interpretation");
            var notesOrdinal = reader.GetOrdinal("Notes");
            var createdOrdinal = reader.GetOrdinal("CreatedDate");
            var updatedOrdinal = reader.GetOrdinal("UpdatedDate");

            while (await reader.ReadAsync(cancellationToken))
            {
                rows.Add(new PatientLabResultRow
                {
                    LabResultId = GetReaderGuid(reader, idOrdinal),
                    TestName = GetReaderString(reader, testNameOrdinal),
                    TestCode = GetReaderString(reader, testCodeOrdinal),
                    SpecimenType = GetReaderString(reader, specimenTypeOrdinal),
                    CollectionDate = GetReaderNullableDateTime(reader, collectionOrdinal),
                    ResultDate = GetReaderNullableDateTime(reader, resultDateOrdinal),
                    ResultValue = GetReaderString(reader, resultValueOrdinal),
                    Unit = GetReaderString(reader, unitOrdinal),
                    ReferenceRange = GetReaderString(reader, referenceRangeOrdinal),
                    Status = GetReaderString(reader, statusOrdinal),
                    OrderedBy = GetReaderString(reader, orderedByOrdinal),
                    Lab = GetReaderString(reader, labOrdinal),
                    Interpretation = GetReaderString(reader, interpretationOrdinal),
                    Notes = GetReaderString(reader, notesOrdinal),
                    CreatedDate = GetReaderNullableDateTime(reader, createdOrdinal),
                    UpdatedDate = GetReaderNullableDateTime(reader, updatedOrdinal)
                });
            }

            var pendingOrders = rows
                .Where(IsPendingLabResult)
                .OrderByDescending(GetLabRowSortDate)
                .Select(row => new PatientPendingOrderDto
                {
                    LabResultId = row.LabResultId,
                    TestName = row.TestName,
                    TestCode = row.TestCode,
                    SpecimenType = row.SpecimenType,
                    Status = NormalizePendingOrderStatus(row.Status),
                    OrderedBy = row.OrderedBy,
                    Lab = row.Lab,
                    CollectionDate = row.CollectionDate,
                    ResultDate = row.ResultDate
                })
                .ToList();

            var results = rows
                .Where(row => !IsPendingLabResult(row))
                .OrderByDescending(GetLabRowSortDate)
                .Select(row => new PatientLabResultDto
                {
                    LabResultId = row.LabResultId,
                    TestName = row.TestName,
                    TestCode = row.TestCode,
                    ResultValue = row.ResultValue,
                    Unit = row.Unit,
                    ReferenceRange = row.ReferenceRange,
                    Severity = NormalizeResultSeverity(row.Status),
                    OrderedBy = row.OrderedBy,
                    Lab = row.Lab,
                    Interpretation = row.Interpretation,
                    Notes = row.Notes,
                    CollectionDate = row.CollectionDate,
                    ResultDate = row.ResultDate
                })
                .ToList();

            return new PatientOrdersResultsSnapshotDto
            {
                PendingOrders = pendingOrders,
                Results = results
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load orders and results for ID number {IdNumber}.", normalizedIdNumber);
            return new PatientOrdersResultsSnapshotDto();
        }
    }

    public async Task<IReadOnlyList<PatientVaccinationDto>> GetPatientVaccinationsAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        var normalizedIdNumber = PatientRequestRules.NormalizeText(idNumber);

        try
        {
            var items = new List<PatientVaccinationDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientVaccinations", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", normalizedIdNumber));

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idOrdinal = reader.GetOrdinal("VaccinationId");
            var nameOrdinal = reader.GetOrdinal("VaccineName");
            var codeOrdinal = reader.GetOrdinal("VaccineCode");
            var adminDateOrdinal = reader.GetOrdinal("AdministrationDate");
            var dueDateOrdinal = reader.GetOrdinal("DueDate");
            var administeredOrdinal = reader.GetOrdinal("AdministeredBy");
            var lotOrdinal = reader.GetOrdinal("Lot");
            var siteOrdinal = reader.GetOrdinal("Site");
            var routeOrdinal = reader.GetOrdinal("Route");
            var reactionOrdinal = reader.GetOrdinal("Reaction");
            var statusOrdinal = reader.GetOrdinal("Status");
            var notesOrdinal = reader.GetOrdinal("Notes");
            var updatedOrdinal = reader.GetOrdinal("UpdatedDate");

            while (await reader.ReadAsync(cancellationToken))
            {
                items.Add(new PatientVaccinationDto
                {
                    VaccinationId = GetReaderGuid(reader, idOrdinal),
                    VaccineName = GetReaderString(reader, nameOrdinal),
                    VaccineCode = GetReaderString(reader, codeOrdinal),
                    AdministrationDate = GetReaderDateTime(reader, adminDateOrdinal),
                    DueDate = GetReaderNullableDateTime(reader, dueDateOrdinal),
                    AdministeredBy = GetReaderString(reader, administeredOrdinal),
                    Lot = GetReaderString(reader, lotOrdinal),
                    Site = GetReaderString(reader, siteOrdinal),
                    Route = GetReaderString(reader, routeOrdinal),
                    Reaction = GetReaderString(reader, reactionOrdinal),
                    Status = GetReaderString(reader, statusOrdinal),
                    Notes = GetReaderString(reader, notesOrdinal),
                    UpdatedDate = GetReaderNullableDateTime(reader, updatedOrdinal)
                });
            }

            return items;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load vaccinations for ID number {IdNumber}.", normalizedIdNumber);
            return [];
        }
    }

    public async Task<IReadOnlyList<PatientConsultationNoteDto>> GetPatientConsultationNotesAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        var normalizedIdNumber = PatientRequestRules.NormalizeText(idNumber);

        try
        {
            var items = new List<PatientConsultationNoteDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientConsultationNotes", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", normalizedIdNumber));

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idOrdinal = reader.GetOrdinal("ConsultationNoteId");
            var appointmentOrdinal = reader.GetOrdinal("AppointmentIdFK");
            var providerOrdinal = reader.GetOrdinal("ProviderIdFK");
            var providerNameOrdinal = reader.GetOrdinal("ProviderName");
            var providerSpecializationOrdinal = reader.GetOrdinal("ProviderSpecialization");
            var consultDateOrdinal = reader.GetOrdinal("ConsultationDate");
            var complaintOrdinal = reader.GetOrdinal("ChiefComplaint");
            var symptomsOrdinal = reader.GetOrdinal("PresentingSymptoms");
            var historyOrdinal = reader.GetOrdinal("History");
            var examOrdinal = reader.GetOrdinal("PhysicalExamination");
            var diagnosisOrdinal = reader.GetOrdinal("Diagnosis");
            var codesOrdinal = reader.GetOrdinal("DiagnosisCodes");
            var planOrdinal = reader.GetOrdinal("TreatmentPlan");
            var medsOrdinal = reader.GetOrdinal("Medications");
            var proceduresOrdinal = reader.GetOrdinal("Procedures");
            var followUpOrdinal = reader.GetOrdinal("FollowUpDate");
            var referralNeededOrdinal = reader.GetOrdinal("ReferralNeeded");
            var referralReasonOrdinal = reader.GetOrdinal("ReferralReason");
            var restrictionsOrdinal = reader.GetOrdinal("Restrictions");
            var notesOrdinal = reader.GetOrdinal("Notes");
            var updatedOrdinal = reader.GetOrdinal("UpdatedDate");

            while (await reader.ReadAsync(cancellationToken))
            {
                items.Add(new PatientConsultationNoteDto
                {
                    ConsultationNoteId = GetReaderGuid(reader, idOrdinal),
                    AppointmentId = GetReaderGuid(reader, appointmentOrdinal),
                    ProviderId = GetReaderGuid(reader, providerOrdinal),
                    ProviderName = GetReaderString(reader, providerNameOrdinal),
                    ProviderSpecialization = GetReaderString(reader, providerSpecializationOrdinal),
                    ConsultationDate = GetReaderDateTime(reader, consultDateOrdinal),
                    ChiefComplaint = GetReaderString(reader, complaintOrdinal),
                    PresentingSymptoms = GetReaderString(reader, symptomsOrdinal),
                    History = GetReaderString(reader, historyOrdinal),
                    PhysicalExamination = GetReaderString(reader, examOrdinal),
                    Diagnosis = GetReaderString(reader, diagnosisOrdinal),
                    DiagnosisCodes = GetReaderString(reader, codesOrdinal),
                    TreatmentPlan = GetReaderString(reader, planOrdinal),
                    Medications = GetReaderString(reader, medsOrdinal),
                    Procedures = GetReaderString(reader, proceduresOrdinal),
                    FollowUpDate = GetReaderNullableDateTime(reader, followUpOrdinal),
                    ReferralNeeded = GetReaderBoolean(reader, referralNeededOrdinal),
                    ReferralReason = GetReaderString(reader, referralReasonOrdinal),
                    Restrictions = GetReaderString(reader, restrictionsOrdinal),
                    Notes = GetReaderString(reader, notesOrdinal),
                    UpdatedDate = GetReaderNullableDateTime(reader, updatedOrdinal)
                });
            }

            return items;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load consultation notes for ID number {IdNumber}.", normalizedIdNumber);
            return [];
        }
    }

    public async Task<IReadOnlyList<PatientReferralDto>> GetPatientReferralsAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        var normalizedIdNumber = PatientRequestRules.NormalizeText(idNumber);

        try
        {
            var items = new List<PatientReferralDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientReferrals", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", normalizedIdNumber));

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idOrdinal = reader.GetOrdinal("ReferralId");
            var referringIdOrdinal = reader.GetOrdinal("ReferringProviderIdFK");
            var referringNameOrdinal = reader.GetOrdinal("ReferringProviderName");
            var referredIdOrdinal = reader.GetOrdinal("ReferredProviderIdFK");
            var referredNameOrdinal = reader.GetOrdinal("ReferredProviderName");
            var referralDateOrdinal = reader.GetOrdinal("ReferralDate");
            var reasonOrdinal = reader.GetOrdinal("Reason");
            var priorityOrdinal = reader.GetOrdinal("Priority");
            var typeOrdinal = reader.GetOrdinal("ReferralType");
            var specializationOrdinal = reader.GetOrdinal("SpecializationNeeded");
            var referralCodeOrdinal = reader.GetOrdinal("ReferralCode");
            var statusOrdinal = reader.GetOrdinal("Status");
            var acceptanceOrdinal = reader.GetOrdinal("AcceptanceDate");
            var completionOrdinal = reader.GetOrdinal("CompletionDate");
            var notesOrdinal = reader.GetOrdinal("Notes");
            var updatedOrdinal = reader.GetOrdinal("UpdatedDate");

            while (await reader.ReadAsync(cancellationToken))
            {
                items.Add(new PatientReferralDto
                {
                    ReferralId = GetReaderGuid(reader, idOrdinal),
                    ReferringProviderId = GetReaderGuid(reader, referringIdOrdinal),
                    ReferringProviderName = GetReaderString(reader, referringNameOrdinal),
                    ReferredProviderId = GetReaderNullableGuid(reader, referredIdOrdinal),
                    ReferredProviderName = GetReaderString(reader, referredNameOrdinal),
                    ReferralDate = GetReaderDateTime(reader, referralDateOrdinal),
                    Reason = GetReaderString(reader, reasonOrdinal),
                    Priority = GetReaderString(reader, priorityOrdinal),
                    ReferralType = GetReaderString(reader, typeOrdinal),
                    SpecializationNeeded = GetReaderString(reader, specializationOrdinal),
                    ReferralCode = GetReaderString(reader, referralCodeOrdinal),
                    Status = GetReaderString(reader, statusOrdinal),
                    AcceptanceDate = GetReaderNullableDateTime(reader, acceptanceOrdinal),
                    CompletionDate = GetReaderNullableDateTime(reader, completionOrdinal),
                    Notes = GetReaderString(reader, notesOrdinal),
                    UpdatedDate = GetReaderNullableDateTime(reader, updatedOrdinal)
                });
            }

            return items;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load referrals for ID number {IdNumber}.", normalizedIdNumber);
            return [];
        }
    }

    private static string ResolveWorklistStatus(string status)
    {
        var normalized = (status ?? string.Empty).Trim().ToUpperInvariant();

        if (normalized.Contains("PROGRESS", StringComparison.Ordinal))
        {
            return "In Progress";
        }

        if (normalized.Contains("COMPLETE", StringComparison.Ordinal)
            || normalized.Contains("CANCEL", StringComparison.Ordinal)
            || normalized.Contains("NO-SHOW", StringComparison.Ordinal)
            || normalized.Contains("NO SHOW", StringComparison.Ordinal))
        {
            return "Discharged";
        }

        return "Waiting";
    }

    private static string ResolveWorklistClinic(string specialization)
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

    private static string ResolveWorklistRisk(DateTime? dateOfBirth, int activeConditions, int chronicConditions)
    {
        var age = dateOfBirth.HasValue
            ? CalculateAge(dateOfBirth.Value)
            : 0;

        if (chronicConditions >= 2 || activeConditions >= 4)
        {
            return "Critical";
        }

        if (chronicConditions >= 1 || activeConditions >= 3 || age >= 75)
        {
            return "High";
        }

        if (activeConditions >= 1 || age >= 60)
        {
            return "Moderate";
        }

        return "Low";
    }

    private static bool IsPendingLabResult(PatientLabResultRow row)
    {
        var normalized = (row.Status ?? string.Empty).Trim().ToUpperInvariant();
        if (string.IsNullOrWhiteSpace(normalized))
        {
            return false;
        }

        return normalized.Contains("PENDING", StringComparison.Ordinal)
            || normalized.Contains("ORDER", StringComparison.Ordinal)
            || normalized.Contains("PROCESS", StringComparison.Ordinal)
            || normalized.Contains("COLLECT", StringComparison.Ordinal)
            || normalized.Contains("QUEUE", StringComparison.Ordinal);
    }

    private static string NormalizePendingOrderStatus(string status)
    {
        var normalized = (status ?? string.Empty).Trim().ToUpperInvariant();

        if (normalized.Contains("COLLECT", StringComparison.Ordinal))
        {
            return "Collected";
        }

        if (normalized.Contains("PROCESS", StringComparison.Ordinal))
        {
            return "Processing";
        }

        if (normalized.Contains("ORDER", StringComparison.Ordinal))
        {
            return "Ordered";
        }

        if (normalized.Contains("QUEUE", StringComparison.Ordinal))
        {
            return "Queued";
        }

        if (normalized.Contains("PENDING", StringComparison.Ordinal))
        {
            return "Pending";
        }

        return string.IsNullOrWhiteSpace(status) ? "Pending" : status.Trim();
    }

    private static string NormalizeResultSeverity(string status)
    {
        var normalized = (status ?? string.Empty).Trim().ToUpperInvariant();

        if (normalized.Contains("CRITIC", StringComparison.Ordinal))
        {
            return "Critical";
        }

        if (normalized.Contains("ABNORMAL", StringComparison.Ordinal)
            || normalized.Contains("HIGH", StringComparison.Ordinal)
            || normalized.Contains("LOW", StringComparison.Ordinal))
        {
            return "Abnormal";
        }

        return "Normal";
    }

    private static DateTime GetLabRowSortDate(PatientLabResultRow row)
        => row.ResultDate
            ?? row.CollectionDate
            ?? row.UpdatedDate
            ?? row.CreatedDate
            ?? DateTime.MinValue;

    private static int CalculateAge(DateTime dateOfBirth)
    {
        var today = DateTime.UtcNow.Date;
        var birthDate = dateOfBirth.Date;

        var age = today.Year - birthDate.Year;
        if (birthDate > today.AddYears(-age))
        {
            age--;
        }

        return Math.Max(0, age);
    }

    private async Task PopulateClientSummariesAsync(
        List<PatientDirectoryItemDto> patients,
        CancellationToken cancellationToken)
    {
        var clientIds = patients
            .Where((patient) => patient.ClientId.HasValue && patient.ClientId.Value != Guid.Empty)
            .Select((patient) => patient.ClientId!.Value)
            .Distinct()
            .ToArray();

        if (clientIds.Length == 0)
        {
            return;
        }

        var summaries = await GetClientLookupMapAsync(clientIds, cancellationToken);
        foreach (var patient in patients)
        {
            if (!patient.ClientId.HasValue || !summaries.TryGetValue(patient.ClientId.Value, out var summary))
            {
                continue;
            }

            patient.ClientCode = summary.ClientCode;
            patient.ClientName = summary.ClientName;
            patient.ClientClinicCategoryName = summary.ClientClinicCategoryName;
        }
    }

    private async Task PopulateClientAssignmentsAsync(
        List<PatientDirectoryItemDto> patients,
        CancellationToken cancellationToken)
    {
        var patientIds = patients
            .Select((patient) => patient.PatientId)
            .Where((patientId) => patientId != Guid.Empty)
            .Distinct()
            .ToArray();

        if (patientIds.Length == 0)
        {
            return;
        }

        var assignmentMap = await GetPatientClientAssignmentsMapAsync(patientIds, cancellationToken);
        if (assignmentMap.Count == 0)
        {
            return;
        }

        foreach (var patient in patients)
        {
            if (!assignmentMap.TryGetValue(patient.PatientId, out var assignments) || assignments.Count == 0)
            {
                continue;
            }

            patient.Clients = assignments;

            var primaryAssignment = assignments.FirstOrDefault((assignment) => assignment.IsPrimary) ?? assignments[0];
            patient.ClientId = primaryAssignment.ClientId;
            patient.ClientCode = primaryAssignment.ClientCode;
            patient.ClientName = primaryAssignment.ClientName;
            patient.ClientClinicCategoryName = primaryAssignment.ClientClinicCategoryName;
        }
    }

    private async Task<Dictionary<Guid, PatientClientLookupItemDto>> GetClientLookupMapAsync(
        IReadOnlyCollection<Guid> clientIds,
        CancellationToken cancellationToken)
    {
        if (clientIds.Count == 0)
        {
            return [];
        }

        try
        {
            var parameterNames = clientIds
                .Select((_, index) => $"@ClientId{index}")
                .ToArray();

            var lookup = new Dictionary<Guid, PatientClientLookupItemDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand(
                $"""
                 SELECT
                     C.ClientId,
                     C.ClientCode,
                     C.FirstName,
                     C.LastName,
                     ISNULL(CCC.CategoryName, '') AS ClientClinicCategoryName
                 FROM Profile.Clients C
                 LEFT JOIN Profile.ClientClinicCategories CCC
                     ON CCC.ClientClinicCategoryId = C.ClientClinicCategoryIDFK
                 WHERE C.ClientId IN ({string.Join(", ", parameterNames)});
                 """,
                connection);

            var index = 0;
            foreach (var clientId in clientIds)
            {
                command.Parameters.Add(new SqlParameter(parameterNames[index], SqlDbType.UniqueIdentifier) { Value = clientId });
                index += 1;
            }

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var clientIdOrdinal = reader.GetOrdinal("ClientId");
            var clientCodeOrdinal = reader.GetOrdinal("ClientCode");
            var firstNameOrdinal = reader.GetOrdinal("FirstName");
            var lastNameOrdinal = reader.GetOrdinal("LastName");
            var categoryNameOrdinal = reader.GetOrdinal("ClientClinicCategoryName");

            while (await reader.ReadAsync(cancellationToken))
            {
                var clientId = GetReaderGuid(reader, clientIdOrdinal);
                if (clientId == Guid.Empty)
                {
                    continue;
                }

                var clientCode = GetReaderString(reader, clientCodeOrdinal);
                var firstName = GetReaderString(reader, firstNameOrdinal);
                var lastName = GetReaderString(reader, lastNameOrdinal);

                lookup[clientId] = new PatientClientLookupItemDto
                {
                    ClientId = clientId,
                    ClientCode = clientCode,
                    ClientName = BuildClientDisplayName(firstName, lastName, clientCode),
                    ClientClinicCategoryName = GetReaderString(reader, categoryNameOrdinal)
                };
            }

            return lookup;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to resolve client summaries for patient records.");
            return [];
        }
    }

    private async Task<IReadOnlyList<PatientClientAssignmentDto>> GetPatientClientAssignmentsAsync(
        Guid patientId,
        CancellationToken cancellationToken)
    {
        var map = await GetPatientClientAssignmentsMapAsync([patientId], cancellationToken);
        return map.TryGetValue(patientId, out var assignments) ? assignments : [];
    }

    private async Task<Dictionary<Guid, List<PatientClientAssignmentDto>>> GetPatientClientAssignmentsMapAsync(
        IReadOnlyCollection<Guid> patientIds,
        CancellationToken cancellationToken)
    {
        if (patientIds.Count == 0)
        {
            return [];
        }

        try
        {
            var parameterNames = patientIds
                .Select((_, index) => $"@PatientId{index}")
                .ToArray();

            var lookup = new Dictionary<Guid, List<PatientClientAssignmentDto>>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand(
                $"""
                 SELECT
                     PC.PatientIdFK,
                     PC.ClientIdFK,
                     C.ClientCode,
                     C.FirstName,
                     C.LastName,
                     ISNULL(CCC.CategoryName, '') AS ClientClinicCategoryName,
                     PC.IsPrimary
                 FROM Profile.PatientClients PC
                 INNER JOIN Profile.Clients C
                     ON C.ClientId = PC.ClientIdFK
                 LEFT JOIN Profile.ClientClinicCategories CCC
                     ON CCC.ClientClinicCategoryId = C.ClientClinicCategoryIDFK
                 WHERE PC.PatientIdFK IN ({string.Join(", ", parameterNames)})
                 ORDER BY PC.PatientIdFK ASC, PC.IsPrimary DESC, C.FirstName ASC, C.LastName ASC, C.ClientCode ASC;
                 """,
                connection);

            var index = 0;
            foreach (var patientId in patientIds)
            {
                command.Parameters.Add(new SqlParameter(parameterNames[index], SqlDbType.UniqueIdentifier) { Value = patientId });
                index += 1;
            }

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var patientIdOrdinal = reader.GetOrdinal("PatientIdFK");
            var clientIdOrdinal = reader.GetOrdinal("ClientIdFK");
            var clientCodeOrdinal = reader.GetOrdinal("ClientCode");
            var firstNameOrdinal = reader.GetOrdinal("FirstName");
            var lastNameOrdinal = reader.GetOrdinal("LastName");
            var categoryNameOrdinal = reader.GetOrdinal("ClientClinicCategoryName");
            var isPrimaryOrdinal = reader.GetOrdinal("IsPrimary");

            while (await reader.ReadAsync(cancellationToken))
            {
                var patientId = GetReaderGuid(reader, patientIdOrdinal);
                var clientId = GetReaderGuid(reader, clientIdOrdinal);
                if (patientId == Guid.Empty || clientId == Guid.Empty)
                {
                    continue;
                }

                if (!lookup.TryGetValue(patientId, out var assignments))
                {
                    assignments = [];
                    lookup[patientId] = assignments;
                }

                var clientCode = GetReaderString(reader, clientCodeOrdinal);
                var firstName = GetReaderString(reader, firstNameOrdinal);
                var lastName = GetReaderString(reader, lastNameOrdinal);

                assignments.Add(new PatientClientAssignmentDto
                {
                    ClientId = clientId,
                    ClientCode = clientCode,
                    ClientName = BuildClientDisplayName(firstName, lastName, clientCode),
                    ClientClinicCategoryName = GetReaderString(reader, categoryNameOrdinal),
                    IsPrimary = GetReaderBoolean(reader, isPrimaryOrdinal)
                });
            }

            return lookup;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to resolve patient-client memberships.");
            return [];
        }
    }

    private async Task<Guid?> GetPatientIdByIdNumberAsync(
        string idNumber,
        bool includeDeleted,
        CancellationToken cancellationToken)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand(
                """
                SELECT TOP (1) PatientId
                FROM Profile.Patient
                WHERE ID_Number = @IDNumber
                  AND (@IncludeDeleted = 1 OR IsDeleted = 0);
                """,
                connection);

            command.Parameters.Add(new SqlParameter("@IDNumber", SqlDbType.VarChar, 250) { Value = idNumber });
            command.Parameters.Add(new SqlParameter("@IncludeDeleted", SqlDbType.Bit) { Value = includeDeleted });

            await connection.OpenAsync(cancellationToken);
            var scalar = await command.ExecuteScalarAsync(cancellationToken);
            return scalar is Guid patientId ? patientId : null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to resolve patient ID for {IdNumber}.", idNumber);
            return null;
        }
    }

    private static string BuildClientDisplayName(string firstName, string lastName, string clientCode)
    {
        var name = $"{firstName} {lastName}".Trim();
        return string.IsNullOrWhiteSpace(name) ? clientCode : name;
    }

    private static PatientCreateRequest NormalizeRequest(PatientCreateRequest request)
        => new()
        {
            PrimaryClientId = request.PrimaryClientId,
            SecondaryClientIds = request.SecondaryClientIds,
            FirstName = PatientRequestRules.NormalizeText(request.FirstName),
            LastName = PatientRequestRules.NormalizeText(request.LastName),
            IdNumber = PatientRequestRules.NormalizeText(request.IdNumber),
            DateOfBirth = PatientRequestRules.NormalizeDate(request.DateOfBirth),
            GenderId = request.GenderId,
            PhoneNumber = PatientRequestRules.NormalizeText(request.PhoneNumber),
            Email = PatientRequestRules.NormalizeText(request.Email),
            Line1 = PatientRequestRules.NormalizeText(request.Line1),
            Line2 = PatientRequestRules.NormalizeText(request.Line2),
            CityId = request.CityId,
            ProvinceId = request.ProvinceId,
            CountryId = request.CountryId,
            MaritalStatusId = request.MaritalStatusId,
            EmergencyName = PatientRequestRules.NormalizeText(request.EmergencyName),
            EmergencyLastName = PatientRequestRules.NormalizeText(request.EmergencyLastName),
            EmergencyPhoneNumber = PatientRequestRules.NormalizeText(request.EmergencyPhoneNumber),
            Relationship = PatientRequestRules.NormalizeText(request.Relationship),
            EmergencyDateOfBirth = PatientRequestRules.NormalizeDate(request.EmergencyDateOfBirth),
            MedicationList = PatientRequestRules.NormalizeText(request.MedicationList)
        };

    private static PatientUpdateRequest NormalizeRequest(PatientUpdateRequest request)
        => new()
        {
            PrimaryClientId = request.PrimaryClientId,
            SecondaryClientIds = request.SecondaryClientIds,
            FirstName = PatientRequestRules.NormalizeText(request.FirstName),
            LastName = PatientRequestRules.NormalizeText(request.LastName),
            DateOfBirth = PatientRequestRules.NormalizeDate(request.DateOfBirth),
            GenderId = request.GenderId,
            PhoneNumber = PatientRequestRules.NormalizeText(request.PhoneNumber),
            Email = PatientRequestRules.NormalizeText(request.Email),
            Line1 = PatientRequestRules.NormalizeText(request.Line1),
            Line2 = PatientRequestRules.NormalizeText(request.Line2),
            CityId = request.CityId,
            ProvinceId = request.ProvinceId,
            CountryId = request.CountryId,
            MaritalStatusId = request.MaritalStatusId,
            EmergencyName = PatientRequestRules.NormalizeText(request.EmergencyName),
            EmergencyLastName = PatientRequestRules.NormalizeText(request.EmergencyLastName),
            EmergencyPhoneNumber = PatientRequestRules.NormalizeText(request.EmergencyPhoneNumber),
            Relationship = PatientRequestRules.NormalizeText(request.Relationship),
            EmergencyDateOfBirth = PatientRequestRules.NormalizeDate(request.EmergencyDateOfBirth),
            MedicationList = PatientRequestRules.NormalizeText(request.MedicationList)
        };

    private static (bool IsValid, Guid PrimaryClientId, string AdditionalClientIdsCsv) BuildClientSelection(
        Guid? primaryClientId,
        IReadOnlyList<Guid>? secondaryClientIds)
    {
        if (!primaryClientId.HasValue || primaryClientId.Value == Guid.Empty)
        {
            return (false, Guid.Empty, string.Empty);
        }

        var normalizedSecondaryIds = (secondaryClientIds ?? [])
            .Where((clientId) => clientId != Guid.Empty && clientId != primaryClientId.Value)
            .Distinct()
            .ToArray();

        return (true, primaryClientId.Value, string.Join(",", normalizedSecondaryIds));
    }

    private static object ToDbString(string? value)
    {
        var trimmed = (value ?? string.Empty).Trim();
        return trimmed.Length > 0 ? trimmed : DBNull.Value;
    }

    private sealed class PatientLabResultRow
    {
        public Guid LabResultId { get; init; }
        public string TestName { get; init; } = string.Empty;
        public string TestCode { get; init; } = string.Empty;
        public string SpecimenType { get; init; } = string.Empty;
        public DateTime? CollectionDate { get; init; }
        public DateTime? ResultDate { get; init; }
        public string ResultValue { get; init; } = string.Empty;
        public string Unit { get; init; } = string.Empty;
        public string ReferenceRange { get; init; } = string.Empty;
        public string Status { get; init; } = string.Empty;
        public string OrderedBy { get; init; } = string.Empty;
        public string Lab { get; init; } = string.Empty;
        public string Interpretation { get; init; } = string.Empty;
        public string Notes { get; init; } = string.Empty;
        public DateTime? CreatedDate { get; init; }
        public DateTime? UpdatedDate { get; init; }
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

    private static string GetReaderString(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? string.Empty : Convert.ToString(reader.GetValue(ordinal)) ?? string.Empty;

    private static Guid GetReaderGuid(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? Guid.Empty : reader.GetGuid(ordinal);

    private static int GetReaderInt(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? 0 : Convert.ToInt32(reader.GetValue(ordinal));

    private static Guid? GetReaderNullableGuid(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? null : reader.GetGuid(ordinal);

    private static DateTime GetReaderDateTime(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? DateTime.MinValue : Convert.ToDateTime(reader.GetValue(ordinal));

    private static DateTime? GetReaderNullableDateTime(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? null : Convert.ToDateTime(reader.GetValue(ordinal));

    private static bool GetReaderBoolean(SqlDataReader reader, int ordinal)
        => !reader.IsDBNull(ordinal) && Convert.ToBoolean(reader.GetValue(ordinal));

    private static (int PageNumber, int PageSize) NormalizePage(int pageNumber, int pageSize)
    {
        var normalizedPageNumber = pageNumber < 1 ? 1 : pageNumber;
        var normalizedPageSize = pageSize < 1 ? DefaultPageSize : Math.Min(pageSize, MaxPageSize);
        return (normalizedPageNumber, normalizedPageSize);
    }

    private static DateTime GetDateTimeOutput(SqlCommand command, string parameterName)
    {
        var value = command.Parameters[parameterName].Value;
        return value == DBNull.Value ? DateTime.MinValue : Convert.ToDateTime(value);
    }
}
