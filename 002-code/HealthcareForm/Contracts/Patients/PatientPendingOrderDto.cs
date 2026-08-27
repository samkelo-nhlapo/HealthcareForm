namespace HealthcareForm.Contracts.Patients;

// Pending lab order entry returned for a patient.
public sealed class PatientPendingOrderDto
{
    // Unique identifier of the lab result/order row.
    public Guid LabResultId { get; init; }

    // Ordered test display name.
    public string TestName { get; init; } = string.Empty;

    // Optional laboratory code for the test.
    public string TestCode { get; init; } = string.Empty;

    // Type of specimen needed for the order.
    public string SpecimenType { get; init; } = string.Empty;

    // Current workflow status for the order.
    public string Status { get; init; } = string.Empty;

    // Provider or staff member recorded as the ordering owner.
    public string OrderedBy { get; init; } = string.Empty;

    // Laboratory or facility associated with the order.
    public string Lab { get; init; } = string.Empty;

    // Collection timestamp when one has been captured.
    public DateTime? CollectionDate { get; init; }

    // Result timestamp when one has been captured but the row still reads as pending.
    public DateTime? ResultDate { get; init; }
}
