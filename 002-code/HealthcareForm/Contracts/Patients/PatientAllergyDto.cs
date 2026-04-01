namespace HealthcareForm.Contracts.Patients;

// Allergy entry returned for a patient.
public sealed class PatientAllergyDto
{
    // Unique identifier for the allergy record.
    public Guid AllergyId { get; init; }

    // Allergy category such as drug, food, or environmental.
    public string AllergyType { get; init; } = string.Empty;

    // Named allergen recorded for the patient.
    public string AllergenName { get; init; } = string.Empty;

    // Documented reaction.
    public string Reaction { get; init; } = string.Empty;

    // Severity label used by the chart.
    public string Severity { get; init; } = string.Empty;

    // Date the reaction started, when known.
    public DateTime? ReactionOnsetDate { get; init; }

    // Person or role that verified the record.
    public string VerifiedBy { get; init; } = string.Empty;

    // Indicates whether the allergy is still considered active.
    public bool IsActive { get; init; }

    // Last update timestamp from the source system.
    public DateTime? UpdatedDate { get; init; }
}
