namespace HealthcareForm.Contracts.Operations;

public sealed class TaskQueueItemDto
{
    public string TaskId { get; init; } = string.Empty;
    public string Title { get; init; } = string.Empty;
    public string Team { get; init; } = "Clinical";
    public string Owner { get; init; } = "Care Team";
    public string Patient { get; init; } = "Unknown Patient";
    public string IdNumber { get; init; } = string.Empty;
    public string Priority { get; init; } = "Routine";
    public string Status { get; init; } = "Open";
    public string DueAt { get; init; } = string.Empty;
    public int SlaMinutes { get; init; }
    public int ElapsedMinutes { get; init; }
}
