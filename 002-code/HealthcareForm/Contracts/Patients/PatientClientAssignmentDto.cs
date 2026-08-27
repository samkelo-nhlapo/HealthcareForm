namespace HealthcareForm.Contracts.Patients;

// One client membership attached to a patient record.
public sealed class PatientClientAssignmentDto
{
    public Guid ClientId { get; init; }
    public string ClientCode { get; init; } = string.Empty;
    public string ClientName { get; init; } = string.Empty;
    public string ClientClinicCategoryName { get; init; } = string.Empty;
    public bool IsPrimary { get; init; }
}
