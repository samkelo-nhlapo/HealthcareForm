namespace HealthcareForm.Contracts.Operations;

public sealed class TaskQueueSnapshotDto
{
    public IReadOnlyList<TaskQueueItemDto> Tasks { get; init; } = [];
}
