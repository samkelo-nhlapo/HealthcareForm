using HealthcareForm.Contracts.Patients;
using System.Data;
using System.Data.SqlClient;

namespace HealthcareForm.Services;

public sealed class PatientService : IPatientService
{
    private const string ConnectionStringKey = "HealthcareEntity";
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

    public async Task<IReadOnlyList<PatientAllergyDto>> GetPatientAllergiesAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        try
        {
            var items = new List<PatientAllergyDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientAllergies", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", idNumber));

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
            _logger.LogError(ex, "Failed to load allergies for ID number {IdNumber}.", idNumber);
            return [];
        }
    }

    public async Task<IReadOnlyList<PatientMedicationDto>> GetPatientMedicationsAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        try
        {
            var items = new List<PatientMedicationDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientMedications", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", idNumber));

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
            _logger.LogError(ex, "Failed to load medications for ID number {IdNumber}.", idNumber);
            return [];
        }
    }

    public async Task<IReadOnlyList<PatientVaccinationDto>> GetPatientVaccinationsAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        try
        {
            var items = new List<PatientVaccinationDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientVaccinations", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", idNumber));

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
            _logger.LogError(ex, "Failed to load vaccinations for ID number {IdNumber}.", idNumber);
            return [];
        }
    }

    public async Task<IReadOnlyList<PatientConsultationNoteDto>> GetPatientConsultationNotesAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        try
        {
            var items = new List<PatientConsultationNoteDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientConsultationNotes", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", idNumber));

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
            _logger.LogError(ex, "Failed to load consultation notes for ID number {IdNumber}.", idNumber);
            return [];
        }
    }

    public async Task<IReadOnlyList<PatientReferralDto>> GetPatientReferralsAsync(string idNumber, CancellationToken cancellationToken = default)
    {
        try
        {
            var items = new List<PatientReferralDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetPatientReferrals", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@IDNumber", idNumber));

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
            _logger.LogError(ex, "Failed to load referrals for ID number {IdNumber}.", idNumber);
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

    private static Guid? GetReaderNullableGuid(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? null : reader.GetGuid(ordinal);

    private static DateTime GetReaderDateTime(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? DateTime.MinValue : Convert.ToDateTime(reader.GetValue(ordinal));

    private static DateTime? GetReaderNullableDateTime(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? null : Convert.ToDateTime(reader.GetValue(ordinal));

    private static bool GetReaderBoolean(SqlDataReader reader, int ordinal)
        => !reader.IsDBNull(ordinal) && Convert.ToBoolean(reader.GetValue(ordinal));

    private static DateTime GetDateTimeOutput(SqlCommand command, string parameterName)
    {
        var value = command.Parameters[parameterName].Value;
        return value == DBNull.Value ? DateTime.MinValue : Convert.ToDateTime(value);
    }
}
