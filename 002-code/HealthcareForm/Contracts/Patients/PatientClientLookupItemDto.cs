namespace HealthcareForm.Contracts.Patients;

// Lightweight client option used when assigning a patient to a clinic or hospital.
public sealed class PatientClientLookupItemDto
{
    public Guid ClientId { get; init; }
    public string ClientCode { get; init; } = string.Empty;
    public string ClientName { get; init; } = string.Empty;
    public string ClientClinicCategoryName { get; init; } = string.Empty;
}
