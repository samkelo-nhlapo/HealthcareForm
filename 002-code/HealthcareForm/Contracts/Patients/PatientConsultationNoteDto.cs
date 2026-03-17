namespace HealthcareForm.Contracts.Patients;

public sealed class PatientConsultationNoteDto
{
    public Guid ConsultationNoteId { get; init; }
    public Guid AppointmentId { get; init; }
    public Guid ProviderId { get; init; }
    public string ProviderName { get; init; } = string.Empty;
    public string ProviderSpecialization { get; init; } = string.Empty;
    public DateTime ConsultationDate { get; init; }
    public string ChiefComplaint { get; init; } = string.Empty;
    public string PresentingSymptoms { get; init; } = string.Empty;
    public string History { get; init; } = string.Empty;
    public string PhysicalExamination { get; init; } = string.Empty;
    public string Diagnosis { get; init; } = string.Empty;
    public string DiagnosisCodes { get; init; } = string.Empty;
    public string TreatmentPlan { get; init; } = string.Empty;
    public string Medications { get; init; } = string.Empty;
    public string Procedures { get; init; } = string.Empty;
    public DateTime? FollowUpDate { get; init; }
    public bool ReferralNeeded { get; init; }
    public string ReferralReason { get; init; } = string.Empty;
    public string Restrictions { get; init; } = string.Empty;
    public string Notes { get; init; } = string.Empty;
    public DateTime? UpdatedDate { get; init; }
}
