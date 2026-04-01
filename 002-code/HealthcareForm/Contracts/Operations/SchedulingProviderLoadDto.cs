namespace HealthcareForm.Contracts.Operations;

// Provider row shown in the scheduling snapshot.
public sealed class SchedulingProviderLoadDto
{
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
