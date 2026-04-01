namespace HealthcareForm.Contracts.Operations;

// Snapshot returned by the operations task-queue endpoint.
public sealed class TaskQueueSnapshotDto
{
    // Ordered tasks shown to operations users.
    public IReadOnlyList<TaskQueueItemDto> Tasks { get; init; } = [];
}
