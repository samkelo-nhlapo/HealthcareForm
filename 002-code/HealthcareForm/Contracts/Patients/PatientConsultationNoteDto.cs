namespace HealthcareForm.Contracts.Patients;

// Consultation note returned for a patient.
public sealed class PatientConsultationNoteDto
{
    // Unique identifier for the consultation note.
    public Guid ConsultationNoteId { get; init; }

    // Appointment that produced the note.
    public Guid AppointmentId { get; init; }

    // Provider identifier associated with the note.
    public Guid ProviderId { get; init; }

    // Provider display name.
    public string ProviderName { get; init; } = string.Empty;

    // Provider specialization shown in the chart.
    public string ProviderSpecialization { get; init; } = string.Empty;

    // Date and time of the consultation.
    public DateTime ConsultationDate { get; init; }

    // Chief complaint captured for the visit.
    public string ChiefComplaint { get; init; } = string.Empty;

    // Symptoms recorded during the consultation.
    public string PresentingSymptoms { get; init; } = string.Empty;

    // Relevant patient history for the encounter.
    public string History { get; init; } = string.Empty;

    // Physical examination findings.
    public string PhysicalExamination { get; init; } = string.Empty;

    // Diagnosis summary.
    public string Diagnosis { get; init; } = string.Empty;

    // Diagnosis coding captured for the note.
    public string DiagnosisCodes { get; init; } = string.Empty;

    // Treatment plan recorded by the provider.
    public string TreatmentPlan { get; init; } = string.Empty;

    // Medications captured in the note.
    public string Medications { get; init; } = string.Empty;

    // Procedures performed or planned.
    public string Procedures { get; init; } = string.Empty;

    // Suggested follow-up date, when one was recorded.
    public DateTime? FollowUpDate { get; init; }

    // Indicates whether the encounter called for a referral.
    public bool ReferralNeeded { get; init; }

    // Reason for the referral when one is required.
    public string ReferralReason { get; init; } = string.Empty;

    // Activity restrictions or return-to-work notes.
    public string Restrictions { get; init; } = string.Empty;

    // Free-form note text.
    public string Notes { get; init; } = string.Empty;

    // Last update timestamp from the source system.
    public DateTime? UpdatedDate { get; init; }
}
