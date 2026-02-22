namespace HealthcareForm.Contracts.Patients;

public sealed class PatientWorklistItemDto
{
    public string IdNumber { get; init; } = string.Empty;
    public string Patient { get; init; } = string.Empty;
    public string Status { get; init; } = "Waiting";
    public string Clinic { get; init; } = "General";
    public string Risk { get; init; } = "Low";
    public string UpdatedOn { get; init; } = string.Empty;
}
