namespace HealthcareForm.Contracts.Lookups;

public sealed class AllergyLookupDto
{
    public Guid AllergyId { get; init; }
    public string AllergyName { get; init; } = string.Empty;
    public string AllergyCategory { get; init; } = string.Empty;
    public string Severity { get; init; } = string.Empty;
    public string ReactionDescription { get; init; } = string.Empty;
    public bool IsCritical { get; init; }
    public bool IsActive { get; init; }
}
