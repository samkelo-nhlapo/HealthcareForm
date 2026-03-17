using HealthcareForm.Contracts.Patients;

namespace HealthcareForm.Services;

public interface IPatientService
{
    Task<IReadOnlyList<PatientWorklistItemDto>> GetWorklistAsync(CancellationToken cancellationToken = default);
    Task<PatientCommandResult> AddPatientAsync(PatientCreateRequest request, CancellationToken cancellationToken = default);
    Task<PatientCommandResult> UpdatePatientAsync(string idNumber, PatientUpdateRequest request, CancellationToken cancellationToken = default);
    Task<PatientLookupResult> GetPatientAsync(string idNumber, CancellationToken cancellationToken = default);
    Task<PatientCommandResult> DeletePatientAsync(string idNumber, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<PatientAllergyDto>> GetPatientAllergiesAsync(string idNumber, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<PatientMedicationDto>> GetPatientMedicationsAsync(string idNumber, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<PatientVaccinationDto>> GetPatientVaccinationsAsync(string idNumber, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<PatientConsultationNoteDto>> GetPatientConsultationNotesAsync(string idNumber, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<PatientReferralDto>> GetPatientReferralsAsync(string idNumber, CancellationToken cancellationToken = default);
}
