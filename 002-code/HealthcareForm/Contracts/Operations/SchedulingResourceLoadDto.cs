namespace HealthcareForm.Contracts.Operations;

// Resource row shown in the scheduling snapshot.
public sealed class SchedulingResourceLoadDto
{
    // Resource or room label shown to operations staff.
    public string Resource { get; init; } = string.Empty;

    // Clinic lane the resource is grouped under.
    public string Clinic { get; init; } = "General";

    // Number of appointments currently consuming the resource.
    public int Allocated { get; init; }

    // Remaining availability derived for the dashboard.
    public int Available { get; init; }

    // Estimated turnaround time in minutes.
    public int TurnaroundMinutes { get; init; }
}
