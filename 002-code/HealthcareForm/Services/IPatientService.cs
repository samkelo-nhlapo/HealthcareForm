using HealthcareForm.Contracts.Patients;

namespace HealthcareForm.Services;

public interface IPatientService
{
    Task<IReadOnlyList<PatientWorklistItemDto>> GetWorklistAsync(CancellationToken cancellationToken = default);
    Task<PatientCommandResult> AddPatientAsync(PatientCreateRequest request, CancellationToken cancellationToken = default);
    Task<PatientCommandResult> UpdatePatientAsync(string idNumber, PatientUpdateRequest request, CancellationToken cancellationToken = default);
    Task<PatientLookupResult> GetPatientAsync(string idNumber, CancellationToken cancellationToken = default);
    Task<PatientCommandResult> DeletePatientAsync(string idNumber, CancellationToken cancellationToken = default);
}
