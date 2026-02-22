namespace HealthcareForm.Contracts.Operations;

public sealed class SchedulingResourceLoadDto
{
    public string Resource { get; init; } = string.Empty;
    public string Clinic { get; init; } = "General";
    public int Allocated { get; init; }
    public int Available { get; init; }
    public int TurnaroundMinutes { get; init; }
}
