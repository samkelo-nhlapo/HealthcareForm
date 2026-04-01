namespace HealthcareForm.Contracts.Operations;

// Task row returned by the operations task-queue endpoint.
public sealed class TaskQueueItemDto
{
    // Human-readable task identifier.
    public string TaskId { get; init; } = string.Empty;

    // Short title shown in the queue.
    public string Title { get; init; } = string.Empty;

    // Team currently responsible for the task.
    public string Team { get; init; } = "Clinical";

    // Current owner or working group.
    public string Owner { get; init; } = "Care Team";

    // Patient name associated with the task, when available.
    public string Patient { get; init; } = "Unknown Patient";

    // National ID number associated with the patient, when available.
    public string IdNumber { get; init; } = string.Empty;

    // Display priority used by the queue.
    public string Priority { get; init; } = "Routine";

    // Human-readable task status.
    public string Status { get; init; } = "Open";

    // Due time formatted for display.
    public string DueAt { get; init; } = string.Empty;

    // Target SLA in minutes.
    public int SlaMinutes { get; init; }

    // Elapsed working time in minutes.
    public int ElapsedMinutes { get; init; }
}
