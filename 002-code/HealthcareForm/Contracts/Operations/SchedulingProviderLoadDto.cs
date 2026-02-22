namespace HealthcareForm.Contracts.Operations;

public sealed class SchedulingProviderLoadDto
{
    public string Provider { get; init; } = string.Empty;
    public string Clinic { get; init; } = "General";
    public string Room { get; init; } = "Unassigned";
    public int Booked { get; init; }
    public int Capacity { get; init; }
    public string NextSlot { get; init; } = "N/A";
}
