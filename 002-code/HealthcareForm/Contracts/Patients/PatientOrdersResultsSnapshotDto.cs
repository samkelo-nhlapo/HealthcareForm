namespace HealthcareForm.Contracts.Patients;

// Combined orders-and-results snapshot used by the clinical workspace.
public sealed class PatientOrdersResultsSnapshotDto
{
    // Open laboratory orders inferred from pending lab-result rows.
    public IReadOnlyList<PatientPendingOrderDto> PendingOrders { get; init; } = [];

    // Completed laboratory results for the patient.
    public IReadOnlyList<PatientLabResultDto> Results { get; init; } = [];
}
