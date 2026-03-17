namespace HealthcareForm.Contracts.Lookups;

public sealed class MedicationLookupDto
{
    public Guid MedicationId { get; init; }
    public string MedicationName { get; init; } = string.Empty;
    public string MedicationGenericName { get; init; } = string.Empty;
    public string MedicationCategory { get; init; } = string.Empty;
    public string Strength { get; init; } = string.Empty;
    public string Unit { get; init; } = string.Empty;
    public string RouteOfAdministration { get; init; } = string.Empty;
    public string ManufacturerName { get; init; } = string.Empty;
    public bool IsActive { get; init; }
}
