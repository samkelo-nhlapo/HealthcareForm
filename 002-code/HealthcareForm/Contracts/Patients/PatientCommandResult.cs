namespace HealthcareForm.Contracts.Patients;

public sealed class PatientCommandResult
{
    public bool Success { get; init; }
    public string Message { get; init; } = string.Empty;
    public int? StatusCode { get; init; }
    public Guid? PatientId { get; init; }
}
