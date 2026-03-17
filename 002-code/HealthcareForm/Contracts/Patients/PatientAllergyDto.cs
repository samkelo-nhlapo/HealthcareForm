namespace HealthcareForm.Contracts.Patients;

public sealed class PatientAllergyDto
{
    public Guid AllergyId { get; init; }
    public string AllergyType { get; init; } = string.Empty;
    public string AllergenName { get; init; } = string.Empty;
    public string Reaction { get; init; } = string.Empty;
    public string Severity { get; init; } = string.Empty;
    public DateTime? ReactionOnsetDate { get; init; }
    public string VerifiedBy { get; init; } = string.Empty;
    public bool IsActive { get; init; }
    public DateTime? UpdatedDate { get; init; }
}
