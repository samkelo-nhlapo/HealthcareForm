namespace HealthcareForm.Contracts.Operations;

// Provider row shown in the scheduling snapshot.
public sealed class SchedulingProviderLoadDto
{
    // Client-provider affiliation identifier for the schedulable provider row.
    public string ClientProviderAffiliationId { get; init; } = string.Empty;

    // Optional client-staff identifier when the affiliation is tied to an employee row.
    public string ClientStaffId { get; init; } = string.Empty;

    // Client identifier for the facility owning the assignment.
    public string ClientId { get; init; } = string.Empty;

    // Facility display name.
    public string ClientName { get; init; } = string.Empty;

    // Provider identifier retained for display and compatibility.
    public string ProviderId { get; init; } = string.Empty;

    // Provider display name shown in the UI.
    public string Provider { get; init; } = string.Empty;

    // Clinic lane the provider is grouped under.
    public string Clinic { get; init; } = "General";

    // Most relevant room assignment for the provider.
    public string Room { get; init; } = "Unassigned";

    // Count of booked appointments in the current window.
    public int Booked { get; init; }

    // Effective capacity shown to operations staff.
    public int Capacity { get; init; }

    // Next known appointment slot formatted for display, or "N/A".
    public string NextSlot { get; init; } = "N/A";
}
