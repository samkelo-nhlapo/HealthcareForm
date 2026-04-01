namespace HealthcareForm.Contracts.Patients;

// Medication entry returned for a patient.
public sealed class PatientMedicationDto
{
    // Unique identifier for the medication record.
    public Guid MedicationId { get; init; }

    // Medication display name.
    public string MedicationName { get; init; } = string.Empty;

    // Dosage instructions captured for the medication.
    public string Dosage { get; init; } = string.Empty;

    // Frequency instructions captured for the medication.
    public string Frequency { get; init; } = string.Empty;

    // Route of administration.
    public string Route { get; init; } = string.Empty;

    // Recorded indication or reason for the medication.
    public string Indication { get; init; } = string.Empty;

    // Prescriber name captured for the medication.
    public string PrescribedBy { get; init; } = string.Empty;

    // Date the prescription was issued.
    public DateTime PrescriptionDate { get; init; }

    // Medication start date.
    public DateTime StartDate { get; init; }

    // Medication end date when applicable.
    public DateTime? EndDate { get; init; }

    // Current medication status.
    public string Status { get; init; } = string.Empty;

    // Recorded side effects.
    public string SideEffects { get; init; } = string.Empty;

    // Free-form medication notes.
    public string Notes { get; init; } = string.Empty;

    // Indicates whether the medication is still active.
    public bool IsActive { get; init; }

    // Last update timestamp from the source system.
    public DateTime? UpdatedDate { get; init; }
}
