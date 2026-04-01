namespace HealthcareForm.Contracts.Patients;

// Result returned when looking up a patient by ID number.
public sealed class PatientLookupResult
{
    // Indicates whether a patient record was found.
    public bool Found { get; init; }

    // Human-readable message for not-found or error cases.
    public string Message { get; init; } = string.Empty;

    // Patient record when the lookup succeeds.
    public PatientRecordDto? Patient { get; init; }
}
