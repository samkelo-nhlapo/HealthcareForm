namespace HealthcareForm.Contracts.Patients;

// Completed lab result entry returned for a patient.
public sealed class PatientLabResultDto
{
    // Unique identifier of the lab result row.
    public Guid LabResultId { get; init; }

    // Test display name.
    public string TestName { get; init; } = string.Empty;

    // Optional laboratory code for the test.
    public string TestCode { get; init; } = string.Empty;

    // Result value captured for the test.
    public string ResultValue { get; init; } = string.Empty;

    // Unit associated with the result value.
    public string Unit { get; init; } = string.Empty;

    // Reference range supplied with the result.
    public string ReferenceRange { get; init; } = string.Empty;

    // Normalized severity for the result row.
    public string Severity { get; init; } = string.Empty;

    // Provider or staff member recorded as the ordering owner.
    public string OrderedBy { get; init; } = string.Empty;

    // Laboratory or facility associated with the result.
    public string Lab { get; init; } = string.Empty;

    // Free-form interpretation captured with the result.
    public string Interpretation { get; init; } = string.Empty;

    // Free-form notes captured with the result.
    public string Notes { get; init; } = string.Empty;

    // Collection timestamp when one has been captured.
    public DateTime? CollectionDate { get; init; }

    // Result completion timestamp.
    public DateTime? ResultDate { get; init; }
}
