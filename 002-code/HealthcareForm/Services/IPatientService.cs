using HealthcareForm.Contracts.Patients;

namespace HealthcareForm.Services;

// Patient record operations used by the clinical API.
public interface IPatientService
{
    // Builds the worklist shown in the clinical shell.
    Task<IReadOnlyList<PatientWorklistItemDto>> GetWorklistAsync(CancellationToken cancellationToken = default);

    // Creates a new patient record.
    Task<PatientCommandResult> AddPatientAsync(PatientCreateRequest request, CancellationToken cancellationToken = default);

    // Updates an existing patient record.
    Task<PatientCommandResult> UpdatePatientAsync(string idNumber, PatientUpdateRequest request, CancellationToken cancellationToken = default);

    // Retrieves a patient by national ID number.
    Task<PatientLookupResult> GetPatientAsync(string idNumber, CancellationToken cancellationToken = default);

    // Deletes a patient record.
    Task<PatientCommandResult> DeletePatientAsync(string idNumber, CancellationToken cancellationToken = default);

    // Retrieves allergy history for the requested patient.
    Task<IReadOnlyList<PatientAllergyDto>> GetPatientAllergiesAsync(string idNumber, CancellationToken cancellationToken = default);

    // Retrieves medication history for the requested patient.
    Task<IReadOnlyList<PatientMedicationDto>> GetPatientMedicationsAsync(string idNumber, CancellationToken cancellationToken = default);

    // Retrieves vaccination history for the requested patient.
    Task<IReadOnlyList<PatientVaccinationDto>> GetPatientVaccinationsAsync(string idNumber, CancellationToken cancellationToken = default);

    // Retrieves consultation notes for the requested patient.
    Task<IReadOnlyList<PatientConsultationNoteDto>> GetPatientConsultationNotesAsync(string idNumber, CancellationToken cancellationToken = default);

    // Retrieves referral history for the requested patient.
    Task<IReadOnlyList<PatientReferralDto>> GetPatientReferralsAsync(string idNumber, CancellationToken cancellationToken = default);
}
