namespace HealthcareForm.Contracts.Operations;

public sealed class SchedulingTimeBlockDto
{
    public string Time { get; init; } = string.Empty;
    public int General { get; init; }
    public int Cardiology { get; init; }
    public int Pediatrics { get; init; }
    public int Oncology { get; init; }
}
