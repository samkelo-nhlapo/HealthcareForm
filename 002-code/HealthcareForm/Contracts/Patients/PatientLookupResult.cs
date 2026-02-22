namespace HealthcareForm.Contracts.Patients;

public sealed class PatientLookupResult
{
    public bool Found { get; init; }
    public string Message { get; init; } = string.Empty;
    public PatientRecordDto? Patient { get; init; }
}
