namespace HealthcareForm.Contracts.Operations;

// Time-block row used by the scheduling heatmap.
public sealed class SchedulingTimeBlockDto
{
    // Time label for the block.
    public string Time { get; init; } = string.Empty;

    // Appointment count for the general clinic lane.
    public int General { get; init; }

    // Appointment count for the cardiology lane.
    public int Cardiology { get; init; }

    // Appointment count for the pediatrics lane.
    public int Pediatrics { get; init; }

    // Appointment count for the oncology lane.
    public int Oncology { get; init; }
}
